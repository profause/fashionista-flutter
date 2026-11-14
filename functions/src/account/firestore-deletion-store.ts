import type { Auth } from 'firebase-admin/auth';
import { getAuth } from 'firebase-admin/auth';
import type {
  DocumentReference,
  Firestore,
  Query,
  QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import { getStorage, type Storage } from 'firebase-admin/storage';

import { destroyCloudinaryAsset } from '../video/delete-asset';
import type {
  DeletionJob,
  DeletionStore,
  JobClaim,
} from './deletion-service';
import {
  dedupeMedia,
  mediaAssetFromUrl,
  mediaAssetsFromFeatured,
  type MediaAsset,
} from './media';

const ACCOUNT_DELETIONS = 'account_deletions';
const DELETE_BATCH_SIZE = 400;

export interface CloudinaryCredentials {
  cloudName: string;
  apiKey: string;
  apiSecret: string;
}

export interface FirestoreDeletionStoreOptions {
  db: Firestore;
  auth?: Auth;
  storage?: Storage;
  cloudinary: CloudinaryCredentials;
}

/**
 * Firestore/Auth/Storage implementation of the deletion port.
 *
 * Every operation is safe to repeat: missing documents are no-ops and media
 * destroy treats Cloudinary's `not found` result as success.
 */
export class FirestoreAccountDeletionStore implements DeletionStore {
  private readonly db: Firestore;
  private readonly auth: Auth;
  private readonly storage: Storage;
  private readonly cloudinary: CloudinaryCredentials;

  constructor(options: FirestoreDeletionStoreOptions) {
    this.db = options.db;
    this.auth = options.auth ?? getAuth();
    this.storage = options.storage ?? getStorage();
    this.cloudinary = options.cloudinary;
  }

  async getJob(uid: string): Promise<DeletionJob | null> {
    const snapshot = await this.jobRef(uid).get();
    if (!snapshot.exists) return null;
    return normalizeJob(uid, snapshot.data() ?? {});
  }

  async acquireJob(job: DeletionJob, staleBefore: Date): Promise<JobClaim> {
    const ref = this.jobRef(job.uid);

    return this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        const current = normalizeJob(job.uid, snapshot.data() ?? {});
        if (current.status === 'completed') {
          return { result: 'completed', job: current };
        }
        if (
          current.status === 'in_progress' &&
          current.updated_at.getTime() > staleBefore.getTime()
        ) {
          return { result: 'busy' };
        }
      }

      transaction.set(ref, jobPayload(job), { merge: true });
      return { result: 'claimed' };
    });
  }

  async saveJob(job: DeletionJob): Promise<void> {
    await this.jobRef(job.uid).set(jobPayload(job), { merge: true });
  }

  async revokeRefreshTokens(uid: string): Promise<void> {
    try {
      await this.auth.revokeRefreshTokens(uid);
    } catch (error) {
      if (!isAuthUserNotFound(error)) throw error;
    }
  }

  async collectMedia(uid: string): Promise<MediaAsset[]> {
    const assets: MediaAsset[] = [];

    const user = await this.db.collection('users').doc(uid).get();
    addUrls(assets, user.data()?.profile_image, user.data()?.banner_image);

    try {
      const authUser = await this.auth.getUser(uid);
      addUrls(assets, authUser.photoURL);
    } catch {
      // The profile document is the primary source; Auth may already be gone.
    }

    const designer = await this.db.collection('designers').doc(uid).get();
    addFeatured(assets, designer.data()?.featured_images);
    addUrls(
      assets,
      designer.data()?.profile_image,
      designer.data()?.banner_image
    );

    const trends = new Map<string, QueryDocumentSnapshot>();
    for (const doc of await this.docsCreatedBy('trends', uid)) {
      trends.set(doc.ref.path, doc);
    }
    for (const doc of await this.docsForAuthor('trends', uid)) {
      trends.set(doc.ref.path, doc);
    }
    for (const doc of trends.values()) {
      addFeatured(assets, doc.data().featured_media);
    }

    const collections = new Map<string, QueryDocumentSnapshot>();
    for (const doc of await this.docsCreatedBy('design_collections', uid)) {
      collections.set(doc.ref.path, doc);
    }
    for (const doc of await this.docsForAuthor('design_collections', uid)) {
      collections.set(doc.ref.path, doc);
    }
    for (const doc of collections.values()) {
      addFeatured(assets, doc.data().featured_images);
    }

    const services = await this.docsCreatedBy('designer_services', uid);
    for (const doc of services) {
      addFeatured(assets, doc.data().featured_images);
    }

    const workOrders = await this.docsCreatedBy('work_orders', uid);
    for (const doc of workOrders) {
      addFeatured(assets, doc.data().featured_media);
    }

    const clientOrders = await this.db
      .collection('work_orders')
      .where('client.uid', '==', uid)
      .get();
    const relatedOrderIds = new Set([
      ...workOrders.map((doc) => doc.id),
      ...clientOrders.docs.map((doc) => doc.id),
    ]);

    const progress = await this.docsCreatedBy(
      'work_order_status_progress',
      uid
    );
    for (const doc of progress) {
      addFeatured(assets, doc.data().featured_media);
    }
    for (const ids of chunks([...relatedOrderIds], 30)) {
      const rows = await this.db
        .collection('work_order_status_progress')
        .where('work_order_id', 'in', ids)
        .get();
      for (const doc of rows.docs) {
        addFeatured(assets, doc.data().featured_media);
      }
    }

    const clients = await this.docsCreatedBy('clients', uid);
    for (const doc of clients) {
      addUrls(assets, doc.data().image_url);
    }

    // A client account may also own designer-created client records linked
    // through client_measurements/{uid}/clients.
    const directClient = await this.db.collection('clients').doc(uid).get();
    addUrls(assets, directClient.data()?.image_url);

    const links = await this.db
      .collection('client_measurements')
      .doc(uid)
      .collection('clients')
      .get();
    for (const link of links.docs) {
      const clientId =
        typeof link.data().client_id === 'string' && link.data().client_id
          ? link.data().client_id
          : link.id;
      const client = await this.db.collection('clients').doc(clientId).get();
      addUrls(assets, client.data()?.image_url);
    }

    const closet = this.db.collection('closets').doc(uid);
    for (const subcollection of ['closet_items', 'outfits', 'outfit_plans']) {
      const rows = await closet.collection(subcollection).get();
      for (const doc of rows.docs) {
        const data = doc.data();
        addFeatured(assets, data.featured_media);
        addUrls(assets, data.thumbnail_url, data.image_url);
      }
    }

    return dedupeMedia(assets);
  }

  async deleteInteractions(uid: string): Promise<number> {
    let count = 0;

    count += await this.deleteQuery(
      this.db.collectionGroup('likes').where('uid', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collectionGroup('followers').where('uid', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collectionGroup('comments').where('author.uid', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collectionGroup('reports').where('reported_by', '==', uid)
    );

    count += await this.deleteQuery(
      this.db
        .collection('designer_reviews')
        .where('comment.author.uid', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('designer_feedback').where('author.uid', '==', uid)
    );

    count += await this.deleteQuery(
      this.db.collection('notifications').where('to', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('notifications').where('from', '==', uid)
    );

    return count;
  }

  async deleteAuthoredTrends(uid: string): Promise<number> {
    const refs = new Map<string, DocumentReference>();

    for (const doc of await this.docsCreatedBy('trends', uid)) {
      refs.set(doc.ref.path, doc.ref);
    }
    for (const doc of await this.docsForAuthor('trends', uid)) {
      refs.set(doc.ref.path, doc.ref);
    }

    for (const ref of refs.values()) {
      await this.db.recursiveDelete(ref);
    }

    return refs.size;
  }

  async deleteDesignerContent(uid: string): Promise<number> {
    let count = 0;

    // Reviews/feedback about the designer must go before the designer document
    // so the rating trigger cannot resurrect the account.
    count += await this.deleteQuery(
      this.db.collection('designer_reviews').where('ref_id', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('designer_feedback').where('ref_id', '==', uid)
    );

    const collections = new Map<string, QueryDocumentSnapshot>();
    for (const doc of await this.docsCreatedBy('design_collections', uid)) {
      collections.set(doc.ref.path, doc);
    }
    for (const doc of await this.docsForAuthor('design_collections', uid)) {
      collections.set(doc.ref.path, doc);
    }
    for (const doc of collections.values()) {
      await this.db.recursiveDelete(doc.ref);
      count += 1;
    }

    count += await this.deleteQuery(
      this.db.collection('designer_services').where('created_by', '==', uid)
    );

    const designerRef = this.db.collection('designers').doc(uid);
    const designerExists = (await designerRef.get()).exists;
    // Always recurse: a missing parent document can still own subcollections.
    await this.db.recursiveDelete(designerRef);
    if (designerExists) count += 1;

    return count;
  }

  async deleteCommerce(uid: string): Promise<number> {
    let count = 0;

    count += await this.deleteQuery(
      this.db.collection('bookings').where('user_id', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('bookings').where('designer_id', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('slot_reservations').where('user_id', '==', uid)
    );
    count += await this.deleteQuery(
      this.db.collection('slot_reservations').where('designer_id', '==', uid)
    );

    const authoredOrders = await this.docsCreatedBy('work_orders', uid);
    const relatedOrderIds = new Set(authoredOrders.map((doc) => doc.id));

    const clientOrders = await this.db
      .collection('work_orders')
      .where('client.uid', '==', uid)
      .get();
    for (const doc of clientOrders.docs) relatedOrderIds.add(doc.id);

    // Progress rows are denormalized into a top-level collection, so deleting
    // the work-order document does not remove them.
    count += await this.deleteQuery(
      this.db
        .collection('work_order_status_progress')
        .where('created_by', '==', uid)
    );
    for (const ids of chunks([...relatedOrderIds], 30)) {
      count += await this.deleteQuery(
        this.db
          .collection('work_order_status_progress')
          .where('work_order_id', 'in', ids)
      );
    }

    for (const doc of authoredOrders) {
      await this.db.recursiveDelete(doc.ref);
      count += 1;
    }

    count += await this.anonymizeClientWorkOrders(uid);

    return count;
  }

  async deleteClientRecords(uid: string): Promise<number> {
    let count = 0;
    const linkedClientIds = new Set<string>();

    const links = await this.db
      .collection('client_measurements')
      .doc(uid)
      .collection('clients')
      .get();

    for (const link of links.docs) {
      const data = link.data();
      linkedClientIds.add(
        typeof data.client_id === 'string' && data.client_id
          ? data.client_id
          : link.id
      );
    }

    for (const clientId of linkedClientIds) {
      const ref = this.db.collection('clients').doc(clientId);
      const exists = (await ref.get()).exists;
      await this.db.recursiveDelete(ref);
      if (exists) count += 1;

      // Remove links to the deleted designer-owned client record from every
      // user who was linked to it.
      count += await this.deleteQuery(
        this.db.collectionGroup('clients').where('client_id', '==', clientId)
      );
    }

    const authoredClients = await this.docsCreatedBy('clients', uid);
    for (const doc of authoredClients) {
      // Other users may still link to this designer-owned client record.
      count += await this.deleteQuery(
        this.db.collectionGroup('clients').where('client_id', '==', doc.id)
      );
      await this.db.recursiveDelete(doc.ref);
      count += 1;
    }

    const directClient = this.db.collection('clients').doc(uid);
    const directClientExists = (await directClient.get()).exists;
    await this.db.recursiveDelete(directClient);
    if (directClientExists) count += 1;

    // The parent document is not required for the links subcollection to
    // exist, so recurse unconditionally.
    await this.db.recursiveDelete(
      this.db.collection('client_measurements').doc(uid)
    );

    return count;
  }

  async deleteUserDocuments(uid: string): Promise<number> {
    let count = 0;

    for (const collection of ['users', 'closets']) {
      const ref = this.db.collection(collection).doc(uid);
      const exists = (await ref.get()).exists;
      // Always recurse: a missing parent document can still own subcollections.
      await this.db.recursiveDelete(ref);
      if (exists) count += 1;
    }

    return count;
  }

  async destroyMedia(media: MediaAsset[]): Promise<string[]> {
    if (media.length === 0) return [];
    if (
      !this.cloudinary.cloudName ||
      !this.cloudinary.apiKey ||
      !this.cloudinary.apiSecret
    ) {
      throw new Error('Cloudinary is not configured for account deletion.');
    }

    const failed: string[] = [];
    for (const batch of chunks(media, 5)) {
      await Promise.all(
        batch.map(async (asset) => {
          try {
            await destroyCloudinaryAsset({
              cloudName: this.cloudinary.cloudName,
              apiKey: this.cloudinary.apiKey,
              apiSecret: this.cloudinary.apiSecret,
              assetId: asset.publicId,
              resourceType: asset.resourceType,
            });
          } catch {
            failed.push(`${asset.resourceType}:${asset.publicId}`);
          }
        })
      );
    }

    return failed;
  }

  async deleteLegacyStorage(uid: string): Promise<number> {
    const paths = [
      `profile_images/${uid}.jpg`,
      `profile_images/${uid}.png`,
      `banner_images/${uid}.jpg`,
      `banner_images/${uid}.png`,
    ];

    let deleted = 0;
    for (const path of paths) {
      try {
        await this.storage.bucket().file(path).delete({ ignoreNotFound: true });
        deleted += 1;
      } catch {
        // Legacy Storage is best-effort; Cloudinary is the active store.
      }
    }
    return deleted;
  }

  async deleteAuthUser(uid: string): Promise<void> {
    try {
      await this.auth.deleteUser(uid);
    } catch (error) {
      if (!isAuthUserNotFound(error)) throw error;
    }
  }

  private jobRef(uid: string): DocumentReference {
    return this.db.collection(ACCOUNT_DELETIONS).doc(uid);
  }

  private async docsCreatedBy(
    collection: string,
    uid: string
  ): Promise<QueryDocumentSnapshot[]> {
    const snapshot = await this.db
      .collection(collection)
      .where('created_by', '==', uid)
      .get();
    return snapshot.docs;
  }

  private async docsForAuthor(
    collection: string,
    uid: string
  ): Promise<QueryDocumentSnapshot[]> {
    const snapshot = await this.db
      .collection(collection)
      .where('author.uid', '==', uid)
      .get();
    return snapshot.docs;
  }

  private async deleteQuery(query: Query): Promise<number> {
    let total = 0;

    while (true) {
      const snapshot = await query.limit(DELETE_BATCH_SIZE).get();
      if (snapshot.empty) break;

      const batch = this.db.batch();
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();

      total += snapshot.size;
      if (snapshot.size < DELETE_BATCH_SIZE) break;
    }

    return total;
  }

  private async anonymizeClientWorkOrders(uid: string): Promise<number> {
    const snapshot = await this.db
      .collection('work_orders')
      .where('client.uid', '==', uid)
      .get();

    if (snapshot.empty) return 0;

    let updated = 0;
    for (
      let index = 0;
      index < snapshot.docs.length;
      index += DELETE_BATCH_SIZE
    ) {
      const batch = this.db.batch();
      const chunk = snapshot.docs.slice(index, index + DELETE_BATCH_SIZE);

      for (const doc of chunk) {
        const data = doc.data();
        const author =
          data.author && data.author.uid === uid
            ? {
                name: 'Deleted user',
                uid: '',
                avatar: '',
                mobileNumber: '',
              }
            : data.author;

        batch.update(doc.ref, {
          client: {
            name: 'Deleted user',
            uid: '',
            avatar: '',
            mobileNumber: '',
          },
          measurements: [],
          ...(author ? { author } : {}),
        });
        updated += 1;
      }

      await batch.commit();
    }

    return updated;
  }
}

function chunks<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

function jobPayload(job: DeletionJob): Record<string, unknown> {
  return {
    uid: job.uid,
    status: job.status,
    requested_at: job.requested_at,
    started_at: job.started_at,
    updated_at: job.updated_at,
    completed_at: job.completed_at,
    completed_steps: job.completed_steps,
    media: job.media,
    counts: job.counts,
    last_error: job.last_error,
  };
}

function addFeatured(assets: MediaAsset[], value: unknown): void {
  assets.push(...mediaAssetsFromFeatured(value));
}

function addUrls(assets: MediaAsset[], ...values: unknown[]): void {
  for (const value of values) {
    const asset = mediaAssetFromUrl(value);
    if (asset) assets.push(asset);
  }
}

function normalizeJob(
  uid: string,
  data: Record<string, unknown>
): DeletionJob {
  const now = new Date();
  const status = data.status;

  return {
    uid,
    status:
      status === 'requested' ||
      status === 'in_progress' ||
      status === 'failed' ||
      status === 'completed'
        ? status
        : 'requested',
    requested_at: toDate(data.requested_at) ?? now,
    started_at: toDate(data.started_at),
    updated_at: toDate(data.updated_at) ?? now,
    completed_at: toDate(data.completed_at),
    completed_steps: Array.isArray(data.completed_steps)
      ? (data.completed_steps as DeletionJob['completed_steps'])
      : [],
    media: normalizeMedia(data.media),
    counts: normalizeCounts(data.counts),
    last_error:
      typeof data.last_error === 'string' ? data.last_error : null,
  };
}

function normalizeMedia(value: unknown): MediaAsset[] {
  if (!Array.isArray(value)) return [];

  const media: MediaAsset[] = [];
  for (const entry of value) {
    if (typeof entry !== 'object' || entry === null) continue;
    const record = entry as Record<string, unknown>;
    if (typeof record.publicId !== 'string' || !record.publicId) continue;
    media.push({
      publicId: record.publicId,
      resourceType: record.resourceType === 'video' ? 'video' : 'image',
    });
  }
  return media;
}

function normalizeCounts(value: unknown): Record<string, number> {
  if (typeof value !== 'object' || value === null) return {};

  const counts: Record<string, number> = {};
  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry === 'number' && Number.isFinite(entry)) {
      counts[key] = entry;
    }
  }
  return counts;
}

function toDate(value: unknown): Date | null {
  if (value instanceof Date) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (
    typeof value === 'object' &&
    value !== null &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    const date = (value as { toDate: () => Date }).toDate();
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
  }
  return null;
}

function isAuthUserNotFound(error: unknown): boolean {
  const code = (error as { code?: string } | undefined)?.code;
  return code === 'auth/user-not-found';
}

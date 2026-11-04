import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { DeviceToken, NotificationPreferences } from './types';

/**
 * Storage contract used by the dispatcher.
 *
 * Keeping it explicit lets the dispatcher be unit tested with an in-memory
 * fake, without the Firestore emulator.
 */
export interface NotificationStore {
  getActiveDevices(userId: string): Promise<DeviceToken[]>;
  getPreferences(userId: string): Promise<Partial<NotificationPreferences>>;
  createHistoryIfAbsent(
    userId: string,
    notificationId: string,
    payload: HistoryPayload
  ): Promise<boolean>;
  claimDelivery(notificationId: string): Promise<boolean>;
  deactivateTokens(userId: string, invalidTokens: string[]): Promise<void>;
}

export interface HistoryPayload {
  title: string;
  description: string;
  type: string;
  event: string;
  refId: string;
  refType: string;
  from: string;
  to: string;
  data: Record<string, string>;
  createdAt: Timestamp;
}

/** Firestore access for the notification dispatcher. */
export class NotificationRepository implements NotificationStore {
  constructor(private readonly db: Firestore) {}

  /** All active device tokens for a user. */
  async getActiveDevices(userId: string): Promise<DeviceToken[]> {
    if (!userId) return [];

    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('devices')
      .where('is_active', '==', true)
      .get();

    const devices: DeviceToken[] = [];
    for (const doc of snapshot.docs) {
      const token = (doc.data().fcm_token ?? '') as string;
      if (token) devices.push({ deviceId: doc.id, token });
    }
    return devices;
  }

  async getPreferences(userId: string): Promise<Partial<NotificationPreferences>> {
    if (!userId) return {};
    const doc = await this.db
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('notifications')
      .get();
    return doc.exists ? (doc.data() as Partial<NotificationPreferences>) : {};
  }

  /**
   * Creates the inbox record once. Returns `false` when it already existed, so
   * the caller can skip the push on a retried trigger.
   */
  async createHistoryIfAbsent(
    userId: string,
    notificationId: string,
    payload: HistoryPayload
  ): Promise<boolean> {
    const ref = this.db.collection('notifications').doc(notificationId);

    return this.db.runTransaction(async (transaction) => {
      const existing = await transaction.get(ref);
      if (existing.exists) return false;

      transaction.set(ref, {
        uid: notificationId,
        title: payload.title,
        description: payload.description,
        type: payload.type,
        event: payload.event,
        ref_id: payload.refId,
        ref_type: payload.refType,
        from: payload.from,
        to: payload.to,
        data: payload.data,
        status: 'new',
        created_at: payload.createdAt.toMillis(),
        read_at: null,
      });

      return true;
    });
  }

  /**
   * Delivery marker kept separate from the inbox record: the inbox document
   * may already exist (created by the app) while the push still has to go out
   * exactly once.
   */
  async claimDelivery(notificationId: string): Promise<boolean> {
    const ref = this.db
      .collection('notification_deliveries')
      .doc(notificationId);

    return this.db.runTransaction(async (transaction) => {
      const existing = await transaction.get(ref);
      if (existing.exists) return false;

      transaction.set(ref, {
        notification_id: notificationId,
        created_at: Timestamp.now(),
      });
      return true;
    });
  }

  /** Deactivates tokens FCM reported as permanently invalid. */
  async deactivateTokens(
    userId: string,
    invalidTokens: string[]
  ): Promise<void> {
    if (invalidTokens.length === 0) return;

    const devices = await this.db
      .collection('users')
      .doc(userId)
      .collection('devices')
      .where('fcm_token', 'in', invalidTokens.slice(0, 10))
      .get();

    const batch = this.db.batch();
    for (const doc of devices.docs) {
      batch.update(doc.ref, {
        is_active: false,
        fcm_token: '',
        updated_at: Timestamp.now(),
      });
    }
    await batch.commit();
  }

  /** Designer-scoped client id → linked Fashionista user id, if any. */
  async resolveUserIdForClient(clientId: string): Promise<string | null> {
    if (!clientId) return null;

    const snapshot = await this.db
      .collectionGroup('clients')
      .where('client_id', '==', clientId)
      .limit(1)
      .get();

    if (snapshot.empty) return null;

    // Path: client_measurements/{userId}/clients/{clientId}
    const segments = snapshot.docs[0].ref.path.split('/');
    const userIndex = segments.indexOf('client_measurements') + 1;
    return segments[userIndex] ?? null;
  }
}

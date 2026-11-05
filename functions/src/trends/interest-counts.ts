import { Firestore, FieldValue } from 'firebase-admin/firestore';
import { diffTags, normalizeTags, tallyTagDeltas } from './tags';

/** Collection that acts as the source of truth for valid fashion interests. */
export const FASHION_INTERESTS_COLLECTION = 'fashion_interests';

/**
 * Denormalized counter on each `fashion_interests` document: the number of
 * trends whose `tags` currently contain the interest's `name`.
 *
 * The Flutter `FashionInterestModel` reads `number_of_posts` first, then the
 * camelCase `numberOfPosts` as a legacy fallback. This function writes the
 * canonical snake_case field only — a document that still holds the legacy key
 * resolves to the fresh value because `number_of_posts` wins.
 */
export const NUMBER_OF_POSTS_FIELD = 'number_of_posts';

/** Legacy key still tolerated by the app; never written. */
export const LEGACY_NUMBER_OF_POSTS_FIELD = 'numberOfPosts';

export const TRENDS_COLLECTION = 'trends';

export interface InterestDelta {
  interestId: string;
  delta: number;
}

/**
 * Storage contract for counter maintenance.
 *
 * Explicit so the sync can be unit tested with an in-memory fake instead of the
 * Firestore emulator.
 */
export interface InterestCounterStore {
  /** Resolves an interest document id by its exact `name`, or `null`. */
  findInterestIdByName(name: string): Promise<string | null>;
  /** Applies every delta atomically. */
  applyCountDeltas(deltas: InterestDelta[]): Promise<void>;
}

export interface SyncResult {
  trendId: string;
  addedTags: string[];
  removedTags: string[];
  /** Tags with no matching `fashion_interests` document. */
  missingInterests: string[];
  updatedInterestIds: string[];
  committed: boolean;
}

/**
 * Applies the counter deltas caused by a single `trends/{trendId}` write.
 *
 * Only the interests whose membership actually changed are touched: the
 * `before`/`after` documents are diffed on their normalized `tags`, so editing
 * a trend's caption or image does not rewrite any counter.
 *
 * Missing interests are reported, not created — `fashion_interests` stays the
 * source of truth, and a typo in a tag must not silently add a new interest.
 *
 * Deltas are aggregated per interest document before writing: two tag values
 * that resolve to the same interest (duplicate `name` entries) must move the
 * counter once, not twice.
 */
export async function syncFashionInterestPostCounts(
  store: InterestCounterStore,
  trendId: string,
  beforeData: Record<string, unknown> | undefined,
  afterData: Record<string, unknown> | undefined
): Promise<SyncResult> {
  const beforeTags = normalizeTags(beforeData?.tags);
  const afterTags = normalizeTags(afterData?.tags);
  const { added, removed } = diffTags(beforeTags, afterTags);

  const result: SyncResult = {
    trendId,
    addedTags: added,
    removedTags: removed,
    missingInterests: [],
    updatedInterestIds: [],
    committed: false,
  };

  if (added.length === 0 && removed.length === 0) return result;

  const interestIdByTag = new Map<string, string>();
  for (const tag of tallyTagDeltas(added, removed).keys()) {
    const interestId = await store.findInterestIdByName(tag);

    if (interestId === null) {
      result.missingInterests.push(tag);
      continue;
    }

    interestIdByTag.set(tag, interestId);
  }

  const deltaByInterest = new Map<string, number>();
  for (const [tag, delta] of tallyTagDeltas(added, removed)) {
    const interestId = interestIdByTag.get(tag);
    if (interestId === undefined) continue;

    deltaByInterest.set(interestId, (deltaByInterest.get(interestId) ?? 0) + delta);
  }

  const deltas: InterestDelta[] = [];
  for (const [interestId, delta] of deltaByInterest) {
    // A cancelled pair (same interest on both sides) must not cost a write.
    if (delta === 0) continue;
    deltas.push({ interestId, delta });
    result.updatedInterestIds.push(interestId);
  }

  if (deltas.length === 0) return result;

  await store.applyCountDeltas(deltas);
  result.committed = true;

  return result;
}

/** Firestore access for fashion-interest post counters. */
export class InterestCounterRepository implements InterestCounterStore {
  constructor(private readonly db: Firestore) {}

  async findInterestIdByName(name: string): Promise<string | null> {
    if (!name) return null;

    const snapshot = await this.db
      .collection(FASHION_INTERESTS_COLLECTION)
      .where('name', '==', name)
      .limit(1)
      .get();

    return snapshot.empty ? null : snapshot.docs[0].id;
  }

  /**
   * Applies every delta in one atomic batch.
   *
   * `update` (not `set`) is intentional: a counter must never materialise an
   * interest document that the catalogue does not contain.
   */
  async applyCountDeltas(deltas: InterestDelta[]): Promise<void> {
    if (deltas.length === 0) return;

    const batch = this.db.batch();
    for (const { interestId, delta } of deltas) {
      batch.update(
        this.db.collection(FASHION_INTERESTS_COLLECTION).doc(interestId),
        { [NUMBER_OF_POSTS_FIELD]: FieldValue.increment(delta) }
      );
    }
    await batch.commit();
  }
}

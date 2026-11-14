import { Firestore } from 'firebase-admin/firestore';
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

/**
 * Comparison key for interest names.
 *
 * Tapping an interest inserts its exact stored name, but a manually typed
 * hashtag may differ in case or whitespace. The counter should still resolve
 * both to the same interest.
 */
export function normalizeInterestName(value: string): string {
  return value.trim().replace(/\s+/g, ' ').toLowerCase();
}

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
 * Current counter value, tolerating the numeric strings some seeded documents
 * still hold. Falls back to the legacy camelCase key when the snake_case field
 * is absent so the first write does not discard an existing count.
 */
export function readInterestCount(data: Record<string, unknown>): number {
  return (
    parseCount(data[NUMBER_OF_POSTS_FIELD]) ??
    parseCount(data[LEGACY_NUMBER_OF_POSTS_FIELD]) ??
    0
  );
}

function parseCount(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return Math.trunc(parsed);
  }
  return null;
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

    const exact = await this.db
      .collection(FASHION_INTERESTS_COLLECTION)
      .where('name', '==', name.trim())
      .limit(1)
      .get();

    if (!exact.empty) return exact.docs[0].id;

    // The app resolves tapped interests to their exact stored name, but a
    // manually typed hashtag can differ in case or spacing. Fall back to a
    // normalized index so those reports still move the counter.
    const index = await this.nameIndex();
    return index.get(normalizeInterestName(name)) ?? null;
  }

  /** Lazily built normalized-name index, cached for this function instance. */
  private nameIndex(): Promise<Map<string, string>> {
    if (this._nameIndex === undefined) {
      this._nameIndex = this.db
        .collection(FASHION_INTERESTS_COLLECTION)
        .get()
        .then((snapshot) => {
          const index = new Map<string, string>();
          for (const doc of snapshot.docs) {
            const name = doc.data().name;
            if (typeof name !== 'string') continue;

            const key = normalizeInterestName(name);
            if (key && !index.has(key)) index.set(key, doc.id);
          }
          return index;
        })
        .catch((error) => {
          // Do not poison the instance with a permanently rejected index.
          this._nameIndex = undefined;
          throw error;
        });
    }

    return this._nameIndex;
  }

  private _nameIndex?: Promise<Map<string, string>>;

  /**
   * Applies every delta in one atomic transaction.
   *
   * A transaction (rather than `FieldValue.increment`) lets a legacy numeric
   * string be normalized instead of making the write fail. The document is
   * never created: `update` on a missing interest is skipped.
   */
  async applyCountDeltas(deltas: InterestDelta[]): Promise<void> {
    if (deltas.length === 0) return;

    const collection = this.db.collection(FASHION_INTERESTS_COLLECTION);

    await this.db.runTransaction(async (transaction) => {
      const refs = deltas.map(({ interestId }) => collection.doc(interestId));
      const snapshots = [];

      for (const ref of refs) {
        snapshots.push(await transaction.get(ref));
      }

      for (let index = 0; index < deltas.length; index += 1) {
        const snapshot = snapshots[index];
        if (!snapshot.exists) continue;

        const current = readInterestCount(
          (snapshot.data() ?? {}) as Record<string, unknown>
        );
        transaction.set(
          refs[index],
          { [NUMBER_OF_POSTS_FIELD]: current + deltas[index].delta },
          { merge: true }
        );
      }
    });
  }
}

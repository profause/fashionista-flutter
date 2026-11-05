import {
  DocumentData,
  Firestore,
  Query,
  QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import {
  FASHION_INTERESTS_COLLECTION,
  LEGACY_NUMBER_OF_POSTS_FIELD,
  NUMBER_OF_POSTS_FIELD,
  TRENDS_COLLECTION,
} from './interest-counts';
import { countTags } from './tags';

/** Documents read per page while scanning a collection. */
const PAGE_SIZE = 300;

/** Writes per batch; Firestore allows up to 500. */
const BATCH_LIMIT = 450;

export interface InterestCounterSnapshot {
  id: string;
  name: string;
  /** Value the app currently resolves for this interest, if any. */
  currentCount: number | null;
}

export interface CounterUpdate {
  id: string;
  value: number;
}

export interface TrendScan {
  /** Tag → number of trends referencing it. */
  tagCounts: Map<string, number>;
  trendsProcessed: number;
}

/**
 * Storage contract for the rebuild.
 *
 * Paging and batching live in the repository; the decision of *which* counters
 * are stale lives here so it can be unit tested.
 */
export interface ReconcileStore {
  /** Counts every tag from the `trends` collection (source of truth). */
  scanTrendTags(): Promise<TrendScan>;
  listInterestCounters(): Promise<InterestCounterSnapshot[]>;
  /** Writes the given counters and returns how many were applied. */
  writeCounters(updates: CounterUpdate[]): Promise<number>;
}

export interface ReconcileResult {
  trendsProcessed: number;
  interestsProcessed: number;
  countersUpdated: number;
}

/**
 * Rebuilds `fashion_interests.number_of_posts` from the actual `trends` data.
 *
 * Recovery operation for the hot-path trigger in this module: Firestore
 * delivers events at-least-once, so an increment can be applied twice and the
 * counter drifts. Nothing here trusts the stored value — every interest is
 * recomputed from the trends that reference it, and interests no trend mentions
 * are reset to `0`.
 *
 * Deliberately never runs on the write path: it reads the whole collection.
 */
export async function rebuildFashionInterestPostCounts(
  store: ReconcileStore
): Promise<ReconcileResult> {
  const { tagCounts, trendsProcessed } = await store.scanTrendTags();

  const interests = await store.listInterestCounters();
  const updates: CounterUpdate[] = [];

  for (const interest of interests) {
    const desired =
      typeof interest.name === 'string'
        ? (tagCounts.get(interest.name.trim()) ?? 0)
        : 0;

    // Counter absent counts as stale so the field is created.
    if (interest.currentCount === desired) continue;

    updates.push({ id: interest.id, value: desired });
  }

  const countersUpdated = await store.writeCounters(updates);

  return {
    trendsProcessed,
    interestsProcessed: interests.length,
    countersUpdated,
  };
}

/** Firestore access for the counter rebuild. */
export class ReconcileRepository implements ReconcileStore {
  constructor(private readonly db: Firestore) {}

  async scanTrendTags(): Promise<TrendScan> {
    const rawTags: unknown[] = [];

    const trendsProcessed = await this.forEachDocument(
      this.db.collection(TRENDS_COLLECTION),
      (doc) => {
        rawTags.push((doc.data() as { tags?: unknown }).tags);
      }
    );

    return { tagCounts: countTags(rawTags), trendsProcessed };
  }

  async listInterestCounters(): Promise<InterestCounterSnapshot[]> {
    const interests: InterestCounterSnapshot[] = [];

    await this.forEachDocument(
      this.db.collection(FASHION_INTERESTS_COLLECTION),
      (doc) => {
        const data = doc.data();
        interests.push({
          id: doc.id,
          name: typeof data.name === 'string' ? data.name : '',
          currentCount: firstNumber(data, [
            NUMBER_OF_POSTS_FIELD,
            LEGACY_NUMBER_OF_POSTS_FIELD,
          ]),
        });
      }
    );

    return interests;
  }

  async writeCounters(updates: CounterUpdate[]): Promise<number> {
    let written = 0;

    for (let index = 0; index < updates.length; index += BATCH_LIMIT) {
      const batch = this.db.batch();

      for (const update of updates.slice(index, index + BATCH_LIMIT)) {
        batch.set(
          this.db.collection(FASHION_INTERESTS_COLLECTION).doc(update.id),
          { [NUMBER_OF_POSTS_FIELD]: update.value },
          { merge: true }
        );
      }

      await batch.commit();
      written += Math.min(BATCH_LIMIT, updates.length - index);
    }

    return written;
  }

  /**
   * Streams a collection in pages ordered by document id.
   *
   * Ordering by `__name__` keeps pagination stable even when documents are
   * added or removed between reads.
   */
  private async forEachDocument(
    query: Query<DocumentData>,
    handler: (doc: QueryDocumentSnapshot<DocumentData>) => void
  ): Promise<number> {
    let lastDoc: QueryDocumentSnapshot<DocumentData> | undefined;
    let total = 0;

    for (;;) {
      let page = query.orderBy('__name__').limit(PAGE_SIZE);
      if (lastDoc !== undefined) page = page.startAfter(lastDoc);

      const snapshot = await page.get();
      if (snapshot.empty) break;

      for (const doc of snapshot.docs) {
        handler(doc);
        total += 1;
      }

      if (snapshot.size < PAGE_SIZE) break;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    return total;
  }
}

function firstNumber(
  data: Record<string, unknown>,
  keys: string[]
): number | null {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === 'number' && Number.isFinite(value)) return value;
  }
  return null;
}

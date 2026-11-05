import { Firestore } from 'firebase-admin/firestore';
import { RatingSummary } from './summary';

/**
 * Storage contract for rating recomputation.
 *
 * Explicit so the recompute path can be unit tested with an in-memory fake,
 * without the Firestore emulator.
 */
export interface RatingStore {
  /** Raw `rating` values of every review pointing at the designer. */
  listRatings(designerId: string): Promise<unknown[]>;
  /** Writes the aggregate; `false` when the designer no longer exists. */
  writeSummary(designerId: string, summary: RatingSummary): Promise<boolean>;
}

/** Firestore access for designer rating aggregates. */
export class RatingRepository implements RatingStore {
  constructor(private readonly db: Firestore) {}

  /**
   * Reads only the `rating` field of each review.
   *
   * Aggregation queries would need a composite index per star bucket, and the
   * histogram cannot be produced from `count()`/`average()` alone. A projected
   * read keeps one index (the existing single-field `ref_id`) and yields every
   * number from a single consistent snapshot.
   */
  async listRatings(designerId: string): Promise<unknown[]> {
    if (!designerId) return [];

    const snapshot = await this.db
      .collection('designer_reviews')
      .where('ref_id', '==', designerId)
      .select('rating')
      .get();

    return snapshot.docs.map(
      (doc) => (doc.data() as { rating?: unknown }).rating
    );
  }

  async writeSummary(
    designerId: string,
    summary: RatingSummary
  ): Promise<boolean> {
    if (!designerId) return false;

    try {
      // `update` (not `set`) so a deleted designer is not resurrected as a
      // document containing only rating fields.
      await this.db.collection('designers').doc(designerId).update({
        ratings: summary.ratings,
        review_count: summary.review_count,
        total_rating: summary.total_rating,
        average_rating: summary.average_rating,
      });
      return true;
    } catch (error) {
      if (isNotFound(error)) return false;
      throw error;
    }
  }
}

function isNotFound(error: unknown): boolean {
  const code = (error as { code?: number | string } | undefined)?.code;
  return code === 5 || code === 'not-found';
}

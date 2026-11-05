import { RatingStore } from './repository';
import {
  RatingSummary,
  ReviewData,
  affectedDesignerIds,
  ratingSummaryChanged,
  summarize,
} from './summary';

export interface RatingLogger {
  info: (message: string, ...args: unknown[]) => void;
  warn: (message: string, ...args: unknown[]) => void;
  error: (message: string, ...args: unknown[]) => void;
}

/** One designer the change touched and the summary written for it. */
export interface RatingUpdate {
  designerId: string;
  summary: RatingSummary;
}

/**
 * Recomputes a designer's aggregate from the reviews that currently point at it.
 *
 * Returns `null` when the designer document is gone — deleting a designer must
 * not be undone by a review edit that races the delete.
 */
export async function recomputeDesignerRating(
  store: RatingStore,
  designerId: string
): Promise<RatingSummary | null> {
  if (!designerId) return null;

  const ratings = await store.listRatings(designerId);
  const summary = summarize(ratings);
  const written = await store.writeSummary(designerId, summary);

  return written ? summary : null;
}

/**
 * Applies a single `designer_reviews` write to every affected designer.
 *
 * Trigger entry point kept free of Firestore specifics so the branching —
 * no-op edits, re-pointed reviews, deleted designers, partial failure — is
 * covered by unit tests.
 */
export async function applyReviewChange(
  store: RatingStore,
  before: ReviewData | undefined,
  after: ReviewData | undefined,
  logger: RatingLogger
): Promise<RatingUpdate[]> {
  if (!ratingSummaryChanged(before, after)) {
    logger.info('Review edit did not change any rating; skipping recompute');
    return [];
  }

  const designerIds = affectedDesignerIds(before, after);
  if (designerIds.length === 0) {
    logger.warn('Review has no ref_id; no designer rating to update');
    return [];
  }

  const updates: RatingUpdate[] = [];

  for (const designerId of designerIds) {
    try {
      const summary = await recomputeDesignerRating(store, designerId);
      if (summary) {
        updates.push({ designerId, summary });
      } else {
        logger.warn('Designer not found while recomputing rating', {
          designerId,
        });
      }
    } catch (error) {
      // Retrying the whole invocation would re-recompute the designers that
      // already succeeded; fail loudly instead so the error is visible.
      logger.error('Failed to recompute designer rating', {
        designerId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }
  }

  return updates;
}

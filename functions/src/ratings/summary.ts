/**
 * Pure rating arithmetic for `designers/{designerId}`.
 *
 * The aggregate is always derived from the review documents, never incremented
 * in place: Firestore triggers are at-least-once, so an incremental `+1`/`-1`
 * drifts on every retry. Recomputing makes the write idempotent and self-healing.
 */

export const RATING_BUCKETS = [5, 4, 3, 2, 1] as const;
export const MIN_RATING = 1;
export const MAX_RATING = 5;

/** Fields the app reads from `designers/{designerId}` to render a rating. */
export interface RatingSummary {
  /** Histogram keyed by star, `{'5': 3, '4': 1, ...}`. */
  ratings: Record<string, number>;
  /** Number of reviews that carry a valid rating. */
  review_count: number;
  /** Same value as `review_count`; kept because the app displays it separately. */
  total_rating: number;
  /** One decimal place, e.g. `4.3`. */
  average_rating: number;
}

export type ReviewData = Record<string, unknown>;

/**
 * Coerces a stored rating into a whole star, or `null` when it is not one.
 *
 * The Dart model defaults `rating` to `0`, so a review saved without a score
 * exists but must not be counted. Out-of-range and fractional values are
 * rejected rather than clamped: inventing a star would silently corrupt the
 * average, and the same value is rejected on every recompute, so the aggregate
 * stays stable.
 */
export function normalizeRating(value: unknown): number | null {
  const parsed =
    typeof value === 'number'
      ? value
      : typeof value === 'string' && value.trim() !== ''
        ? Number(value.trim())
        : NaN;

  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return null;
  if (parsed < MIN_RATING || parsed > MAX_RATING) return null;
  return parsed;
}

export function emptySummary(): RatingSummary {
  const ratings: Record<string, number> = {};
  for (const bucket of RATING_BUCKETS) ratings[String(bucket)] = 0;

  return {
    ratings,
    review_count: 0,
    total_rating: 0,
    average_rating: 0,
  };
}

function roundToOneDecimal(value: number): number {
  return Math.round(value * 10) / 10;
}

/**
 * Builds the summary for a designer from the ratings of its reviews.
 *
 * Unknown values are skipped, so the result depends only on the set of valid
 * ratings — calling it twice with the same input always yields the same output.
 */
export function summarize(values: readonly unknown[]): RatingSummary {
  const summary = emptySummary();
  let weightedSum = 0;

  for (const value of values) {
    const rating = normalizeRating(value);
    if (rating === null) continue;

    summary.ratings[String(rating)] += 1;
    summary.review_count += 1;
    weightedSum += rating;
  }

  summary.total_rating = summary.review_count;
  summary.average_rating =
    summary.review_count === 0
      ? 0
      : roundToOneDecimal(weightedSum / summary.review_count);

  return summary;
}

/** Designer id a review points at, or `''` when absent. */
export function designerIdOf(data: ReviewData | undefined): string {
  const value = data?.ref_id;
  return typeof value === 'string' ? value.trim() : '';
}

/**
 * True when a write can move an aggregate.
 *
 * Editing only the comment text triggers no recompute — a busy review thread
 * would otherwise re-read every review for every edit.
 */
export function ratingSummaryChanged(
  before: ReviewData | undefined,
  after: ReviewData | undefined
): boolean {
  if (!before || !after) return true; // create or delete
  return (
    normalizeRating(before.rating) !== normalizeRating(after.rating) ||
    designerIdOf(before) !== designerIdOf(after)
  );
}

/**
 * Every designer affected by a change.
 *
 * A re-pointed review (`ref_id` changed) affects two designers: the original
 * aggregate has to drop the review and the new one has to pick it up.
 */
export function affectedDesignerIds(
  before: ReviewData | undefined,
  after: ReviewData | undefined
): string[] {
  const ids = new Set<string>();
  const previous = designerIdOf(before);
  const next = designerIdOf(after);

  if (previous) ids.add(previous);
  if (next) ids.add(next);

  return [...ids];
}

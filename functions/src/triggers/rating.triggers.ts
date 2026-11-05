import {
  FirestoreEvent,
  Change,
  DocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import type { Firestore } from 'firebase-admin/firestore';
import { RatingRepository } from '../ratings/repository';
import { applyReviewChange, RatingLogger } from '../ratings/service';
import { ReviewData } from '../ratings/summary';

/**
 * A review is created, edited or deleted → refresh the designer aggregate.
 *
 * The app writes `designer_reviews/{reviewId}` with `set(merge: true)` and
 * never maintains the counters itself, so this trigger is the only writer of
 * `designers/{designerId}.ratings`, `review_count`, `total_rating` and
 * `average_rating`.
 */
export async function onDesignerReviewWritten(
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined>
): Promise<void> {
  const change = event.data;
  if (!change) return;

  const before: ReviewData | undefined = change.before.exists
    ? (change.before.data() as ReviewData)
    : undefined;
  const after: ReviewData | undefined = change.after.exists
    ? (change.after.data() as ReviewData)
    : undefined;

  const context = buildContext();
  await applyReviewChange(
    new RatingRepository(context.db),
    before,
    after,
    context.logger
  );
}

function buildContext(): { db: Firestore; logger: RatingLogger } {
  // Imported lazily so unit tests can import this module without initialising
  // the Admin SDK.
  const admin = require('firebase-admin');
  const { getFirestore } = require('firebase-admin/firestore');
  const { logger } = require('firebase-functions');

  return { db: getFirestore(admin.app()), logger };
}

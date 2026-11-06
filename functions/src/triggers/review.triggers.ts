import {
  FirestoreEvent,
  QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey, summarizeText } from '../notifications/helpers';
import { NotificationContext, NotificationPayload } from '../notifications/types';
import { normalizeRating } from '../ratings/summary';

/** Characters of the review text kept in the push body. */
const MAX_SNIPPET_LENGTH = 80;

export interface DesignerReviewInput {
  reviewId: string;
  /** Designer the review points at (`ref_id`); also the recipient uid. */
  designerId: string;
  /** Reviewer uid (`comment.author.uid`). */
  authorId: string;
  authorName: string;
  rating: unknown;
  commentText: string;
}

/**
 * Builds the notification a designer receives when someone reviews them.
 *
 * Pure so the shape of the body — and the self-review suppression — is unit
 * tested without Firestore. Returns `null` when there is nothing to send.
 */
export function buildDesignerReviewNotification(
  input: DesignerReviewInput
): NotificationPayload | null {
  const { reviewId, designerId, authorId, authorName, rating, commentText } =
    input;

  // A designer reviewing their own profile is not worth a push.
  if (!reviewId || !designerId || authorId === designerId) return null;

  const who = authorName.trim() || 'A client';
  const stars = normalizeRating(rating);
  const snippet = summarizeText(commentText, MAX_SNIPPET_LENGTH);
  const starsLabel =
    stars === null ? '' : `${stars} star${stars === 1 ? '' : 's'}`;

  let body: string;
  if (stars !== null && snippet) {
    body = `${who} rated you ${starsLabel}: "${snippet}"`;
  } else if (stars !== null) {
    body = `${who} rated you ${starsLabel}.`;
  } else if (snippet) {
    body = `${who} left a review: "${snippet}"`;
  } else {
    body = `${who} reviewed your profile.`;
  }

  return {
    recipientUserId: designerId,
    title: 'New review',
    body,
    type: 'review',
    event: 'review_received',
    // One notification per review document.
    idempotencyKey: buildIdempotencyKey(['designer', 'review', reviewId]),
    audience: 'designer',
    refId: reviewId,
    refType: 'designer_review',
    designerId,
    data: {
      user_id: authorId,
      // Drives the star row in the inbox card; absent when no stars were given.
      ...(stars === null ? {} : { rating: String(stars) }),
    },
  };
}

/**
 * A review is created → tell the designer.
 *
 * Path: `designer_reviews/{reviewId}`. Only the first write is notified; the
 * app submits with `set(merge: true)`, so later edits (or the rating aggregate
 * trigger) do not produce a second push.
 */
export async function onDesignerReviewCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data() as Record<string, unknown>;
  const comment = asRecord(data.comment);
  const author = asRecord(comment.author);

  // `ref_id` is the designer uid; `data.uid` is the review id, not the author.
  const designerId = text(data.ref_id) || text(comment.ref_id);
  const authorId = text(author.uid);

  if (!designerId || !authorId) return;

  const context = buildContext();

  // Only real designers can be notified: any signed-in user may write a review
  // document, so an arbitrary `ref_id` must not push to an unrelated account.
  const repository = new NotificationRepository(context.db);
  if (!(await repository.designerExists(designerId))) {
    context.logger.info('Review references an unknown designer; skipping', {
      designerId,
      reviewId: snapshot.id,
    });
    return;
  }

  const payload = buildDesignerReviewNotification({
    reviewId: snapshot.id,
    designerId,
    authorId,
    authorName: text(author.name) || (await repository.getUserDisplayName(authorId)),
    rating: data.rating,
    commentText: text(comment.text),
  });

  if (!payload) return; // self-review

  await deliverNotification(context, payload);
}

function asRecord(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : {};
}

function text(value: unknown): string {
  return value === undefined || value === null ? '' : String(value).trim();
}

function buildContext(): NotificationContext {
  // Imported lazily so unit tests can import this module without initialising
  // the Admin SDK.
  const admin = require('firebase-admin');
  const { getFirestore } = require('firebase-admin/firestore');
  const { getMessaging } = require('firebase-admin/messaging');
  const { logger } = require('firebase-functions');

  return {
    db: getFirestore(admin.app()),
    messaging: getMessaging(admin.app()),
    logger,
  };
}

import {
  FirestoreEvent,
  QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey, summarizeText } from '../notifications/helpers';
import { NotificationContext, NotificationPayload } from '../notifications/types';

/** Characters of the comment kept in the push body. */
const MAX_SNIPPET_LENGTH = 80;

export interface TrendCommentInput {
  trendId: string;
  commentId: string;
  /** The user who wrote the comment. */
  authorId: string;
  authorName: string;
  /** Author of the trend, i.e. the recipient. */
  ownerId: string;
  commentText: string;
}

/**
 * Builds the notification a trend's owner receives when someone comments.
 *
 * Pure so the wording and the self-comment suppression are unit tested.
 * Returns `null` when there is nobody to notify.
 */
export function buildTrendCommentNotification(
  input: TrendCommentInput
): NotificationPayload | null {
  const { trendId, commentId, authorId, authorName, ownerId, commentText } =
    input;

  if (!trendId || !commentId || !ownerId) return null;

  // Commenting on your own trend must not notify you.
  if (ownerId === authorId) return null;

  const who = authorName.trim() || 'Someone';
  const snippet = summarizeText(commentText, MAX_SNIPPET_LENGTH);

  return {
    recipientUserId: ownerId,
    title: 'New comment on your trend',
    body: snippet
      ? `${who} commented: "${snippet}"`
      : `${who} commented on your trend.`,
    type: 'trend',
    event: 'trend_commented',
    // One notification per comment document.
    idempotencyKey: buildIdempotencyKey([
      'trend',
      'commented',
      trendId,
      commentId,
    ]),
    audience: 'user',
    refId: trendId,
    refType: 'trend',
    data: { user_id: authorId, comment_id: commentId },
  };
}

/**
 * A comment is created → tell the trend's owner.
 *
 * Path: `trends/{trendId}/comments/{commentId}`. The app writes comments with
 * `.add()`, so the document id is generated; the author is read from
 * `author.uid` because `uid` on the document mirrors the generated id.
 *
 * Deleting a comment is silent.
 */
export async function onTrendCommentCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const trendId = event.params.trendId;
  if (!trendId) return;

  const data = snapshot.data() as Record<string, unknown>;
  const author = asRecord(data.author);
  const authorId = text(author.uid);
  if (!authorId) return;

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  const trend = await repository.getTrendAuthor(trendId);
  if (!trend) {
    context.logger.info('Comment on a missing trend; no owner to notify', {
      trendId,
    });
    return;
  }

  const payload = buildTrendCommentNotification({
    trendId,
    commentId: snapshot.id,
    authorId,
    authorName: text(author.name) || (await repository.getUserDisplayName(authorId)),
    ownerId: trend.userId,
    commentText: text(data.text),
  });

  if (!payload) return; // comment on your own trend

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

import {
  FirestoreEvent,
  QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey } from '../notifications/helpers';
import { NotificationContext, NotificationPayload } from '../notifications/types';

export interface TrendLikeInput {
  trendId: string;
  /** The user who tapped like. */
  likerId: string;
  /** Display name of the liker, empty when unknown. */
  likerName: string;
  /** Author of the trend. */
  authorId: string;
}

/**
 * Builds the notification a trend's author receives when someone likes it.
 *
 * Pure so the suppression rule is unit tested: liking your own post must never
 * notify you. Returns `null` when there is no one to notify.
 */
export function buildTrendLikeNotification(
  input: TrendLikeInput
): NotificationPayload | null {
  const { trendId, likerId, likerName, authorId } = input;

  if (!trendId || !authorId || authorId === likerId) return null;

  const who = likerName.trim() || 'Someone';

  return {
    recipientUserId: authorId,
    title: 'New like on your trend',
    body: `${who} liked your trend.`,
    type: 'trend',
    event: 'trend_liked',
    // One notification per (trend, liker) pair: unliking and liking again must
    // not spam the author, and a retried event must not send twice.
    idempotencyKey: buildIdempotencyKey(['trend', 'liked', trendId, likerId]),
    audience: 'user',
    refId: trendId,
    refType: 'trend',
    data: { user_id: likerId },
  };
}

/**
 * A like document is created → tell the trend's author.
 *
 * Path: `trends/{trendId}/likes/{likerId}`. The document id is the liker's uid,
 * so the recipient of the like is always resolvable from `event.params`.
 *
 * Unlikes (document deletion) are intentionally silent.
 */
export async function onTrendLikeCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const trendId = event.params.trendId;
  const likerId = event.params.userId;
  if (!trendId || !likerId) return;

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  const trend = await repository.getTrendAuthor(trendId);
  if (!trend) {
    context.logger.info('Like on a missing trend; no author to notify', {
      trendId,
    });
    return;
  }

  // The like document carries an author snapshot; fall back to the profile.
  const likeData = snapshot.data() as Record<string, unknown>;
  const snapshotName = nameOf(likeData.author);
  const likerName =
    snapshotName || (await repository.getUserDisplayName(likerId));

  const payload = buildTrendLikeNotification({
    trendId,
    likerId,
    likerName,
    authorId: trend.userId,
  });

  if (!payload) {
    // Author liking their own trend.
    return;
  }

  await deliverNotification(context, payload);
}

function nameOf(author: unknown): string {
  if (typeof author !== 'object' || author === null) return '';
  const name = (author as Record<string, unknown>).name;
  return typeof name === 'string' ? name.trim() : '';
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

import {
  FirestoreEvent,
  QueryDocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey } from '../notifications/helpers';
import { NotificationContext, NotificationPayload } from '../notifications/types';

export interface ClientLinkedInput {
  /** The linked user, i.e. the recipient. */
  userId: string;
  clientId: string;
  /** Designer who created the client record. */
  designerId: string;
  designerName: string;
}

/**
 * Builds the notification sent when a designer's client record is linked to a
 * Fashionista account.
 *
 * Pure so the wording and the suppression rule are unit tested. Returns `null`
 * when there is nobody to notify.
 */
export function buildClientLinkedNotification(
  input: ClientLinkedInput
): NotificationPayload | null {
  const { userId, clientId, designerId, designerName } = input;

  if (!userId || !clientId || !designerId) return null;

  // A designer linking their own account to their own client record.
  if (designerId === userId) return null;

  const who = designerName.trim() || 'A designer';

  return {
    recipientUserId: userId,
    title: 'New Client',
    body: `${who} has added you as a client`,
    type: 'client',
    event: 'client_linked',
    // One notification per (user, client record) pair.
    idempotencyKey: buildIdempotencyKey(['client', 'linked', userId, clientId]),
    audience: 'client',
    refId: clientId,
    refType: 'client',
    designerId,
    data: { client_id: clientId },
  };
}

/**
 * A designer's client record is linked to a registered user → welcome them.
 *
 * Path: `client_measurements/{userId}/clients/{clientId}`, written by
 * `linkClientToUser` only after a matching user account is found. The link is
 * created with `set(merge: true)`, so re-linking an existing client is an
 * update and does not fire again.
 */
export async function onClientLinked(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const userId = event.params.userId;
  const clientId = event.params.clientId ?? snapshot.id;
  if (!userId || !clientId) return;

  const data = snapshot.data() as Record<string, unknown>;
  const designerId = text(data.designer_id);
  if (!designerId) return;

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  const payload = buildClientLinkedNotification({
    userId,
    clientId,
    designerId,
    designerName: await repository.getDesignerDisplayName(designerId),
  });

  if (!payload) return; // self-link

  await deliverNotification(context, payload);
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

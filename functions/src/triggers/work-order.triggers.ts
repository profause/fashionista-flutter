import { FirestoreEvent, Change, QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey, statusChanged } from '../notifications/helpers';
import { NotificationContext } from '../notifications/types';

type WorkOrderData = Record<string, unknown>;

function text(value: unknown): string {
  return value === undefined || value === null ? '' : String(value);
}

function clientIdOf(order: WorkOrderData): string {
  const client = order.client as Record<string, unknown> | undefined;
  return text(client?.uid ?? order.client_id);
}

/** New work order → notify the designer. */
export async function onWorkOrderCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const order = snapshot.data() as WorkOrderData;
  const designerId = text(order.created_by);
  if (!designerId) return;

  const clientName = text(
    (order.client as Record<string, unknown> | undefined)?.name ?? 'A client'
  );

  await deliverNotification(buildContext(), {
    recipientUserId: designerId,
    title: 'New order received',
    body: `${clientName} created "${text(order.title) || 'an order'}"`,
    type: 'work_order_status_progress',
    event: 'order_received',
    idempotencyKey: buildIdempotencyKey(['order', 'created', snapshot.id]),
    audience: 'designer',
    refId: snapshot.id,
    refType: 'work_order',
    designerId,
  });
}

/**
 * Status change on the work order → notify the linked client.
 *
 * A designer-scoped client id is not necessarily a Fashionista user, so the
 * recipient is resolved through the `client_measurements` linkage. No linkage
 * means no notification (never a guessed recipient).
 */
export async function onWorkOrderUpdated(
  event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>
): Promise<void> {
  const change = event.data;
  if (!change) return;

  const before = change.before.data() as WorkOrderData;
  const after = change.after.data() as WorkOrderData;

  if (!statusChanged(before, after)) return;
  if (after.notify_client === false) return;

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  const clientId = clientIdOf(after);
  const recipient = await repository.resolveUserIdForClient(clientId);
  if (!recipient) {
    context.logger.info('Order status change has no linked user', {
      orderId: change.after.id,
    });
    return;
  }

  const status = text(after.status);
  await deliverNotification(context, {
    recipientUserId: recipient,
    title: status === 'completed' ? 'Your order is ready' : 'Order updated',
    body: `"${text(after.title) || 'Your order'}" is now ${status || 'updated'}.`,
    type: 'work_order_status_progress',
    event:
      status === 'completed' ? 'order_completed' : 'order_status_updated',
    idempotencyKey: buildIdempotencyKey([
      'order',
      status,
      change.after.id,
    ]),
    audience: 'client',
    refId: change.after.id,
    refType: 'work_order',
    designerId: text(after.created_by),
  });
}

/** Progress entry explicitly flagged `notify_client`. */
export async function onWorkOrderProgressCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const progress = snapshot.data() as WorkOrderData;
  if (progress.notify_client !== true) return;

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  const orderId = text(progress.work_order_id);
  const recipient = await repository.resolveUserIdForClient(
    text(progress.client_id)
  );
  if (!recipient) return;

  await deliverNotification(context, {
    recipientUserId: recipient,
    title: 'Order update',
    body: text(progress.description) || 'Your order has a new update.',
    type: 'work_order_status_progress',
    event: 'order_status_updated',
    idempotencyKey: buildIdempotencyKey([
      'order_progress',
      snapshot.id,
    ]),
    audience: 'client',
    refId: orderId,
    refType: 'work_order',
    designerId: text(progress.created_by),
  });
}

function buildContext(): NotificationContext {
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

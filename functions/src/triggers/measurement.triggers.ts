import { FirestoreEvent, Change, DocumentSnapshot } from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey } from '../notifications/helpers';
import { NotificationContext } from '../notifications/types';

type MeasurementData = Record<string, unknown>;

function text(value: unknown): string {
  return value === undefined || value === null ? '' : String(value);
}

/**
 * Designer changes a client's measurements → notify the linked user.
 *
 * Measurement values are never included in the body; only the body part name
 * (a label, not a value) and the client id.
 */
export async function onMeasurementWritten(
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined>
): Promise<void> {
  const change = event.data;
  if (!change) return;

  const after = change.after.exists
    ? (change.after.data() as MeasurementData)
    : undefined;
  if (!after) return; // deletions are not notified

  const context = buildContext();
  const repository = new NotificationRepository(context.db);

  // `clients/{clientId}/measurements/{measurementId}`
  const segments = change.after.ref.path.split('/');
  const clientIndex = segments.indexOf('clients') + 1;
  const clientId = segments[clientIndex] ?? text(after.client_id);
  if (!clientId) return;

  const recipient = await repository.resolveUserIdForClient(clientId);
  if (!recipient) {
    context.logger.info('Measurement update has no linked user', { clientId });
    return;
  }

  const bodyPart = text(after.body_part);
  await deliverNotification(context, {
    recipientUserId: recipient,
    title: 'Measurements updated',
    body: bodyPart
      ? `Your designer updated your ${bodyPart} measurements.`
      : 'Your designer updated your measurements.',
    type: 'measurement',
    event: 'measurement_updated',
    idempotencyKey: buildIdempotencyKey([
      'measurement',
      change.after.id,
      String(change.after.updateTime?.toMillis() ?? ''),
    ]),
    audience: 'client',
    refId: clientId,
    refType: 'measurement',
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

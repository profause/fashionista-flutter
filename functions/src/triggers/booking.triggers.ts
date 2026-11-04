import { FirestoreEvent, Change, QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';
import { NotificationRepository } from '../notifications/repository';
import { deliverNotification } from '../notifications/dispatcher';
import { buildIdempotencyKey } from '../notifications/helpers';
import { NotificationContext } from '../notifications/types';

type BookingData = Record<string, unknown>;

function text(value: unknown): string {
  return value === undefined || value === null ? '' : String(value);
}

/** Human-readable slot, e.g. `2026-11-16 at 8:30 AM`. */
function describeSlot(data: BookingData): string {
  const date = text(data.date);
  const start = text(data.start_time);
  if (!date || !start) return 'your appointment';

  const [hoursRaw, minutes] = start.split(':');
  const hours = Number(hoursRaw);
  if (Number.isNaN(hours)) return `${date} at ${start}`;

  const suffix = hours < 12 ? 'AM' : 'PM';
  const display = hours % 12 === 0 ? 12 : hours % 12;
  return `${date} at ${display}:${minutes ?? '00'} ${suffix}`;
}

/** The signed-in party that caused this transition, when recorded. */
function actorOf(after: BookingData): string {
  return text(after.last_status_actor ?? after.status_updated_by);
}

/**
 * New booking request → notify the designer.
 *
 * The app also writes an inbox record for this event; the delivery marker makes
 * the push idempotent regardless.
 */
export async function onBookingCreated(
  event: FirestoreEvent<QueryDocumentSnapshot | undefined>
): Promise<void> {
  const snapshot = event.data;
  if (!snapshot) return;

  const booking = snapshot.data() as BookingData;
  const designerId = text(booking.designer_id);
  const userId = text(booking.user_id);
  if (!designerId) return;

  const clientName = text(
    (booking.client as Record<string, unknown> | undefined)?.name ?? 'A client'
  );

  const context = buildContext();
  await deliverNotification(context, {
    recipientUserId: designerId,
    title: 'New appointment request',
    body: `${clientName} requested ${describeSlot(booking)}`,
    type: 'booking',
    event: 'appointment_requested',
    idempotencyKey: buildIdempotencyKey([
      'booking',
      'requested',
      snapshot.id,
    ]),
    audience: 'designer',
    refId: snapshot.id,
    refType: 'booking',
    designerId,
    data: { user_id: userId },
  });
}

/**
 * Status transitions → notify the other party.
 *
 * Only meaningful transitions produce a notification, and the actor is never
 * notified about their own action.
 */
export async function onBookingUpdated(
  event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>
): Promise<void> {
  const change = event.data;
  if (!change) return;

  const before = change.before.data() as BookingData;
  const after = change.after.data() as BookingData;

  const beforeStatus = text(before.status);
  const afterStatus = text(after.status);
  if (beforeStatus === afterStatus) return;

  const designerId = text(after.designer_id);
  const clientUserId = text(after.user_id);
  const actor = actorOf(after);
  const slot = describeSlot(after);

  const context = buildContext();

  // Designer confirmed/declined → the client.
  if (
    (afterStatus === 'confirmed' || afterStatus === 'declined') &&
    clientUserId &&
    actor !== clientUserId
  ) {
    const confirmed = afterStatus === 'confirmed';
    await deliverNotification(context, {
      recipientUserId: clientUserId,
      title: confirmed ? 'Appointment confirmed' : 'Appointment declined',
      body: confirmed
        ? `Your appointment on ${slot} has been confirmed.`
        : `Your appointment on ${slot} was declined.`,
      type: 'booking',
      event: confirmed ? 'appointment_confirmed' : 'appointment_declined',
      idempotencyKey: buildIdempotencyKey([
        'booking',
        afterStatus,
        change.after.id,
      ]),
      audience: 'client',
      refId: change.after.id,
      refType: 'booking',
      designerId,
    });
    return;
  }

  // Cancellation → the other party.
  if (afterStatus === 'cancelled') {
    const cancelledByClient = actor === clientUserId;
    const recipient = cancelledByClient ? designerId : clientUserId;
    if (!recipient || recipient === actor) return;

    await deliverNotification(context, {
      recipientUserId: recipient,
      title: 'Appointment cancelled',
      body: cancelledByClient
        ? `An appointment on ${slot} was cancelled.`
        : `Your appointment on ${slot} was cancelled by the designer.`,
      type: 'booking',
      event: 'appointment_cancelled',
      idempotencyKey: buildIdempotencyKey([
        'booking',
        'cancelled',
        change.after.id,
      ]),
      audience: cancelledByClient ? 'designer' : 'client',
      refId: change.after.id,
      refType: 'booking',
      designerId,
    });
  }
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

export { NotificationRepository };

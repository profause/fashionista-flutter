import { Timestamp } from 'firebase-admin/firestore';
import { NotificationRepository, NotificationStore } from './repository';
import {
  NotificationContext,
  NotificationPayload,
  DeliveryResult,
  preferenceKeyFor,
} from './types';
import {
  isCategoryEnabled,
  redactToken,
} from './helpers';

/** FCM caps a multicast at 500 tokens per call. */
const MULTICAST_LIMIT = 500;

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

/**
 * Single entry point for delivering a notification: preference gate, inbox
 * history, idempotency, multicast send and invalid-token cleanup.
 *
 * Every trigger goes through here — no FCM logic lives in the triggers.
 */
export async function deliverNotification(
  context: NotificationContext,
  payload: NotificationPayload,
  store: NotificationStore = new NotificationRepository(context.db)
): Promise<DeliveryResult> {
  const result: DeliveryResult = {
    attempted: 0,
    sent: 0,
    failed: 0,
    invalidTokens: [],
  };

  if (!payload.recipientUserId) {
    context.logger.warn('Notification skipped: missing recipient', {
      event: payload.event,
    });
    return result;
  }

  const repository = store;

  // 1. Preference gate.
  //
  // A read failure must not silently allow the push: log it and rethrow so the
  // platform retries the event. Nothing has been written yet at this point.
  let pushEnabled: boolean;
  try {
    const preferences = await repository.getPreferences(
      payload.recipientUserId
    );
    pushEnabled = isCategoryEnabled(preferences, preferenceKeyFor(payload));
  } catch (error) {
    context.logger.error('Failed to read notification preferences', {
      event: payload.event,
      recipient: payload.recipientUserId,
      error: error instanceof Error ? error.message : String(error),
    });
    throw error;
  }

  // 2. Idempotent history creation.
  const historyCreated = await repository.createHistoryIfAbsent(
    payload.recipientUserId,
    payload.idempotencyKey,
    {
      title: payload.title,
      description: payload.body,
      type: payload.type,
      event: payload.event,
      refId: payload.refId,
      refType: payload.refType,
      from: payload.designerId ?? '',
      to: payload.recipientUserId,
      data: {
        type: payload.type,
        event: payload.event,
        ref_id: payload.refId,
        ref_type: payload.refType,
        audience: payload.audience,
        ...(payload.designerId ? { designer_id: payload.designerId } : {}),
        ...(payload.data ?? {}),
      },
      createdAt: Timestamp.now(),
    }
  );

  if (!historyCreated) {
    context.logger.info('Notification history already exists', {
      id: payload.idempotencyKey,
    });
  }

  // 3. A disabled category stops the push, never the inbox record: the in-app
  //    activity feed is an event log, not a delivery artefact.
  if (!pushEnabled) {
    context.logger.info('Push suppressed by preferences', {
      event: payload.event,
      recipient: payload.recipientUserId,
      preference: preferenceKeyFor(payload),
    });
    return result;
  }

  // 4. Delivery claim — a retried trigger must not send twice, even when the
  //    inbox record was written earlier by the app.
  const claimed = await repository.claimDelivery(payload.idempotencyKey);
  if (!claimed) {
    context.logger.info('Notification delivery already claimed', {
      id: payload.idempotencyKey,
    });
    return result;
  }

  // 5. Recipient devices.
  const devices = await repository.getActiveDevices(payload.recipientUserId);
  if (devices.length === 0) {
    context.logger.info('No active devices for recipient', {
      recipient: payload.recipientUserId,
    });
    return result;
  }

  const data: Record<string, string> = {
    type: payload.type,
    event: payload.event,
    ref_id: payload.refId,
    ref_type: payload.refType,
    audience: payload.audience,
    ...(payload.designerId ? { designer_id: payload.designerId } : {}),
    ...(payload.data ?? {}),
  };

  for (let start = 0; start < devices.length; start += MULTICAST_LIMIT) {
    const batch = devices.slice(start, start + MULTICAST_LIMIT);
    const tokens = batch.map((device) => device.token);

    result.attempted += tokens.length;

    try {
      const response = await context.messaging.sendEachForMulticast({
        tokens,
        notification: { title: payload.title, body: payload.body },
        data,
        android: {
          priority: 'high',
          notification: { channelId: 'fashionista_general' },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
      });

      result.sent += response.successCount;
      result.failed += response.failureCount;

      response.responses.forEach((item, index) => {
        if (item.success) return;

        const code = item.error?.code ?? '';
        if (INVALID_TOKEN_CODES.has(code)) {
          result.invalidTokens.push(tokens[index]);
        }

        context.logger.warn('FCM send failed', {
          token: redactToken(tokens[index]),
          code: code || 'unknown',
        });
      });
    } catch (error) {
      result.failed += tokens.length;
      context.logger.error('FCM multicast threw', {
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  // 6. Cleanup so dead devices do not accumulate.
  await repository.deactivateTokens(
    payload.recipientUserId,
    result.invalidTokens
  );

  return result;
}

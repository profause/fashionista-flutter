import { Timestamp } from 'firebase-admin/firestore';
import { deliverNotification } from '../src/notifications/dispatcher';
import {
  HistoryPayload,
  NotificationStore,
} from '../src/notifications/repository';
import {
  DeviceToken,
  NotificationContext,
  NotificationPayload,
  StoredPreferences,
} from '../src/notifications/types';

class FakeStore implements NotificationStore {
  devices: DeviceToken[] = [];
  preferences: StoredPreferences = {};
  failPreferences = false;
  history = new Map<string, HistoryPayload>();
  deliveries = new Set<string>();
  deactivated: string[] = [];

  async getActiveDevices(): Promise<DeviceToken[]> {
    return this.devices;
  }

  async getPreferences(): Promise<StoredPreferences> {
    if (this.failPreferences) throw new Error('preferences unavailable');
    return this.preferences;
  }

  async createHistoryIfAbsent(
    _userId: string,
    notificationId: string,
    payload: HistoryPayload
  ): Promise<boolean> {
    if (this.history.has(notificationId)) return false;
    this.history.set(notificationId, payload);
    return true;
  }

  async claimDelivery(notificationId: string): Promise<boolean> {
    if (this.deliveries.has(notificationId)) return false;
    this.deliveries.add(notificationId);
    return true;
  }

  async deactivateTokens(
    _userId: string,
    invalidTokens: string[]
  ): Promise<void> {
    this.deactivated.push(...invalidTokens);
  }
}

function buildContext(
  behaviour: (tokens: string[]) => {
    success: boolean;
    code?: string;
  }[]
): { context: NotificationContext; sends: string[][] } {
  const sends: string[][] = [];
  const context: NotificationContext = {
    db: {} as NotificationContext['db'],
    logger: {
      info: () => undefined,
      warn: () => undefined,
      error: () => undefined,
    },
    messaging: {
      sendEachForMulticast: async (message) => {
        sends.push(message.tokens);
        const responses = behaviour(message.tokens).map((item) => ({
          success: item.success,
          error: item.code ? { code: item.code } : undefined,
        }));
        return {
          successCount: responses.filter((r) => r.success).length,
          failureCount: responses.filter((r) => !r.success).length,
          responses,
        };
      },
    },
  };
  return { context, sends };
}

function payload(overrides: Partial<NotificationPayload> = {}): NotificationPayload {
  return {
    recipientUserId: 'designer_1',
    title: 'New appointment request',
    body: 'Ama requested 2026-11-16 at 8:30 AM',
    type: 'booking',
    event: 'appointment_requested',
    idempotencyKey: 'booking__requested__b1',
    audience: 'designer',
    refId: 'b1',
    refType: 'booking',
    designerId: 'designer_1',
    ...overrides,
  };
}

describe('deliverNotification', () => {
  it('writes history and sends to every active device', async () => {
    const store = new FakeStore();
    store.devices = [
      { deviceId: 'd1', token: 't1' },
      { deviceId: 'd2', token: 't2' },
    ];
    const { context, sends } = buildContext((tokens) =>
      tokens.map(() => ({ success: true }))
    );

    const result = await deliverNotification(context, payload(), store);

    expect(store.history.size).toBe(1);
    expect(sends[0]).toEqual(['t1', 't2']);
    expect(result.sent).toBe(2);
    expect(result.failed).toBe(0);
  });

  it('does not send twice for a retried trigger', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    const { context, sends } = buildContext(() => [{ success: true }]);

    await deliverNotification(context, payload(), store);
    await deliverNotification(context, payload(), store);

    expect(sends.length).toBe(1);
    expect(store.history.size).toBe(1);
  });

  it('suppresses the push but keeps the inbox history', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    store.preferences = { appointments: false };
    const { context, sends } = buildContext(() => [{ success: true }]);

    const result = await deliverNotification(context, payload(), store);

    expect(sends).toHaveLength(0);
    expect(result.attempted).toBe(0);
    // In-app activity feed is an event log, not a delivery artefact.
    expect(store.history.size).toBe(1);
  });

  it('suppresses a disabled category through a legacy key', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    store.preferences = { social: false };
    const { context, sends } = buildContext(() => [{ success: true }]);

    await deliverNotification(
      context,
      payload({ type: 'trend', event: 'trend_liked' }),
      store
    );

    expect(sends).toHaveLength(0);
    expect(store.history.size).toBe(1);
  });

  it('sends when the event-specific key is enabled', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    // The old `social` bucket disabled everything; the specific key wins.
    store.preferences = { social: false, trend_like: true };
    const { context, sends } = buildContext(() => [{ success: true }]);

    await deliverNotification(
      context,
      payload({ type: 'trend', event: 'trend_liked' }),
      store
    );

    expect(sends).toHaveLength(1);
  });

  it('refuses to send when the preference read fails', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    store.failPreferences = true;
    const { context, sends } = buildContext(() => [{ success: true }]);

    await expect(
      deliverNotification(context, payload(), store)
    ).rejects.toThrow('preferences unavailable');

    expect(sends).toHaveLength(0);
    expect(store.history.size).toBe(0);
  });

  it('does nothing when the recipient has no active devices', async () => {
    const store = new FakeStore();
    const { context, sends } = buildContext(() => [{ success: true }]);

    const result = await deliverNotification(context, payload(), store);

    expect(sends).toHaveLength(0);
    expect(result.attempted).toBe(0);
    // History is still recorded so the inbox shows the event.
    expect(store.history.size).toBe(1);
  });

  it('collects permanently invalid tokens for deactivation', async () => {
    const store = new FakeStore();
    store.devices = [
      { deviceId: 'd1', token: 'good' },
      { deviceId: 'd2', token: 'dead' },
    ];
    const { context } = buildContext((tokens) =>
      tokens.map((token) =>
        token === 'dead'
          ? { success: false, code: 'messaging/registration-token-not-registered' }
          : { success: true }
      )
    );

    const result = await deliverNotification(context, payload(), store);

    expect(result.sent).toBe(1);
    expect(result.failed).toBe(1);
    expect(store.deactivated).toEqual(['dead']);
  });

  it('does not deactivate tokens that failed for other reasons', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    const { context } = buildContext(() => [
      { success: false, code: 'messaging/internal-error' },
    ]);

    const result = await deliverNotification(context, payload(), store);

    expect(result.failed).toBe(1);
    expect(store.deactivated).toHaveLength(0);
  });

  it('counts a thrown multicast as a full batch failure', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    const { context } = buildContext(() => []);
    context.messaging.sendEachForMulticast = async () => {
      throw new Error('network down');
    };

    const result = await deliverNotification(context, payload(), store);

    expect(result.failed).toBe(1);
    expect(result.sent).toBe(0);
  });

  it('skips delivery when the recipient is missing', async () => {
    const store = new FakeStore();
    const { context, sends } = buildContext(() => [{ success: true }]);

    const result = await deliverNotification(
      context,
      payload({ recipientUserId: '' }),
      store
    );

    expect(sends).toHaveLength(0);
    expect(result.attempted).toBe(0);
  });

  it('preserves routing data on the history record', async () => {
    const store = new FakeStore();
    store.devices = [{ deviceId: 'd1', token: 't1' }];
    const { context } = buildContext(() => [{ success: true }]);

    await deliverNotification(context, payload(), store);

    const history = store.history.get('booking__requested__b1')!;
    expect(history.description).toContain('Ama');
    expect(history.event).toBe('appointment_requested');
    expect(history.type).toBe('booking');
    expect(history.createdAt).toBeInstanceOf(Timestamp);
  });

  it('sends in batches of at most 500 tokens', async () => {
    const store = new FakeStore();
    store.devices = Array.from({ length: 620 }, (_, index) => ({
      deviceId: `d${index}`,
      token: `t${index}`,
    }));
    const { context, sends } = buildContext((tokens) =>
      tokens.map(() => ({ success: true }))
    );

    await deliverNotification(context, payload(), store);

    expect(sends.map((batch) => batch.length)).toEqual([500, 120]);
  });
});

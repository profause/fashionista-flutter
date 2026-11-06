import { Firestore } from 'firebase-admin/firestore';

/** Coarse category the Flutter inbox uses to choose a widget. */
export type NotificationType =
  | 'appointment'
  | 'booking'
  | 'work_order_status_progress'
  | 'measurement'
  | 'trend'
  | 'review'
  | 'client'
  | 'info';

/**
 * Who the notification is for; drives routing on the device.
 *
 * `user` is used for social events (trend likes) whose recipient is neither a
 * client nor a designer in the booking sense.
 */
export type NotificationAudience = 'designer' | 'client' | 'user';

export interface NotificationPayload {
  recipientUserId: string;
  title: string;
  body: string;
  /** Coarse category. */
  type: NotificationType;
  /** Fine-grained event, e.g. `appointment_confirmed`. */
  event: string;
  /** Deterministic id so retries cannot duplicate the record or the push. */
  idempotencyKey: string;
  audience: NotificationAudience;
  refId: string;
  refType: string;
  designerId?: string;
  data?: Record<string, string>;
}

/**
 * Preference key per notification category.
 *
 * These strings are the contract shared with the Flutter app
 * (`lib/data/models/notification/notification_preferences.dart`). A test
 * asserts both lists match; changing one side silently disables the gate.
 */
export type NotificationPreferenceKey =
  | 'trend_like'
  | 'trend_comment'
  | 'appointments'
  | 'appointment_reminder'
  | 'designer_rating'
  | 'order_updates'
  | 'measurement_updates'
  | 'clients';

export type NotificationPreferences = Record<NotificationPreferenceKey, boolean>;

/** Every category starts enabled: a user without a document gets everything. */
export const DEFAULT_PREFERENCES: NotificationPreferences = {
  trend_like: true,
  trend_comment: true,
  appointments: true,
  appointment_reminder: true,
  designer_rating: true,
  order_updates: true,
  measurement_updates: true,
  clients: true,
};

/**
 * Keys written before the taxonomy split, still honoured on read.
 *
 * `social` gated trend likes, trend comments and designer reviews at once.
 */
export const LEGACY_PREFERENCE_KEYS: Record<string, NotificationPreferenceKey[]> =
  {
    social: ['trend_like', 'trend_comment', 'designer_rating'],
    orders: ['order_updates'],
    measurements: ['measurement_updates'],
    reminders: ['appointment_reminder'],
  };

/** Raw shape read from `users/{uid}/settings/notifications`. */
export type StoredPreferences = Record<string, unknown>;

/** Legacy keys that may stand in for [key], newest-first semantics. */
export function legacyKeysFor(key: NotificationPreferenceKey): string[] {
  return Object.entries(LEGACY_PREFERENCE_KEYS)
    .filter(([, keys]) => keys.includes(key))
    .map(([legacyKey]) => legacyKey);
}

/**
 * Effective value for a category.
 *
 * Order: the current key, then its legacy alias, then the default. An explicit
 * `false` on either key always wins over the default.
 */
export function isPreferenceEnabled(
  stored: StoredPreferences | undefined,
  key: NotificationPreferenceKey
): boolean {
  if (stored) {
    const current = stored[key];
    if (typeof current === 'boolean') return current;

    for (const legacyKey of legacyKeysFor(key)) {
      const value = stored[legacyKey];
      if (typeof value === 'boolean') return value;
    }
  }

  return DEFAULT_PREFERENCES[key];
}

/**
 * Category a notification belongs to.
 *
 * The fine-grained `event` decides, because `type` is a coarse persisted value
 * that cannot separate a like from a comment.
 */
export function preferenceKeyFor(
  payload: Pick<NotificationPayload, 'type' | 'event'>
): NotificationPreferenceKey {
  switch (payload.event) {
    case 'trend_liked':
      return 'trend_like';
    case 'trend_commented':
      return 'trend_comment';
    case 'review_received':
      return 'designer_rating';
    case 'client_linked':
      return 'clients';
    case 'order_received':
    case 'order_status_updated':
      return 'order_updates';
    case 'measurement_updated':
      return 'measurement_updates';
    case 'appointment_reminder':
      return 'appointment_reminder';
    default:
      break;
  }

  // Fallback for producers that only set a type.
  switch (payload.type) {
    case 'appointment':
    case 'booking':
      return 'appointments';
    case 'review':
      return 'designer_rating';
    case 'client':
      return 'clients';
    case 'work_order_status_progress':
      return 'order_updates';
    case 'measurement':
      return 'measurement_updates';
    case 'trend':
      return 'trend_like';
    default:
      return 'appointments';
  }
}

export interface DeviceToken {
  deviceId: string;
  token: string;
}

export interface DeliveryResult {
  attempted: number;
  sent: number;
  failed: number;
  invalidTokens: string[];
}

export interface NotificationContext {
  db: Firestore;
  messaging: {
    sendEachForMulticast: (message: {
      tokens: string[];
      notification: { title: string; body: string };
      data: Record<string, string>;
      android?: Record<string, unknown>;
      apns?: Record<string, unknown>;
    }) => Promise<{
      successCount: number;
      failureCount: number;
      responses: Array<{
        success: boolean;
        error?: { code?: string; message?: string };
      }>;
    }>;
  };
  logger: {
    info: (message: string, ...args: unknown[]) => void;
    warn: (message: string, ...args: unknown[]) => void;
    error: (message: string, ...args: unknown[]) => void;
  };
}


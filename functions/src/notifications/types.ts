import { Firestore } from 'firebase-admin/firestore';

/** Coarse category the Flutter inbox uses to choose a widget. */
export type NotificationType =
  | 'booking'
  | 'work_order_status_progress'
  | 'measurement'
  | 'info';

/** Who the notification is for; drives routing on the device. */
export type NotificationAudience = 'designer' | 'client';

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

export interface NotificationPreferences {
  appointments: boolean;
  orders: boolean;
  measurements: boolean;
  reminders: boolean;
}

export const DEFAULT_PREFERENCES: NotificationPreferences = {
  appointments: true,
  orders: true,
  measurements: true,
  reminders: true,
};

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

/** Category used for the preference gate. */
export function preferenceKeyFor(
  type: NotificationType
): keyof NotificationPreferences {
  switch (type) {
    case 'booking':
      return 'appointments';
    case 'work_order_status_progress':
      return 'orders';
    case 'measurement':
      return 'measurements';
    default:
      return 'appointments';
  }
}

import { NotificationPreferences, DEFAULT_PREFERENCES } from './types';

/** Truncates a token so logs never contain a usable credential. */
export function redactToken(token: string): string {
  if (!token) return '(empty)';
  return `${token.slice(0, 6)}…${token.slice(-4)}`;
}

/** Builds the notification document id used for both history and delivery. */
export function buildIdempotencyKey(parts: Array<string | undefined>): string {
  return parts
    .filter((part): part is string => !!part && part.trim().length > 0)
    .map((part) => part.trim().replace(/[^A-Za-z0-9_-]/g, '_'))
    .join('__');
}

/**
 * Firestore triggers can run more than once for the same change. A transition
 * only produces a notification when the status actually moved.
 */
export function statusChanged(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): boolean {
  if (!after) return false;
  const previousStatus = before?.status;
  return previousStatus !== after.status;
}

/** True when a party is the actor of the change and should not be notified. */
export function isSelfNotification(
  actorId: string | undefined,
  recipientUserId: string
): boolean {
  return !!actorId && actorId === recipientUserId;
}

/** Preference gate; missing documents default to enabled. */
export function isCategoryEnabled(
  preferences: Partial<NotificationPreferences> | undefined,
  key: keyof NotificationPreferences
): boolean {
  if (!preferences) return true;
  const value = preferences[key];
  return value === undefined ? true : value === true;
}

export function mergePreferences(
  stored: Partial<NotificationPreferences> | undefined
): NotificationPreferences {
  return { ...DEFAULT_PREFERENCES, ...(stored ?? {}) };
}

/** Removes undefined values so Firestore does not reject the write. */
export function compact<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(
    Object.entries(value).filter(([, entry]) => entry !== undefined)
  ) as T;
}

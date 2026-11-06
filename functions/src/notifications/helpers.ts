import {
  DEFAULT_PREFERENCES,
  NotificationPreferences,
  NotificationPreferenceKey,
  StoredPreferences,
  isPreferenceEnabled,
} from './types';

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

/**
 * Preference gate.
 *
 * Delegates to {@link isPreferenceEnabled} so a legacy key (`social`, `orders`,
 * `measurements`, `reminders`) still disables the category it used to cover,
 * and a missing document or field falls back to the default.
 */
export function isCategoryEnabled(
  stored: StoredPreferences | undefined,
  key: NotificationPreferenceKey
): boolean {
  return isPreferenceEnabled(stored, key);
}

/** Defaults with the stored values applied; legacy keys are ignored. */
export function mergePreferences(
  stored: StoredPreferences | undefined
): NotificationPreferences {
  const merged = { ...DEFAULT_PREFERENCES };
  for (const key of Object.keys(DEFAULT_PREFERENCES) as NotificationPreferenceKey[]) {
    const value = stored?.[key];
    if (typeof value === 'boolean') merged[key] = value;
  }
  return merged;
}

/** Removes undefined values so Firestore does not reject the write. */
export function compact<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(
    Object.entries(value).filter(([, entry]) => entry !== undefined)
  ) as T;
}

/**
 * Collapses whitespace and shortens user text for a push body.
 *
 * Multi-line input stays one readable line; long input is cut on a word
 * boundary and marked with an ellipsis so it never ends mid-word.
 */
export function summarizeText(value: string, maxLength = 80): string {
  const collapsed = value.replace(/\s+/g, ' ').trim();
  if (collapsed.length <= maxLength) return collapsed;

  const cut = collapsed.slice(0, maxLength);
  const lastSpace = cut.lastIndexOf(' ');
  const trimmed = lastSpace > maxLength / 2 ? cut.slice(0, lastSpace) : cut;

  return `${trimmed.trimEnd()}…`;
}

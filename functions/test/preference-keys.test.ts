import {
  DEFAULT_PREFERENCES,
  NotificationPreferenceKey,
  NotificationType,
  isPreferenceEnabled,
  preferenceKeyFor,
} from '../src/notifications/types';

/** Every key the Flutter app can display. Kept in sync deliberately. */
const APP_KEYS: NotificationPreferenceKey[] = [
  'trend_like',
  'trend_comment',
  'appointments',
  'appointment_reminder',
  'designer_rating',
  'order_updates',
  'measurement_updates',
  'clients',
];

describe('preference keys', () => {
  it('matches the list the Flutter model declares', () => {
    expect(Object.keys(DEFAULT_PREFERENCES).sort()).toEqual([...APP_KEYS].sort());
  });

  it('defaults every category to enabled', () => {
    for (const key of APP_KEYS) {
      expect(DEFAULT_PREFERENCES[key]).toBe(true);
      expect(isPreferenceEnabled(undefined, key)).toBe(true);
      expect(isPreferenceEnabled({}, key)).toBe(true);
    }
  });
});

describe('preferenceKeyFor', () => {
  const cases: Array<[NotificationType, string, NotificationPreferenceKey]> = [
    ['trend', 'trend_liked', 'trend_like'],
    ['trend', 'trend_commented', 'trend_comment'],
    ['appointment', 'appointment_requested', 'appointments'],
    ['appointment', 'appointment_confirmed', 'appointments'],
    ['appointment', 'appointment_declined', 'appointments'],
    ['appointment', 'appointment_cancelled', 'appointments'],
    ['review', 'review_received', 'designer_rating'],
    ['work_order_status_progress', 'order_received', 'order_updates'],
    ['work_order_status_progress', 'order_status_updated', 'order_updates'],
    ['client', 'client_linked', 'clients'],
    ['measurement', 'measurement_updated', 'measurement_updates'],
    ['appointment', 'appointment_reminder', 'appointment_reminder'],
  ];

  it.each(cases)('%s / %s → %s', (type, event, expected) => {
    expect(preferenceKeyFor({ type, event })).toBe(expected);
  });

  it('separates likes from comments, which share a type', () => {
    expect(preferenceKeyFor({ type: 'trend', event: 'trend_liked' })).not.toBe(
      preferenceKeyFor({ type: 'trend', event: 'trend_commented' })
    );
  });

  it('separates reviews from likes, which shared the old social bucket', () => {
    expect(preferenceKeyFor({ type: 'trend', event: 'trend_liked' })).not.toBe(
      preferenceKeyFor({ type: 'review', event: 'review_received' })
    );
  });

  it('falls back to the type when the event is unknown', () => {
    expect(preferenceKeyFor({ type: 'appointment', event: 'something_new' })).toBe(
      'appointments'
    );
    expect(
      preferenceKeyFor({ type: 'work_order_status_progress', event: '' })
    ).toBe('order_updates');
  });

  it('falls back to appointments for an unrecognised payload', () => {
    expect(preferenceKeyFor({ type: 'info', event: '' })).toBe('appointments');
  });
});

describe('isPreferenceEnabled', () => {
  it('honours an explicit false for the current key', () => {
    expect(isPreferenceEnabled({ trend_comment: false }, 'trend_comment')).toBe(
      false
    );
  });

  it('uses the legacy key when the current one is absent', () => {
    const legacy = { social: false, orders: false, measurements: false, reminders: false };

    expect(isPreferenceEnabled(legacy, 'trend_like')).toBe(false);
    expect(isPreferenceEnabled(legacy, 'trend_comment')).toBe(false);
    expect(isPreferenceEnabled(legacy, 'designer_rating')).toBe(false);
    expect(isPreferenceEnabled(legacy, 'order_updates')).toBe(false);
    expect(isPreferenceEnabled(legacy, 'measurement_updates')).toBe(false);
    expect(isPreferenceEnabled(legacy, 'appointment_reminder')).toBe(false);
    // `social` never covered this one.
    expect(isPreferenceEnabled(legacy, 'appointments')).toBe(true);
  });

  it('prefers the current key over the legacy one', () => {
    expect(isPreferenceEnabled({ social: false, trend_like: true }, 'trend_like')).toBe(
      true
    );
    expect(isPreferenceEnabled({ social: true, trend_like: false }, 'trend_like')).toBe(
      false
    );
  });

  it('ignores non-boolean junk instead of truthy coercion', () => {
    expect(isPreferenceEnabled({ trend_like: 'false' }, 'trend_like')).toBe(true);
    expect(isPreferenceEnabled({ trend_like: 0 }, 'trend_like')).toBe(true);
  });
});

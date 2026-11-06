import {
  buildIdempotencyKey,
  isCategoryEnabled,
  isSelfNotification,
  mergePreferences,
  redactToken,
  statusChanged,
} from '../src/notifications/helpers';

describe('redactToken', () => {
  it('keeps only a short prefix and suffix', () => {
    const token = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const redacted = redactToken(token);
    expect(redacted).toContain('abcdef');
    expect(redacted).toContain('6789');
    expect(redacted).not.toContain('klmnopqrstuvwxyz');
  });

  it('handles empty tokens', () => {
    expect(redactToken('')).toBe('(empty)');
  });
});

describe('buildIdempotencyKey', () => {
  it('joins non-empty parts with a separator', () => {
    expect(buildIdempotencyKey(['booking', 'confirmed', 'b1'])).toBe(
      'booking__confirmed__b1'
    );
  });

  it('drops empty parts and sanitises separators', () => {
    expect(buildIdempotencyKey(['booking', '', undefined, 'a/b'])).toBe(
      'booking__a_b'
    );
  });

  it('is stable for the same inputs', () => {
    const a = buildIdempotencyKey(['order', 'completed', 'x']);
    const b = buildIdempotencyKey(['order', 'completed', 'x']);
    expect(a).toBe(b);
  });

  it('differs across statuses', () => {
    expect(buildIdempotencyKey(['booking', 'confirmed', 'b1'])).not.toBe(
      buildIdempotencyKey(['booking', 'declined', 'b1'])
    );
  });
});

describe('statusChanged', () => {
  it('is true only when the status actually moves', () => {
    expect(statusChanged({ status: 'pending' }, { status: 'confirmed' })).toBe(
      true
    );
    expect(statusChanged({ status: 'pending' }, { status: 'pending' })).toBe(
      false
    );
  });

  it('is false for a deleted document', () => {
    expect(statusChanged({ status: 'pending' }, undefined)).toBe(false);
  });
});

describe('isSelfNotification', () => {
  it('prevents notifying the actor', () => {
    expect(isSelfNotification('user_1', 'user_1')).toBe(true);
    expect(isSelfNotification('user_1', 'user_2')).toBe(false);
    expect(isSelfNotification(undefined, 'user_2')).toBe(false);
  });
});

describe('preferences', () => {
  it('defaults every category to enabled', () => {
    expect(isCategoryEnabled(undefined, 'appointments')).toBe(true);
    expect(isCategoryEnabled({}, 'orders')).toBe(true);
  });

  it('respects an explicit false', () => {
    expect(isCategoryEnabled({ appointments: false }, 'appointments')).toBe(
      false
    );
  });

  it('fills missing keys with defaults', () => {
    expect(mergePreferences({ orders: false })).toEqual({
      appointments: true,
      orders: false,
      measurements: true,
      reminders: true,
      social: true,
      clients: true,
    });
  });
});

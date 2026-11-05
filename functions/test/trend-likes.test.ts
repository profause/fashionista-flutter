import { buildTrendLikeNotification } from '../src/triggers/trend-like.triggers';

const input = {
  trendId: 'trend_1',
  likerId: 'liker_1',
  likerName: 'Ama',
  authorId: 'author_1',
};

describe('buildTrendLikeNotification', () => {
  it('notifies the author with the liker name', () => {
    const payload = buildTrendLikeNotification(input);

    expect(payload).not.toBeNull();
    expect(payload?.recipientUserId).toBe('author_1');
    expect(payload?.title).toBe('New like on your trend');
    expect(payload?.body).toBe('Ama liked your trend.');
    expect(payload?.type).toBe('trend');
    expect(payload?.event).toBe('trend_liked');
    expect(payload?.refId).toBe('trend_1');
    expect(payload?.refType).toBe('trend');
    expect(payload?.audience).toBe('user');
  });

  it('falls back to an anonymous body when the name is unknown', () => {
    const payload = buildTrendLikeNotification({ ...input, likerName: '' });

    expect(payload?.body).toBe('Someone liked your trend.');
  });

  it('trims the liker name', () => {
    const payload = buildTrendLikeNotification({
      ...input,
      likerName: '  Ama  ',
    });

    expect(payload?.body).toBe('Ama liked your trend.');
  });

  it('never notifies the author for their own like', () => {
    expect(
      buildTrendLikeNotification({ ...input, likerId: 'author_1' })
    ).toBeNull();
  });

  it('returns null when the trend has no author', () => {
    expect(buildTrendLikeNotification({ ...input, authorId: '' })).toBeNull();
  });

  it('returns null when the trend id is missing', () => {
    expect(buildTrendLikeNotification({ ...input, trendId: '' })).toBeNull();
  });

  it('keys the idempotency key on the trend and the liker', () => {
    const payload = buildTrendLikeNotification(input);

    expect(payload?.idempotencyKey).toBe('trend__liked__trend_1__liker_1');
  });

  it('produces the same key for the same trend and liker', () => {
    const first = buildTrendLikeNotification(input);
    const second = buildTrendLikeNotification({ ...input, likerName: 'Other' });

    expect(first?.idempotencyKey).toBe(second?.idempotencyKey);
  });

  it('produces a different key for a different liker', () => {
    const a = buildTrendLikeNotification(input);
    const b = buildTrendLikeNotification({ ...input, likerId: 'liker_2' });

    expect(a?.idempotencyKey).not.toBe(b?.idempotencyKey);
  });

  it('carries the liker id for diagnostics', () => {
    const payload = buildTrendLikeNotification(input);

    expect(payload?.data).toEqual({ user_id: 'liker_1' });
  });
});

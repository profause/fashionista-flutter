import { buildTrendCommentNotification } from '../src/triggers/trend-comment.triggers';

const input = {
  trendId: 'trend_1',
  commentId: 'comment_1',
  authorId: 'commenter_1',
  authorName: 'Ama',
  ownerId: 'author_1',
  commentText: 'This is stunning!',
};

describe('buildTrendCommentNotification', () => {
  it('notifies the trend owner with the comment', () => {
    const payload = buildTrendCommentNotification(input);

    expect(payload).not.toBeNull();
    expect(payload?.recipientUserId).toBe('author_1');
    expect(payload?.title).toBe('New comment on your trend');
    expect(payload?.body).toBe('Ama commented: "This is stunning!"');
    expect(payload?.type).toBe('trend');
    expect(payload?.event).toBe('trend_commented');
    expect(payload?.refId).toBe('trend_1');
    expect(payload?.refType).toBe('trend');
    expect(payload?.audience).toBe('user');
  });

  it('falls back to an anonymous body when the name is unknown', () => {
    const payload = buildTrendCommentNotification({ ...input, authorName: '' });

    expect(payload?.body).toBe('Someone commented: "This is stunning!"');
  });

  it('handles an empty comment body', () => {
    const payload = buildTrendCommentNotification({
      ...input,
      commentText: '   ',
    });

    expect(payload?.body).toBe('Ama commented on your trend.');
  });

  it('collapses multi-line comments', () => {
    const payload = buildTrendCommentNotification({
      ...input,
      commentText: 'Love  this\n\nso much',
    });

    expect(payload?.body).toBe('Ama commented: "Love this so much"');
  });

  it('truncates a long comment on a word boundary', () => {
    const payload = buildTrendCommentNotification({
      ...input,
      commentText: 'word '.repeat(40),
    });

    expect(payload?.body).toContain('…');
    expect(payload?.body.length).toBeLessThan(120);
  });

  it('never notifies the owner for their own comment', () => {
    expect(
      buildTrendCommentNotification({ ...input, authorId: 'author_1' })
    ).toBeNull();
  });

  it('returns null when an id is missing', () => {
    expect(
      buildTrendCommentNotification({ ...input, trendId: '' })
    ).toBeNull();
    expect(
      buildTrendCommentNotification({ ...input, commentId: '' })
    ).toBeNull();
    expect(
      buildTrendCommentNotification({ ...input, ownerId: '' })
    ).toBeNull();
  });

  it('keys the idempotency key on the comment document', () => {
    const payload = buildTrendCommentNotification(input);

    expect(payload?.idempotencyKey).toBe(
      'trend__commented__trend_1__comment_1'
    );
  });

  it('gives a different key for a different comment', () => {
    const a = buildTrendCommentNotification(input);
    const b = buildTrendCommentNotification({ ...input, commentId: 'comment_2' });

    expect(a?.idempotencyKey).not.toBe(b?.idempotencyKey);
  });

  it('carries the commenter and comment for diagnostics', () => {
    const payload = buildTrendCommentNotification(input);

    expect(payload?.data).toEqual({
      user_id: 'commenter_1',
      comment_id: 'comment_1',
    });
  });
});

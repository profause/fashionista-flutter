import { buildDesignerReviewNotification } from '../src/triggers/review.triggers';

const input = {
  reviewId: 'review_1',
  designerId: 'designer_1',
  authorId: 'client_1',
  authorName: 'Ama',
  rating: 5,
  commentText: 'Beautiful work, the fit was perfect.',
};

describe('buildDesignerReviewNotification', () => {
  it('notifies the designer with the rating and the comment', () => {
    const payload = buildDesignerReviewNotification(input);

    expect(payload).not.toBeNull();
    expect(payload?.recipientUserId).toBe('designer_1');
    expect(payload?.title).toBe('New review');
    expect(payload?.body).toBe(
      'Ama rated you 5 stars: "Beautiful work, the fit was perfect."'
    );
    expect(payload?.type).toBe('review');
    expect(payload?.event).toBe('review_received');
    expect(payload?.refId).toBe('review_1');
    expect(payload?.refType).toBe('designer_review');
    expect(payload?.designerId).toBe('designer_1');
    expect(payload?.audience).toBe('designer');
  });

  it('uses the singular for a one-star review', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: 1,
      commentText: '',
    });

    expect(payload?.body).toBe('Ama rated you 1 star.');
  });

  it('handles a rating without a comment', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: 4,
      commentText: '   ',
    });

    expect(payload?.body).toBe('Ama rated you 4 stars.');
  });

  it('handles a comment without a rating', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: 0, // the Dart model default when no stars were picked
      commentText: 'Lovely experience overall.',
    });

    expect(payload?.body).toBe(
      'Ama left a review: "Lovely experience overall."'
    );
  });

  it('handles a review with neither text nor rating', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: undefined,
      commentText: '',
    });

    expect(payload?.body).toBe('Ama reviewed your profile.');
  });

  it('accepts the rating as a numeric string', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: '3',
      commentText: '',
    });

    expect(payload?.body).toBe('Ama rated you 3 stars.');
  });

  it('rejects an out-of-range rating instead of inventing stars', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: 9,
      commentText: 'nice',
    });

    expect(payload?.body).toBe('Ama left a review: "nice"');
  });

  it('collapses whitespace in the comment', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: undefined,
      commentText: 'Great   fit,\n\nthank you!',
    });

    expect(payload?.body).toBe('Ama left a review: "Great fit, thank you!"');
  });

  it('truncates a long comment on a word boundary', () => {
    const comment = `${'word '.repeat(30)}end`;
    const payload = buildDesignerReviewNotification({
      ...input,
      rating: undefined,
      commentText: comment,
    });

    expect(payload?.body).toContain('…');
    expect(payload?.body.length).toBeLessThan(120);
    expect(payload?.body).not.toContain('  ');
  });

  it('falls back to a neutral author when the name is missing', () => {
    const payload = buildDesignerReviewNotification({
      ...input,
      authorName: '   ',
    });

    expect(payload?.body.startsWith('A client rated you')).toBe(true);
  });

  it('never notifies a designer about their own review', () => {
    expect(
      buildDesignerReviewNotification({ ...input, authorId: 'designer_1' })
    ).toBeNull();
  });

  it('returns null without a designer or review id', () => {
    expect(
      buildDesignerReviewNotification({ ...input, designerId: '' })
    ).toBeNull();
    expect(
      buildDesignerReviewNotification({ ...input, reviewId: '' })
    ).toBeNull();
  });

  it('keys the idempotency key on the review document', () => {
    const payload = buildDesignerReviewNotification(input);

    expect(payload?.idempotencyKey).toBe('designer__review__review_1');
  });
});

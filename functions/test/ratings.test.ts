import { RatingStore } from '../src/ratings/repository';
import {
  RatingSummary,
  affectedDesignerIds,
  designerIdOf,
  normalizeRating,
  ratingSummaryChanged,
  summarize,
} from '../src/ratings/summary';
import {
  RatingLogger,
  applyReviewChange,
  recomputeDesignerRating,
} from '../src/ratings/service';

function silentLogger(): RatingLogger {
  return { info: () => {}, warn: () => {}, error: () => {} };
}

/** In-memory store; records every write so idempotency can be asserted. */
class FakeStore implements RatingStore {
  readonly writes: Array<{ designerId: string; summary: RatingSummary }> = [];

  constructor(
    private readonly reviewsByDesigner: Record<string, unknown[]>,
    private readonly existingDesigners: string[] = Object.keys(reviewsByDesigner)
  ) {}

  async listRatings(designerId: string): Promise<unknown[]> {
    return this.reviewsByDesigner[designerId] ?? [];
  }

  async writeSummary(
    designerId: string,
    summary: RatingSummary
  ): Promise<boolean> {
    if (!this.existingDesigners.includes(designerId)) return false;
    this.writes.push({ designerId, summary });
    return true;
  }
}

describe('normalizeRating', () => {
  it('accepts whole stars as numbers and numeric strings', () => {
    expect(normalizeRating(5)).toBe(5);
    expect(normalizeRating(1)).toBe(1);
    expect(normalizeRating('4')).toBe(4);
    expect(normalizeRating(' 3 ')).toBe(3);
  });

  it('rejects values that are not a star', () => {
    for (const value of [0, 6, -1, 4.5, 'abc', '', null, undefined, {}, []]) {
      expect(normalizeRating(value)).toBeNull();
    }
  });
});

describe('summarize', () => {
  it('returns empty buckets when there are no reviews', () => {
    expect(summarize([])).toEqual({
      ratings: { '5': 0, '4': 0, '3': 0, '2': 0, '1': 0 },
      review_count: 0,
      total_rating: 0,
      average_rating: 0,
    });
  });

  it('builds the histogram, count and average', () => {
    const summary = summarize([5, 5, 4, 3]);

    expect(summary.ratings).toEqual({
      '5': 2,
      '4': 1,
      '3': 1,
      '2': 0,
      '1': 0,
    });
    expect(summary.review_count).toBe(4);
    expect(summary.total_rating).toBe(4);
    expect(summary.average_rating).toBe(4.3); // 17 / 4
  });

  it('rounds the average to one decimal', () => {
    expect(summarize([5, 4]).average_rating).toBe(4.5);
    expect(summarize([5, 5, 5]).average_rating).toBe(5);
    expect(summarize([1, 1, 2]).average_rating).toBe(1.3);
  });

  it('skips reviews without a valid rating', () => {
    const summary = summarize([5, 0, undefined, null, 7, 'bad']);

    expect(summary.review_count).toBe(1);
    expect(summary.total_rating).toBe(1);
    expect(summary.average_rating).toBe(5);
    expect(summary.ratings['5']).toBe(1);
  });

  it('is deterministic for identical input', () => {
    const values = [5, 4, 4, 2];
    expect(summarize(values)).toEqual(summarize([...values]));
  });
});

describe('designerIdOf', () => {
  it('reads and trims ref_id', () => {
    expect(designerIdOf({ ref_id: ' d1 ' })).toBe('d1');
    expect(designerIdOf({ ref_id: 42 })).toBe('');
    expect(designerIdOf(undefined)).toBe('');
  });
});

describe('ratingSummaryChanged', () => {
  it('always recomputes on create and delete', () => {
    expect(ratingSummaryChanged(undefined, { rating: 5 })).toBe(true);
    expect(ratingSummaryChanged({ rating: 5 }, undefined)).toBe(true);
  });

  it('ignores edits that do not touch the rating or the designer', () => {
    expect(
      ratingSummaryChanged(
        { rating: 4, ref_id: 'd1', comment: { text: 'a' } },
        { rating: 4, ref_id: 'd1', comment: { text: 'b' } }
      )
    ).toBe(false);
  });

  it('detects a rating change and a re-point', () => {
    expect(ratingSummaryChanged({ rating: 3 }, { rating: 5 })).toBe(true);
    expect(
      ratingSummaryChanged({ rating: 5, ref_id: 'd1' }, { rating: 5, ref_id: 'd2' })
    ).toBe(true);
  });
});

describe('affectedDesignerIds', () => {
  it('returns the single designer of a create or delete', () => {
    expect(affectedDesignerIds(undefined, { ref_id: 'd1' })).toEqual(['d1']);
    expect(affectedDesignerIds({ ref_id: 'd1' }, undefined)).toEqual(['d1']);
  });

  it('returns both designers when a review is re-pointed', () => {
    expect(
      affectedDesignerIds({ ref_id: 'd1' }, { ref_id: 'd2' }).sort()
    ).toEqual(['d1', 'd2']);
  });

  it('deduplicates and skips missing ids', () => {
    expect(affectedDesignerIds({ ref_id: 'd1' }, { ref_id: 'd1' })).toEqual([
      'd1',
    ]);
    expect(affectedDesignerIds(undefined, { rating: 5 })).toEqual([]);
  });
});

describe('recomputeDesignerRating', () => {
  it('writes a summary derived from the stored reviews', async () => {
    const store = new FakeStore({ d1: [5, 5, 3] });
    const summary = await recomputeDesignerRating(store, 'd1');

    expect(summary?.average_rating).toBe(4.3);
    expect(summary?.review_count).toBe(3);
    expect(store.writes).toHaveLength(1);
  });

  it('produces the same summary when run twice', async () => {
    const store = new FakeStore({ d1: [5, 4] });

    await recomputeDesignerRating(store, 'd1');
    await recomputeDesignerRating(store, 'd1');

    expect(store.writes[0].summary).toEqual(store.writes[1].summary);
  });

  it('returns null when the designer was deleted', async () => {
    const store = new FakeStore({ d1: [5] }, []);

    expect(await recomputeDesignerRating(store, 'd1')).toBeNull();
    expect(store.writes).toHaveLength(0);
  });

  it('does nothing without an id', async () => {
    const store = new FakeStore({});

    expect(await recomputeDesignerRating(store, '')).toBeNull();
    expect(store.writes).toHaveLength(0);
  });
});

describe('applyReviewChange', () => {
  it('recomputes on create', async () => {
    const store = new FakeStore({ d1: [5] });
    const updates = await applyReviewChange(
      store,
      undefined,
      { ref_id: 'd1', rating: 5 },
      silentLogger()
    );

    expect(updates.map((u) => u.designerId)).toEqual(['d1']);
    expect(updates[0].summary.average_rating).toBe(5);
  });

  it('recomputes on delete', async () => {
    const store = new FakeStore({ d1: [] });
    const updates = await applyReviewChange(
      store,
      { ref_id: 'd1', rating: 5 },
      undefined,
      silentLogger()
    );

    expect(updates[0].summary.review_count).toBe(0);
    expect(updates[0].summary.average_rating).toBe(0);
  });

  it('updates both designers when a review is re-pointed', async () => {
    const store = new FakeStore({ d1: [], d2: [4] });
    const updates = await applyReviewChange(
      store,
      { ref_id: 'd1', rating: 5 },
      { ref_id: 'd2', rating: 5 },
      silentLogger()
    );

    expect(updates.map((u) => u.designerId).sort()).toEqual(['d1', 'd2']);
    expect(store.writes.map((w) => w.designerId).sort()).toEqual(['d1', 'd2']);
  });

  it('skips a comment-only edit', async () => {
    const store = new FakeStore({ d1: [5] });
    const updates = await applyReviewChange(
      store,
      { ref_id: 'd1', rating: 5, comment: 'old' },
      { ref_id: 'd1', rating: 5, comment: 'new' },
      silentLogger()
    );

    expect(updates).toEqual([]);
    expect(store.writes).toHaveLength(0);
  });

  it('skips a review with no ref_id', async () => {
    const store = new FakeStore({});
    const updates = await applyReviewChange(
      store,
      undefined,
      { rating: 4 },
      silentLogger()
    );

    expect(updates).toEqual([]);
    expect(store.writes).toHaveLength(0);
  });

  it('reports a missing designer without failing the invocation', async () => {
    const store = new FakeStore({ d1: [5] }, []);
    const updates = await applyReviewChange(
      store,
      undefined,
      { ref_id: 'd1', rating: 5 },
      silentLogger()
    );

    expect(updates).toEqual([]);
  });

  it('propagates a storage failure so it surfaces in logs', async () => {
    const store: RatingStore = {
      listRatings: async () => {
        throw new Error('firestore unavailable');
      },
      writeSummary: async () => true,
    };

    await expect(
      applyReviewChange(
        store,
        undefined,
        { ref_id: 'd1', rating: 5 },
        silentLogger()
      )
    ).rejects.toThrow('firestore unavailable');
  });
});

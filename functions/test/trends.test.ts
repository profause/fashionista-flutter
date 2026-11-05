import {
  countTags,
  diffTags,
  normalizeTags,
  tallyTagDeltas,
} from '../src/trends/tags';
import {
  InterestCounterStore,
  InterestDelta,
  NUMBER_OF_POSTS_FIELD,
  syncFashionInterestPostCounts,
} from '../src/trends/interest-counts';
import {
  CounterUpdate,
  InterestCounterSnapshot,
  ReconcileStore,
  rebuildFashionInterestPostCounts,
} from '../src/trends/reconcile';

/**
 * In-memory counter store.
 *
 * `interests` maps an interest `name` to its document id, mirroring the
 * `where('name', '==', tag).limit(1)` lookup the repository performs.
 */
class FakeCounterStore implements InterestCounterStore {
  readonly deltas: InterestDelta[] = [];
  readonly lookups: string[] = [];

  constructor(
    private readonly interests: Record<string, string>,
    private readonly apply: (
      deltas: InterestDelta[]
    ) => Promise<void> = async () => {}
  ) {}

  async findInterestIdByName(name: string): Promise<string | null> {
    this.lookups.push(name);
    return this.interests[name] ?? null;
  }

  async applyCountDeltas(deltas: InterestDelta[]): Promise<void> {
    await this.apply(deltas);
    this.deltas.push(...deltas);
  }
}

class FakeReconcileStore implements ReconcileStore {
  written: CounterUpdate[] = [];

  constructor(
    private readonly tags: unknown[],
    private readonly interests: InterestCounterSnapshot[]
  ) {}

  async scanTrendTags() {
    return { tagCounts: countTags(this.tags), trendsProcessed: this.tags.length };
  }

  async listInterestCounters(): Promise<InterestCounterSnapshot[]> {
    return this.interests;
  }

  async writeCounters(updates: CounterUpdate[]): Promise<number> {
    this.written = updates;
    return updates.length;
  }
}

describe('normalizeTags', () => {
  it('splits the comma-separated string the app stores', () => {
    expect(normalizeTags('Ankara,Wedding')).toEqual(['Ankara', 'Wedding']);
  });

  it('accepts an array of strings', () => {
    expect(normalizeTags(['Ankara', 'Wedding'])).toEqual(['Ankara', 'Wedding']);
  });

  it('trims, drops blanks and removes duplicates preserving order', () => {
    expect(normalizeTags(' Ankara , ,Ankara,  Wedding ,')).toEqual([
      'Ankara',
      'Wedding',
    ]);
  });

  it('ignores non-string entries inside an array', () => {
    expect(normalizeTags(['Kente', 42, null, undefined, {}])).toEqual(['Kente']);
  });

  it('returns an empty list for unsupported input', () => {
    for (const value of [undefined, null, 7, {}, true]) {
      expect(normalizeTags(value)).toEqual([]);
    }
  });
});

describe('diffTags', () => {
  it('reports added and removed tags', () => {
    expect(diffTags(['Ankara', 'Wedding'], ['Ankara', 'Kente'])).toEqual({
      added: ['Kente'],
      removed: ['Wedding'],
    });
  });

  it('reports nothing when the sets match in a different order', () => {
    expect(diffTags(['Ankara', 'Kente'], ['Kente', 'Ankara'])).toEqual({
      added: [],
      removed: [],
    });
  });
});

describe('tallyTagDeltas', () => {
  it('maps additions to +1 and removals to -1', () => {
    const deltas = tallyTagDeltas(['Kente'], ['Wedding']);

    expect(deltas.get('Kente')).toBe(1);
    expect(deltas.get('Wedding')).toBe(-1);
  });

  it('is empty when nothing moved', () => {
    expect(tallyTagDeltas([], []).size).toBe(0);
  });
});

describe('countTags', () => {
  it('counts each trend once per distinct tag', () => {
    const counts = countTags([
      'Ankara,Wedding',
      'Ankara, Ankara',
      ['Kente'],
      undefined,
    ]);

    expect(counts.get('Ankara')).toBe(2);
    expect(counts.get('Wedding')).toBe(1);
    expect(counts.get('Kente')).toBe(1);
  });
});

describe('syncFashionInterestPostCounts', () => {
  const interests = { Ankara: 'i-ankara', Wedding: 'i-wedding', Kente: 'i-kente' };

  it('increments the interests of newly added tags', async () => {
    const store = new FakeCounterStore(interests);

    const result = await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'Ankara' },
      { tags: 'Ankara,Wedding' }
    );

    expect(result.addedTags).toEqual(['Wedding']);
    expect(result.removedTags).toEqual([]);
    expect(result.committed).toBe(true);
    expect(store.deltas).toEqual([{ interestId: 'i-wedding', delta: 1 }]);
  });

  it('decrements the interests of removed tags', async () => {
    const store = new FakeCounterStore(interests);

    await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'Ankara,Wedding' },
      { tags: 'Ankara' }
    );

    expect(store.deltas).toEqual([{ interestId: 'i-wedding', delta: -1 }]);
  });

  it('treats a created trend as all tags added', async () => {
    const store = new FakeCounterStore(interests);

    await syncFashionInterestPostCounts(store, 't1', undefined, {
      tags: 'Ankara,Kente',
    });

    expect(store.deltas).toEqual([
      { interestId: 'i-ankara', delta: 1 },
      { interestId: 'i-kente', delta: 1 },
    ]);
  });

  it('treats a deleted trend as all tags removed', async () => {
    const store = new FakeCounterStore(interests);

    await syncFashionInterestPostCounts(store, 't1', { tags: 'Ankara' }, undefined);

    expect(store.deltas).toEqual([{ interestId: 'i-ankara', delta: -1 }]);
  });

  it('writes nothing when the tags are unchanged', async () => {
    const store = new FakeCounterStore(interests);

    const result = await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'Ankara, Wedding', caption: 'old' },
      { tags: 'Wedding,Ankara', caption: 'new' }
    );

    expect(result.committed).toBe(false);
    expect(store.deltas).toEqual([]);
    expect(store.lookups).toEqual([]);
  });

  it('writes nothing when only the tag order changes', async () => {
    const store = new FakeCounterStore(interests);

    await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'Ankara,Wedding' },
      { tags: 'Wedding,Ankara' }
    );

    expect(store.deltas).toEqual([]);
  });

  it('reports tags with no matching interest instead of creating one', async () => {
    const store = new FakeCounterStore(interests);

    const result = await syncFashionInterestPostCounts(
      store,
      't1',
      undefined,
      { tags: 'Ankara,Typo' }
    );

    expect(result.missingInterests).toEqual(['Typo']);
    expect(result.updatedInterestIds).toEqual(['i-ankara']);
    expect(store.deltas).toEqual([{ interestId: 'i-ankara', delta: 1 }]);
  });

  it('looks up each affected tag once', async () => {
    const store = new FakeCounterStore(interests);

    await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'Wedding' },
      { tags: 'Ankara,Kente' }
    );

    expect(store.lookups.sort()).toEqual(['Ankara', 'Kente', 'Wedding']);
  });

  it('applies one delta per interest when two tags resolve to it', async () => {
    const store = new FakeCounterStore({
      Ankara: 'i-shared',
      ' ankara': 'i-shared',
    });

    // Two distinct normalized tags mapped to the same document.
    const result = await syncFashionInterestPostCounts(
      store,
      't1',
      undefined,
      { tags: 'Ankara,ankara' }
    );

    expect(result.updatedInterestIds).toEqual(['i-shared']);
    expect(store.deltas).toEqual([{ interestId: 'i-shared', delta: 1 }]);
  });

  it('leaves the counter untouched when an added and a removed tag share an interest', async () => {
    const store = new FakeCounterStore({ A: 'i-shared', B: 'i-shared' });

    const result = await syncFashionInterestPostCounts(
      store,
      't1',
      { tags: 'A' },
      { tags: 'B' }
    );

    expect(store.deltas).toEqual([]);
    expect(result.committed).toBe(false);
  });

  it('does not mark the batch committed when the store throws', async () => {
    const store = new FakeCounterStore(interests, async () => {
      throw new Error('batch failed');
    });

    await expect(
      syncFashionInterestPostCounts(store, 't1', undefined, { tags: 'Ankara' })
    ).rejects.toThrow('batch failed');
  });
});

describe('NUMBER_OF_POSTS_FIELD', () => {
  it('matches the snake_case key the Flutter model reads first', () => {
    expect(NUMBER_OF_POSTS_FIELD).toBe('number_of_posts');
  });
});

describe('rebuildFashionInterestPostCounts', () => {
  it('rewrites only the stale counters', async () => {
    const store = new FakeReconcileStore(
      ['Ankara,Wedding', 'Ankara', 'Kente'],
      [
        { id: 'i-ankara', name: 'Ankara', currentCount: 2 },
        { id: 'i-wedding', name: 'Wedding', currentCount: 0 }, // stale
        { id: 'i-kente', name: 'Kente', currentCount: 99 }, // stale
        { id: 'i-lace', name: 'Lace', currentCount: 0 }, // correct
      ]
    );

    const result = await rebuildFashionInterestPostCounts(store);

    expect(result).toEqual({
      trendsProcessed: 3,
      interestsProcessed: 4,
      countersUpdated: 2,
    });
    expect(store.written).toEqual([
      { id: 'i-wedding', value: 1 },
      { id: 'i-kente', value: 1 },
    ]);
  });

  it('resets interests no trend references', async () => {
    const store = new FakeReconcileStore(
      ['Ankara'],
      [{ id: 'i-lace', name: 'Lace', currentCount: 7 }]
    );

    await rebuildFashionInterestPostCounts(store);

    expect(store.written).toEqual([{ id: 'i-lace', value: 0 }]);
  });

  it('creates the counter when it is absent', async () => {
    const store = new FakeReconcileStore(
      ['Ankara'],
      [{ id: 'i-ankara', name: 'Ankara', currentCount: null }]
    );

    await rebuildFashionInterestPostCounts(store);

    expect(store.written).toEqual([{ id: 'i-ankara', value: 1 }]);
  });

  it('writes nothing when every counter is already correct', async () => {
    const store = new FakeReconcileStore(
      ['Ankara'],
      [{ id: 'i-ankara', name: 'Ankara', currentCount: 1 }]
    );

    const result = await rebuildFashionInterestPostCounts(store);

    expect(result.countersUpdated).toBe(0);
    expect(store.written).toEqual([]);
  });

  it('handles an empty catalogue', async () => {
    const store = new FakeReconcileStore([], []);

    expect(await rebuildFashionInterestPostCounts(store)).toEqual({
      trendsProcessed: 0,
      interestsProcessed: 0,
      countersUpdated: 0,
    });
  });
});

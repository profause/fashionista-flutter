import type { CallableRequest } from 'firebase-functions/v2/https';

import {
  ACCOUNT_DELETION_MANIFEST,
  DELETION_STEP_IDS,
  USER_DATA_COLLECTIONS,
} from '../src/account/deletion-manifest';
import {
  AccountDeletionBusyError,
  AccountDeletionService,
  DeletionJob,
  DeletionLogger,
  DeletionStore,
  JobClaim,
} from '../src/account/deletion-service';
import { handleDeleteMyAccount } from '../src/account/delete-account';
import {
  dedupeMedia,
  mediaAssetsFromFeatured,
  parseCloudinaryUrl,
} from '../src/account/media';
import type { MediaAsset } from '../src/account/media';

const silentLogger: DeletionLogger = { error: () => undefined };

class FakeStore implements DeletionStore {
  job: DeletionJob | null = null;
  calls: string[] = [];
  media: MediaAsset[] = [
    { publicId: 'fashionista/profile_images/u1', resourceType: 'image' },
  ];
  failedMedia: string[] = [];
  failAt: string | null = null;
  claimBusy = false;

  async getJob(_uid: string): Promise<DeletionJob | null> {
    return this.job ? cloneJob(this.job) : null;
  }

  async acquireJob(
    job: DeletionJob,
    staleBefore: Date
  ): Promise<JobClaim> {
    this.calls.push('acquireJob');
    if (this.claimBusy) return { result: 'busy' };
    if (this.job) {
      if (this.job.status === 'completed') {
        return { result: 'completed', job: cloneJob(this.job) };
      }
      if (
        this.job.status === 'in_progress' &&
        this.job.updated_at.getTime() > staleBefore.getTime()
      ) {
        return { result: 'busy' };
      }
    }
    this.job = cloneJob(job);
    return { result: 'claimed' };
  }

  async saveJob(job: DeletionJob): Promise<void> {
    this.calls.push('saveJob');
    if (this.failAt === 'saveJob') throw new Error('save failed');
    this.job = cloneJob(job);
  }

  async revokeRefreshTokens(): Promise<void> {
    this.calls.push('revokeRefreshTokens');
  }

  async collectMedia(): Promise<MediaAsset[]> {
    this.calls.push('collectMedia');
    return this.media;
  }

  async deleteInteractions(): Promise<number> {
    this.calls.push('deleteInteractions');
    return 2;
  }

  async deleteAuthoredTrends(): Promise<number> {
    this.calls.push('deleteAuthoredTrends');
    return 1;
  }

  async deleteDesignerContent(): Promise<number> {
    this.calls.push('deleteDesignerContent');
    return 1;
  }

  async deleteCommerce(): Promise<number> {
    this.calls.push('deleteCommerce');
    return 1;
  }

  async deleteClientRecords(): Promise<number> {
    this.calls.push('deleteClientRecords');
    return 1;
  }

  async deleteUserDocuments(): Promise<number> {
    this.calls.push('deleteUserDocuments');
    return 2;
  }

  async destroyMedia(): Promise<string[]> {
    this.calls.push('destroyMedia');
    return this.failedMedia;
  }

  async deleteLegacyStorage(): Promise<number> {
    this.calls.push('deleteLegacyStorage');
    return 0;
  }

  async deleteAuthUser(): Promise<void> {
    this.calls.push('deleteAuthUser');
    if (this.failAt === 'deleteAuthUser') throw new Error('auth delete failed');
  }
}

function cloneJob(job: DeletionJob): DeletionJob {
  return {
    ...job,
    completed_steps: [...job.completed_steps],
    media: job.media.map((asset) => ({ ...asset })),
    counts: { ...job.counts },
  };
}

function request(data: unknown, uid?: string): CallableRequest {
  return {
    auth: uid
      ? {
          uid,
          token: {},
        }
      : undefined,
    data,
    rawRequest: {},
    acceptsStreaming: false,
  } as unknown as CallableRequest;
}

function completedJob(uid = 'u1'): DeletionJob {
  const now = new Date('2026-01-01T00:00:00Z');
  return {
    uid,
    status: 'completed',
    requested_at: now,
    started_at: now,
    updated_at: now,
    completed_at: now,
    completed_steps: [...DELETION_STEP_IDS],
    media: [],
    counts: {},
    last_error: null,
  };
}

describe('account deletion manifest', () => {
  it('covers every user-owned collection', () => {
    const covered = new Set(
      ACCOUNT_DELETION_MANIFEST.flatMap((entry) => entry.collections)
    );

    for (const collection of USER_DATA_COLLECTIONS) {
      expect(covered.has(collection)).toBe(true);
    }
  });

  it('has a manifest entry for every executable step', () => {
    const steps = new Set(
      ACCOUNT_DELETION_MANIFEST.map((entry) => entry.step)
    );
    for (const step of DELETION_STEP_IDS) {
      expect(steps.has(step)).toBe(true);
    }
  });
});

describe('Cloudinary media helpers', () => {
  it('parses transformed image URLs', () => {
    expect(
      parseCloudinaryUrl(
        'https://res.cloudinary.com/cloud/image/upload/c_fill,w_480/v123/fashionista/profile_images/u1.jpg'
      )
    ).toEqual({
      publicId: 'fashionista/profile_images/u1',
      resourceType: 'image',
    });
  });

  it('parses video URLs and strips the poster extension', () => {
    expect(
      parseCloudinaryUrl(
        'https://res.cloudinary.com/cloud/video/upload/so_0,w_720,q_auto/v123/fashionista/trends/videos/u1/clip.mp4'
      )
    ).toEqual({
      publicId: 'fashionista/trends/videos/u1/clip',
      resourceType: 'video',
    });
  });

  it('ignores non-Cloudinary and malformed URLs', () => {
    expect(parseCloudinaryUrl('https://example.com/a.jpg')).toBeNull();
    expect(parseCloudinaryUrl('not a url')).toBeNull();
    expect(parseCloudinaryUrl('')).toBeNull();
  });

  it('reads public ids from featured media and strings', () => {
    expect(
      mediaAssetsFromFeatured([
        {
          uid: 'fashionista/trends/t1_0',
          url: 'https://res.cloudinary.com/cloud/image/upload/x.jpg',
          type: 'image',
        },
        { uid: 'fashionista/trends/videos/u1/clip', type: 'video' },
        'https://res.cloudinary.com/cloud/image/upload/v1/fashionista/designs/c1_0.jpg',
      ])
    ).toEqual([
      {
        publicId: 'fashionista/trends/t1_0',
        resourceType: 'image',
      },
      {
        publicId: 'fashionista/trends/videos/u1/clip',
        resourceType: 'video',
      },
      {
        publicId: 'fashionista/designs/c1_0',
        resourceType: 'image',
      },
    ]);
  });

  it('de-duplicates by resource type and public id', () => {
    expect(
      dedupeMedia([
        { publicId: 'a', resourceType: 'image' },
        { publicId: 'a', resourceType: 'image' },
        { publicId: 'a', resourceType: 'video' },
      ])
    ).toHaveLength(2);
  });
});

describe('AccountDeletionService', () => {
  it('runs the cascade in order and deletes auth last', async () => {
    const store = new FakeStore();
    const service = new AccountDeletionService(store, silentLogger, () =>
      new Date('2026-01-01T00:00:00Z')
    );

    const result = await service.delete('u1');

    expect(result).toEqual({
      status: 'completed',
      alreadyCompleted: false,
      completedSteps: DELETION_STEP_IDS.length,
    });
    expect(store.calls).toEqual([
      'acquireJob',
      'revokeRefreshTokens',
      'collectMedia',
      'saveJob',
      'deleteInteractions',
      'saveJob',
      'deleteAuthoredTrends',
      'saveJob',
      'deleteDesignerContent',
      'saveJob',
      'deleteCommerce',
      'saveJob',
      'deleteClientRecords',
      'saveJob',
      'deleteUserDocuments',
      'saveJob',
      'destroyMedia',
      'saveJob',
      'deleteLegacyStorage',
      'saveJob',
      'deleteAuthUser',
      'saveJob',
    ]);
    expect(store.job?.status).toBe('completed');
    expect(store.job?.counts).toMatchObject({
      interactions: 2,
      trends: 1,
      designer_content: 1,
      commerce: 1,
      client_records: 1,
      user_documents: 2,
    });
  });

  it('returns success for an already completed job', async () => {
    const store = new FakeStore();
    store.job = completedJob();

    const service = new AccountDeletionService(store, silentLogger);
    const result = await service.delete('u1');

    expect(result.alreadyCompleted).toBe(true);
    expect(store.calls).toEqual([]);
  });

  it('rejects a concurrent deletion discovered by the atomic lock', async () => {
    const store = new FakeStore();
    store.claimBusy = true;

    const service = new AccountDeletionService(store, silentLogger);
    await expect(service.delete('u1')).rejects.toBeInstanceOf(
      AccountDeletionBusyError
    );
    expect(store.calls).toEqual(['acquireJob']);
  });

  it('rejects a concurrent, non-stale deletion', async () => {
    const store = new FakeStore();
    store.job = {
      ...completedJob(),
      status: 'in_progress',
      completed_at: null,
      updated_at: new Date(),
    };

    const service = new AccountDeletionService(store, silentLogger);
    await expect(service.delete('u1')).rejects.toBeInstanceOf(
      AccountDeletionBusyError
    );
    expect(store.calls).toEqual([]);
  });

  it('resumes a stale in-progress job', async () => {
    const store = new FakeStore();
    store.job = {
      ...completedJob(),
      status: 'in_progress',
      completed_at: null,
      completed_steps: ['media_scan', 'interactions'],
      updated_at: new Date('2026-01-01T00:00:00Z'),
    };

    const service = new AccountDeletionService(
      store,
      silentLogger,
      () => new Date('2026-01-01T01:00:00Z')
    );
    await service.delete('u1');

    expect(store.calls).not.toContain('collectMedia');
    expect(store.calls).not.toContain('deleteInteractions');
    expect(store.calls).toContain('deleteAuthUser');
    expect(store.job?.status).toBe('completed');
  });

  it('does not delete auth when media cleanup fails, then retries only media', async () => {
    const store = new FakeStore();
    store.failedMedia = ['image:fashionista/profile_images/u1'];

    const service = new AccountDeletionService(store, silentLogger, () =>
      new Date('2026-01-01T00:00:00Z')
    );

    await expect(service.delete('u1')).rejects.toThrow(
      '1 Cloudinary asset(s) could not be deleted.'
    );
    expect(store.job?.status).toBe('failed');
    expect(store.calls).not.toContain('deleteAuthUser');
    expect(store.job?.completed_steps).toContain('user_documents');

    store.failedMedia = [];
    store.calls = [];
    await service.delete('u1');

    expect(store.calls).toContain('destroyMedia');
    expect(store.calls).toContain('deleteAuthUser');
    expect(store.calls).not.toContain('deleteInteractions');
    expect(store.calls).not.toContain('deleteUserDocuments');
    expect(store.job?.status).toBe('completed');
  });

  it('does not fail the request when auth is gone but completion save fails', async () => {
    const store = new FakeStore();
    const service = new AccountDeletionService(store, silentLogger, () =>
      new Date('2026-01-01T00:00:00Z')
    );

    const originalSave = store.saveJob.bind(store);
    let saves = 0;
    store.saveJob = async (job: DeletionJob) => {
      saves += 1;
      if (job.status === 'completed') throw new Error('write failed');
      await originalSave(job);
    };

    await expect(service.delete('u1')).resolves.toMatchObject({
      status: 'completed',
    });
    expect(saves).toBeGreaterThan(1);
    expect(store.calls).toContain('deleteAuthUser');
  });
});

describe('handleDeleteMyAccount', () => {
  it('rejects anonymous callers', async () => {
    await expect(
      handleDeleteMyAccount(request({ confirmation: 'DELETE' }))
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('rejects a missing or wrong confirmation', async () => {
    await expect(
      handleDeleteMyAccount(request({ confirmation: 'delete' }, 'u1'))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(
      handleDeleteMyAccount(request({}, 'u1'))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('uses the token uid and returns the service result', async () => {
    const store = new FakeStore();
    const result = await handleDeleteMyAccount(
      request({ confirmation: 'DELETE' }, 'u1'),
      {
        store,
        logger: silentLogger,
        now: () => new Date('2026-01-01T00:00:00Z'),
      }
    );

    expect(result.status).toBe('completed');
    expect(store.job?.uid).toBe('u1');
  });

  it('maps a concurrent deletion to failed-precondition', async () => {
    const store = new FakeStore();
    store.job = {
      ...completedJob(),
      status: 'in_progress',
      completed_at: null,
      updated_at: new Date(),
    };

    await expect(
      handleDeleteMyAccount(
        request({ confirmation: 'DELETE' }, 'u1'),
        { store, logger: silentLogger }
      )
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('maps internal failures to a generic error', async () => {
    const store = new FakeStore();
    store.failAt = 'deleteAuthUser';

    await expect(
      handleDeleteMyAccount(
        request({ confirmation: 'DELETE' }, 'u1'),
        { store, logger: silentLogger }
      )
    ).rejects.toMatchObject({ code: 'internal' });
  });
});

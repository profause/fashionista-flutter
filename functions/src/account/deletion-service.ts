import type { MediaAsset } from './media';
import {
  DELETION_STEP_IDS,
  type DeletionStepId,
} from './deletion-manifest';

export type DeletionJobStatus =
  | 'requested'
  | 'in_progress'
  | 'failed'
  | 'completed';

export interface DeletionJob {
  uid: string;
  status: DeletionJobStatus;
  requested_at: Date;
  started_at: Date | null;
  updated_at: Date;
  completed_at: Date | null;
  completed_steps: DeletionStepId[];
  media: MediaAsset[];
  counts: Record<string, number>;
  last_error: string | null;
}

export interface DeletionLogger {
  error: (message: string, ...args: unknown[]) => void;
}

export type JobClaim =
  | { result: 'claimed' }
  | { result: 'busy' }
  | { result: 'completed'; job: DeletionJob };

/** Small, testable port over Firestore/Auth/Storage/Cloudinary. */
export interface DeletionStore {
  getJob(uid: string): Promise<DeletionJob | null>;
  /** Atomically takes the deletion lock unless a live job already owns it. */
  acquireJob(job: DeletionJob, staleBefore: Date): Promise<JobClaim>;
  saveJob(job: DeletionJob): Promise<void>;

  revokeRefreshTokens(uid: string): Promise<void>;
  collectMedia(uid: string): Promise<MediaAsset[]>;

  deleteInteractions(uid: string): Promise<number>;
  deleteAuthoredTrends(uid: string): Promise<number>;
  deleteDesignerContent(uid: string): Promise<number>;
  deleteCommerce(uid: string): Promise<number>;
  deleteClientRecords(uid: string): Promise<number>;
  deleteUserDocuments(uid: string): Promise<number>;

  destroyMedia(media: MediaAsset[]): Promise<string[]>;
  deleteLegacyStorage(uid: string): Promise<number>;
  deleteAuthUser(uid: string): Promise<void>;
}

export interface AccountDeletionResult {
  status: 'completed';
  alreadyCompleted: boolean;
  completedSteps: number;
}

export class AccountDeletionBusyError extends Error {
  constructor() {
    super('Account deletion is already in progress.');
    this.name = 'AccountDeletionBusyError';
  }
}

const STALE_JOB_MS = 15 * 60 * 1000;

export class AccountDeletionService {
  private readonly now: () => Date;

  constructor(
    private readonly store: DeletionStore,
    private readonly logger: DeletionLogger,
    now: () => Date = () => new Date()
  ) {
    this.now = now;
  }

  async delete(uid: string): Promise<AccountDeletionResult> {
    const existing = await this.store.getJob(uid);
    if (existing?.status === 'completed') {
      return {
        status: 'completed',
        alreadyCompleted: true,
        completedSteps: existing.completed_steps.length,
      };
    }

    if (existing?.status === 'in_progress' && !this.isStale(existing)) {
      throw new AccountDeletionBusyError();
    }

    const now = this.now();
    const job: DeletionJob = {
      uid,
      status: 'in_progress',
      requested_at: existing?.requested_at ?? now,
      started_at: now,
      updated_at: now,
      completed_at: null,
      completed_steps: normalizeSteps(existing?.completed_steps),
      media: existing?.media ?? [],
      counts: existing?.counts ?? {},
      last_error: null,
    };

    // Take the lock atomically before any destructive work. A crashed
    // invocation leaves an `in_progress` job that a later retry can resume once
    // it is stale.
    const staleBefore = new Date(now.getTime() - STALE_JOB_MS);
    const claim = await this.store.acquireJob(job, staleBefore);
    if (claim.result === 'busy') throw new AccountDeletionBusyError();
    if (claim.result === 'completed') {
      return {
        status: 'completed',
        alreadyCompleted: true,
        completedSteps: claim.job.completed_steps.length,
      };
    }

    try {
      await this.store.revokeRefreshTokens(uid);

      await this.runStep(job, 'media_scan', async () => {
        job.media = await this.store.collectMedia(uid);
      });

      await this.runStep(job, 'interactions', async () => {
        job.counts.interactions = await this.store.deleteInteractions(uid);
      });

      await this.runStep(job, 'trends', async () => {
        job.counts.trends = await this.store.deleteAuthoredTrends(uid);
      });

      await this.runStep(job, 'designer_content', async () => {
        job.counts.designer_content = await this.store.deleteDesignerContent(
          uid
        );
      });

      await this.runStep(job, 'commerce', async () => {
        job.counts.commerce = await this.store.deleteCommerce(uid);
      });

      await this.runStep(job, 'client_records', async () => {
        job.counts.client_records = await this.store.deleteClientRecords(uid);
      });

      await this.runStep(job, 'user_documents', async () => {
        job.counts.user_documents = await this.store.deleteUserDocuments(uid);
      });

      await this.runStep(job, 'media', async () => {
        const failed = await this.store.destroyMedia(job.media);
        if (failed.length > 0) {
          throw new Error(
            `${failed.length} Cloudinary asset(s) could not be deleted.`
          );
        }
      });

      await this.runStep(job, 'legacy_storage', async () => {
        job.counts.legacy_storage = await this.store.deleteLegacyStorage(uid);
      });

      // Auth is deleted last. If saving the completed job fails afterwards, the
      // account is already gone, so do not turn that into a client-visible
      // failure that cannot be retried.
      if (!job.completed_steps.includes('auth_user')) {
        await this.store.deleteAuthUser(uid);
        job.completed_steps.push('auth_user');
      }

      const completedAt = this.now();
      job.status = 'completed';
      job.completed_at = completedAt;
      job.updated_at = completedAt;

      try {
        await this.store.saveJob(job);
      } catch (error) {
        this.logger.error('Account deleted but job completion was not saved', {
          uid,
          error: errorMessage(error),
        });
      }

      return {
        status: 'completed',
        alreadyCompleted: false,
        completedSteps: job.completed_steps.length,
      };
    } catch (error) {
      job.status = 'failed';
      job.updated_at = this.now();
      job.last_error = errorMessage(error).slice(0, 500);

      try {
        await this.store.saveJob(job);
      } catch (saveError) {
        this.logger.error('Failed to persist failed account deletion job', {
          uid,
          error: errorMessage(saveError),
        });
      }

      throw error;
    }
  }

  private async runStep(
    job: DeletionJob,
    step: DeletionStepId,
    action: () => Promise<void>
  ): Promise<void> {
    if (job.completed_steps.includes(step)) return;

    await action();

    job.completed_steps.push(step);
    job.updated_at = this.now();
    await this.store.saveJob(job);
  }

  private isStale(job: DeletionJob): boolean {
    const lastUpdate = job.updated_at ?? job.started_at ?? job.requested_at;
    return this.now().getTime() - lastUpdate.getTime() > STALE_JOB_MS;
  }
}

function normalizeSteps(value: unknown): DeletionStepId[] {
  if (!Array.isArray(value)) return [];
  const valid = new Set<string>(DELETION_STEP_IDS);
  return value.filter(
    (step): step is DeletionStepId =>
      typeof step === 'string' && valid.has(step)
  );
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

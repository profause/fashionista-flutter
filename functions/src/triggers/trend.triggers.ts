import {
  FirestoreEvent,
  Change,
  DocumentSnapshot,
} from 'firebase-functions/v2/firestore';
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';
import {
  InterestCounterRepository,
  syncFashionInterestPostCounts,
} from '../trends/interest-counts';
import {
  ReconcileRepository,
  ReconcileResult,
  rebuildFashionInterestPostCounts,
} from '../trends/reconcile';

interface TrendLogger {
  info: (message: string, ...args: unknown[]) => void;
  debug: (message: string, ...args: unknown[]) => void;
  warn: (message: string, ...args: unknown[]) => void;
  error: (message: string, ...args: unknown[]) => void;
}

/**
 * Maintains `fashion_interests.number_of_posts` for every trend write.
 *
 * A single `onDocumentWritten` trigger handles creation, update and deletion:
 *
 * - create: `after.tags` are all "added" (each unique tag is incremented);
 * - delete: `before.tags` are all "removed" (each unique tag is decremented);
 * - update: only the tags that differ between `before` and `after` are touched.
 *
 * The document id comes from `event.params` rather than the snapshots so a
 * deleted trend still resolves its own id.
 */
export async function onTrendWritten(
  event: FirestoreEvent<Change<DocumentSnapshot> | undefined>
): Promise<void> {
  const trendId = event.params.trendId;
  const before = event.data?.before.data() as Record<string, unknown> | undefined;
  const after = event.data?.after.data() as Record<string, unknown> | undefined;

  if (!before && !after) return;

  const context = buildContext();

  try {
    const result = await syncFashionInterestPostCounts(
      new InterestCounterRepository(context.db),
      trendId,
      before,
      after
    );

    if (result.missingInterests.length > 0) {
      context.logger.warn('Trend references unknown fashion interests', {
        trendId,
        addedTags: result.addedTags,
        removedTags: result.removedTags,
        missingInterests: result.missingInterests,
      });
    } else if (result.committed) {
      context.logger.debug('Updated fashion interest post counts', {
        trendId,
        addedTags: result.addedTags,
        removedTags: result.removedTags,
      });
    }
  } catch (error) {
    // Rethrow so the platform records the failure and can retry the event.
    context.logger.error('Failed to update fashion interest post counts', {
      trendId,
      error,
    });
    throw error;
  }
}

/**
 * Admin-only recovery operation that rebuilds
 * `fashion_interests.number_of_posts` from the current `trends` data.
 *
 * Requires an authenticated caller whose ID token carries the `admin: true`
 * custom claim. Intended to be invoked manually (for example from the Firebase
 * console or a tool script) after a missed or duplicated event.
 */
export async function onInterestCountRebuildRequest(
  request: CallableRequest
): Promise<ReconcileResult> {
  if (request.auth?.token?.admin !== true) {
    throw new HttpsError(
      'permission-denied',
      'Only administrators can rebuild fashion interest post counts.'
    );
  }

  const context = buildContext();
  const summary = await rebuildFashionInterestPostCounts(
    new ReconcileRepository(context.db)
  );

  context.logger.info('Rebuilt fashion interest post counts', { ...summary });

  return summary;
}

function buildContext(): { db: Firestore; logger: TrendLogger } {
  // Imported lazily so unit tests can import this module without initialising
  // the Admin SDK.
  const admin = require('firebase-admin');
  const { getFirestore } = require('firebase-admin/firestore');
  const { logger } = require('firebase-functions');

  return { db: getFirestore(admin.app()), logger };
}

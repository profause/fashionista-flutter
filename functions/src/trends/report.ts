import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

/** Default number of unique reporters that hides a trend. */
export const DEFAULT_REPORT_THRESHOLD = 5;

export interface ReportDetail {
  reason: string;
  reason_title: string;
  number_of_times_reported: number;
}

export interface ReportAggregate {
  details: ReportDetail[];
  total: number;
}

interface ReportLogger {
  error: (message: string, ...args: unknown[]) => void;
}

/**
 * Adds one unique report to the reason breakdown.
 *
 * Existing aggregates are re-derived from their `details` array rather than
 * trusting a separately stored total, so a malformed value cannot hide a trend
 * early.
 */
export function mergeReasonReport(
  existingDetails: unknown,
  reasonId: string,
  reasonTitle: string
): ReportAggregate {
  const details = normalizeDetails(existingDetails);
  const index = details.findIndex((item) => item.reason === reasonId);

  if (index >= 0) {
    details[index] = {
      ...details[index],
      reason_title: reasonTitle,
      number_of_times_reported:
        details[index].number_of_times_reported + 1,
    };
  } else {
    details.push({
      reason: reasonId,
      reason_title: reasonTitle,
      number_of_times_reported: 1,
    });
  }

  return {
    details,
    total: details.reduce(
      (sum, item) => sum + item.number_of_times_reported,
      0
    ),
  };
}

export function normalizeDetails(value: unknown): ReportDetail[] {
  if (!Array.isArray(value)) return [];

  const details: ReportDetail[] = [];
  for (const entry of value) {
    if (typeof entry !== 'object' || entry === null) continue;

    const record = entry as Record<string, unknown>;
    const reason = typeof record.reason === 'string' ? record.reason : '';
    if (!reason) continue;

    const reasonTitle =
      typeof record.reason_title === 'string' ? record.reason_title : reason;
    const count =
      typeof record.number_of_times_reported === 'number' &&
      Number.isFinite(record.number_of_times_reported)
        ? Math.max(0, Math.floor(record.number_of_times_reported))
        : 0;

    details.push({
      reason,
      reason_title: reasonTitle,
      number_of_times_reported: count,
    });
  }

  return details;
}

export function isThresholdReached(total: number, threshold: number): boolean {
  return threshold > 0 && total >= threshold;
}

export function resolveThreshold(raw: unknown): number {
  if (typeof raw === 'number' && Number.isFinite(raw) && raw >= 1) {
    return Math.floor(raw);
  }
  return DEFAULT_REPORT_THRESHOLD;
}

export function resolveEnabled(raw: unknown): boolean {
  return raw !== false;
}

/**
 * Records one report per user and hides the trend when the unique reporter
 * count reaches the configured threshold.
 *
 * All reads happen before writes, as required by Firestore transactions.
 * The per-user receipt makes retries and duplicate taps idempotent.
 */
export async function handleReportTrend(
  request: CallableRequest
): Promise<{
  hidden: boolean;
  alreadyReported: boolean;
  numberOfReports: number;
}> {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to report a trend.'
    );
  }

  const data =
    typeof request.data === 'object' && request.data !== null
      ? (request.data as Record<string, unknown>)
      : {};
  const trendId = readId(data.trendId);
  const reasonId = readId(data.reasonId);

  if (!trendId || !reasonId) {
    throw new HttpsError(
      'invalid-argument',
      'A trend and a report reason are required.'
    );
  }

  const context = buildContext();
  const db = context.db;
  const trendRef = db.collection('trends').doc(trendId);
  const reasonRef = db.collection('report_trend_content').doc(reasonId);
  const aggregateRef = db.collection('reported_trends').doc(trendId);
  const receiptRef = aggregateRef.collection('reports').doc(uid);
  const configRef = db.collection('app_config').doc('trend_reporting');
  const now = new Date();

  try {
    return await db.runTransaction(async (transaction) => {
      const trendSnap = await transaction.get(trendRef);
      const reasonSnap = await transaction.get(reasonRef);
      const aggregateSnap = await transaction.get(aggregateRef);
      const receiptSnap = await transaction.get(receiptRef);
      const configSnap = await transaction.get(configRef);

      if (!trendSnap.exists) {
        throw new HttpsError('not-found', 'This trend no longer exists.');
      }

      const trend = trendSnap.data() ?? {};
      if (trend.created_by === uid) {
        throw new HttpsError(
          'failed-precondition',
          'You cannot report your own trend.'
        );
      }

      if (!reasonSnap.exists) {
        throw new HttpsError('not-found', 'This report reason is unavailable.');
      }

      const reason = reasonSnap.data() ?? {};
      if (reason.is_active === false) {
        throw new HttpsError('not-found', 'This report reason is unavailable.');
      }

      const config = configSnap.data() ?? {};
      if (!resolveEnabled(config.enabled)) {
        throw new HttpsError(
          'failed-precondition',
          'Reporting is temporarily unavailable.'
        );
      }

      const existingAggregate = aggregateSnap.data() ?? {};
      const existingTotal =
        typeof existingAggregate.number_of_times_reported === 'number'
          ? Math.max(
              0,
              Math.floor(existingAggregate.number_of_times_reported)
            )
          : 0;

      if (receiptSnap.exists) {
        return {
          hidden: trend.status === 'reported',
          alreadyReported: true,
          numberOfReports: existingTotal,
        };
      }

      if (trend.status === 'reported') {
        return {
          hidden: true,
          alreadyReported: false,
          numberOfReports: existingTotal,
        };
      }

      const reasonTitle =
        typeof reason.title === 'string' && reason.title.trim()
          ? reason.title.trim()
          : reasonId;
      const aggregate = mergeReasonReport(
        existingAggregate.details,
        reasonId,
        reasonTitle
      );
      const threshold = resolveThreshold(config.threshold);
      const hidden = isThresholdReached(aggregate.total, threshold);

      transaction.set(receiptRef, {
        trend_id: trendId,
        reason: reasonId,
        reason_title: reasonTitle,
        reported_by: uid,
        created_at: now,
      });

      transaction.set(
        aggregateRef,
        {
          trend_id: trendId,
          details: aggregate.details,
          number_of_times_reported: aggregate.total,
          updated_at: now,
          ...(aggregateSnap.exists && existingAggregate.first_reported_at
            ? {}
            : { first_reported_at: now }),
        },
        { merge: true }
      );

      if (hidden) {
        transaction.set(
          trendRef,
          {
            status: 'reported',
            reported_at: now,
            number_of_times_reported: aggregate.total,
          },
          { merge: true }
        );
      }

      return {
        hidden,
        alreadyReported: false,
        numberOfReports: aggregate.total,
      };
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;

    context.logger.error('Failed to record trend report', {
      trendId,
      reasonId,
      uid,
      error,
    });
    throw new HttpsError(
      'internal',
      'Could not submit your report. Please try again.'
    );
  }
}

export const reportTrend = onCall(async (request) =>
  handleReportTrend(request)
);

function readId(value: unknown): string {  if (typeof value !== 'string') return '';
  const id = value.trim();
  if (!id || id.length > 128 || id.includes('/')) return '';
  return id;
}

function buildContext(): {
  db: Firestore;
  logger: ReportLogger;
} {
  // Imported lazily so unit tests can import this module without initialising
  // the Admin SDK.
  const admin = require('firebase-admin');
  const { getFirestore } = require('firebase-admin/firestore');
  const { logger } = require('firebase-functions');

  return { db: getFirestore(admin.app()), logger };
}

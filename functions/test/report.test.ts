import {
  DEFAULT_REPORT_THRESHOLD,
  isThresholdReached,
  mergeReasonReport,
  normalizeDetails,
  resolveEnabled,
  resolveThreshold,
} from '../src/trends/report';

describe('normalizeDetails', () => {
  it('keeps valid reason entries and drops malformed ones', () => {
    expect(
      normalizeDetails([
        { reason: 'spam', reason_title: 'Spam', number_of_times_reported: 2 },
        { reason: '', number_of_times_reported: 4 },
        { reason: 'abuse', number_of_times_reported: '3' },
        { reason: 'ads', reason_title: 'Ads', number_of_times_reported: 1.9 },
        null,
        'nope',
      ])
    ).toEqual([
      { reason: 'spam', reason_title: 'Spam', number_of_times_reported: 2 },
      { reason: 'abuse', reason_title: 'abuse', number_of_times_reported: 0 },
      { reason: 'ads', reason_title: 'Ads', number_of_times_reported: 1 },
    ]);
  });

  it('returns an empty list for a missing breakdown', () => {
    expect(normalizeDetails(undefined)).toEqual([]);
    expect(normalizeDetails({})).toEqual([]);
  });
});

describe('mergeReasonReport', () => {
  it('adds a first report for a reason', () => {
    expect(mergeReasonReport([], 'spam', 'Spam')).toEqual({
      details: [
        { reason: 'spam', reason_title: 'Spam', number_of_times_reported: 1 },
      ],
      total: 1,
    });
  });

  it('increments an existing reason and recalculates the total', () => {
    const aggregate = mergeReasonReport(
      [{ reason: 'spam', reason_title: 'Old title', number_of_times_reported: 2 }],
      'spam',
      'Spam'
    );

    expect(aggregate.details).toEqual([
      { reason: 'spam', reason_title: 'Spam', number_of_times_reported: 3 },
    ]);
    expect(aggregate.total).toBe(3);
  });

  it('keeps reasons separate and sums their counts', () => {
    const aggregate = mergeReasonReport(
      [{ reason: 'spam', reason_title: 'Spam', number_of_times_reported: 2 }],
      'abuse',
      'Abuse'
    );

    expect(aggregate.total).toBe(3);
    expect(aggregate.details).toHaveLength(2);
  });
});

describe('threshold helpers', () => {
  it('uses the default when the config is missing or invalid', () => {
    expect(resolveThreshold(undefined)).toBe(DEFAULT_REPORT_THRESHOLD);
    expect(resolveThreshold('3')).toBe(DEFAULT_REPORT_THRESHOLD);
    expect(resolveThreshold(0)).toBe(DEFAULT_REPORT_THRESHOLD);
    expect(resolveThreshold(-2)).toBe(DEFAULT_REPORT_THRESHOLD);
  });

  it('floors a configured threshold', () => {
    expect(resolveThreshold(3.9)).toBe(3);
    expect(resolveThreshold(1)).toBe(1);
  });

  it('reaches the threshold at or above the value', () => {
    expect(isThresholdReached(4, 5)).toBe(false);
    expect(isThresholdReached(5, 5)).toBe(true);
    expect(isThresholdReached(6, 5)).toBe(true);
    expect(isThresholdReached(100, 0)).toBe(false);
  });

  it('treats only an explicit false as disabled', () => {
    expect(resolveEnabled(undefined)).toBe(true);
    expect(resolveEnabled(true)).toBe(true);
    expect(resolveEnabled(false)).toBe(false);
  });
});

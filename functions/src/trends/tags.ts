/**
 * Pure helpers for normalizing and diffing trend tags.
 *
 * A trend's `tags` value stores `fashion_interests.name` values. The Flutter
 * `TrendFeedModel` declares it as a `String?`, so the live documents hold a
 * comma-separated string such as `"Ankara,Wedding"`. An array of strings is
 * also accepted because older imports wrote that shape.
 *
 * Both are handled here; callers always receive a de-duplicated list.
 */

/** Extracts the raw tag entries from either supported `tags` shape. */
function toTagEntries(raw: unknown): unknown[] {
  if (Array.isArray(raw)) return raw;
  if (typeof raw === 'string') return raw.split(',');
  return [];
}

/**
 * Normalizes a raw `tags` value into a de-duplicated list of trimmed,
 * non-empty tag names, preserving first-appearance order.
 *
 * Any non-string input becomes `[]`; non-string entries and blanks are skipped.
 */
export function normalizeTags(raw: unknown): string[] {
  const normalized: string[] = [];
  const seen = new Set<string>();

  for (const entry of toTagEntries(raw)) {
    if (typeof entry !== 'string') continue;

    const tag = entry.trim();
    if (tag === '' || seen.has(tag)) continue;

    seen.add(tag);
    normalized.push(tag);
  }

  return normalized;
}

/** Tags added and removed between two already normalized lists. */
export function diffTags(
  before: readonly string[],
  after: readonly string[]
): { added: string[]; removed: string[] } {
  const beforeSet = new Set(before);
  const afterSet = new Set(after);

  return {
    added: after.filter((tag) => !beforeSet.has(tag)),
    removed: before.filter((tag) => !afterSet.has(tag)),
  };
}

/**
 * Net delta per tag, with opposite moves cancelling out.
 *
 * `added` and `removed` are disjoint by construction, so a tag maps to `+1`,
 * `-1` or is absent — never both.
 */
export function tallyTagDeltas(
  added: readonly string[],
  removed: readonly string[]
): Map<string, number> {
  const deltas = new Map<string, number>();

  for (const tag of added) deltas.set(tag, (deltas.get(tag) ?? 0) + 1);
  for (const tag of removed) deltas.set(tag, (deltas.get(tag) ?? 0) - 1);

  return deltas;
}

/**
 * How many documents reference each tag.
 *
 * Used by the reconcile pass, which counts from the source of truth instead of
 * trusting the stored counter.
 */
export function countTags(rawTagsValues: Iterable<unknown>): Map<string, number> {
  const counts = new Map<string, number>();

  for (const raw of rawTagsValues) {
    for (const tag of normalizeTags(raw)) {
      counts.set(tag, (counts.get(tag) ?? 0) + 1);
    }
  }

  return counts;
}

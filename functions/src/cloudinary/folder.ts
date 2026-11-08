/**
 * Folder rules shared by the client (upload) and the delete callable.
 *
 * Videos live under `<base>/trends/videos/<uid>/<public_id>` so every asset is
 * attributable to one user.
 */

/** Folder that owns every video for one user. */
export function trendVideoFolder(baseFolder: string, uid: string): string {
  const base = sanitizeSegment(baseFolder);
  const user = sanitizeSegment(uid);
  if (!user) throw new Error('A user id is required to build the folder');
  return [base, 'trends', 'videos', user].filter(Boolean).join('/');
}

/**
 * Rejects anything that could escape a folder: `/`, `..`, whitespace and
 * Cloudinary's reserved characters.
 */
export function sanitizeSegment(value: string): string {
  return (value ?? '').trim().replace(/[^A-Za-z0-9_-]/g, '');
}

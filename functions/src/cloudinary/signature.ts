import { createHmac } from 'node:crypto';

/** Parameters Cloudinary includes in the signature, in alphabetical order. */
export interface UploadSignatureParams {
  folder: string;
  public_id: string;
  timestamp: number;
}

/**
 * HMAC-SHA1 signature exactly as Cloudinary computes it: alphabetically sorted
 * `key=value` pairs joined with `&`, hashed with the API secret.
 *
 * `file`, `api_key`, `resource_type` and `cloud_name` are never signed, so
 * sending any extra parameter from the client invalidates the signature.
 */
export function signUploadParams(
  params: UploadSignatureParams,
  apiSecret: string,
): string {
  if (!apiSecret) throw new Error('Cloudinary API secret is not configured');

  const toSign = [
    `folder=${params.folder}`,
    `public_id=${params.public_id}`,
    `timestamp=${params.timestamp}`,
  ].join('&');

  return createHmac('sha1', apiSecret).update(toSign).digest('hex');
}

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

const TREND_ID_PATTERN = /^[A-Za-z0-9_-]{6,64}$/;

export function isValidTrendId(trendId: string): boolean {
  return TREND_ID_PATTERN.test(trendId ?? '');
}

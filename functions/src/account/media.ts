export type MediaResourceType = 'image' | 'video';

export interface MediaAsset {
  publicId: string;
  resourceType: MediaResourceType;
}

const IMAGE_EXTENSIONS = /\.(avif|gif|jpe?g|png|webp)$/i;
const VIDEO_EXTENSIONS = /\.(m4v|mkv|mov|mp4|webm)$/i;

/**
 * Extracts the Cloudinary public id and resource type from a delivery URL.
 *
 * Cloudinary URLs may contain one or more transformation components before the
 * optional version and the folder/public-id path. Only public ids created by
 * this app are supported; anything outside `res.cloudinary.com` is ignored.
 */
export function parseCloudinaryUrl(url: string): MediaAsset | null {
  if (typeof url !== 'string' || !url.trim()) return null;

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }

  if (!parsed.hostname.endsWith('cloudinary.com')) return null;

  const marker = parsed.pathname.indexOf('/upload/');
  if (marker < 0) return null;

  const resourceType: MediaResourceType = parsed.pathname
    .slice(0, marker)
    .includes('/video')
    ? 'video'
    : 'image';

  const segments = parsed.pathname
    .slice(marker + '/upload/'.length)
    .split('/')
    .filter(Boolean);

  const versionIndex = segments.findIndex((segment) => /^v\d+$/.test(segment));
  const pathSegments =
    versionIndex >= 0 ? segments.slice(versionIndex + 1) : [...segments];

  // When there is no version component, drop leading transformation segments.
  while (
    pathSegments.length > 1 &&
    isTransformationSegment(pathSegments[0])
  ) {
    pathSegments.shift();
  }

  if (pathSegments.length === 0) return null;

  const lastIndex = pathSegments.length - 1;
  pathSegments[lastIndex] = stripExtension(pathSegments[lastIndex]);
  const publicId = pathSegments.join('/');

  return publicId ? { publicId, resourceType } : null;
}

/** Reads a `featured_media` / `featured_images` array into media assets. */
export function mediaAssetsFromFeatured(value: unknown): MediaAsset[] {
  if (!Array.isArray(value)) return [];

  const assets: MediaAsset[] = [];
  for (const entry of value) {
    if (typeof entry === 'string') {
      const parsed = parseCloudinaryUrl(entry);
      if (parsed) assets.push(parsed);
      continue;
    }
    if (typeof entry !== 'object' || entry === null) continue;

    const record = entry as Record<string, unknown>;
    const hint: MediaResourceType =
      record.type === 'video' ? 'video' : 'image';
    const uid = typeof record.uid === 'string' ? record.uid.trim() : '';
    const url = typeof record.url === 'string' ? record.url.trim() : '';

    if (uid) {
      if (uid.startsWith('http://') || uid.startsWith('https://')) {
        const parsed = parseCloudinaryUrl(uid);
        if (parsed) assets.push(parsed);
      } else if (!uid.includes('/') && url) {
        // Older documents may hold a bare asset id even though the delivery
        // URL still carries the full folder path.
        const parsed = parseCloudinaryUrl(url);
        assets.push(parsed ?? { publicId: uid, resourceType: hint });
      } else {
        assets.push({ publicId: uid, resourceType: hint });
      }
      continue;
    }

    const parsed = parseCloudinaryUrl(url);
    if (parsed) assets.push(parsed);
  }

  return assets;
}

export function mediaAssetFromUrl(url: unknown): MediaAsset | null {
  return typeof url === 'string' ? parseCloudinaryUrl(url) : null;
}

/** Returns a stable, de-duplicated list for retryable job storage. */
export function dedupeMedia(assets: MediaAsset[]): MediaAsset[] {
  const seen = new Set<string>();
  const result: MediaAsset[] = [];

  for (const asset of assets) {
    if (!asset.publicId) continue;
    const key = `${asset.resourceType}:${asset.publicId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(asset);
  }

  return result;
}

const TRANSFORMATION_KEYS = new Set([
  'a',
  'ac',
  'af',
  'ar',
  'b',
  'bo',
  'c',
  'co',
  'd',
  'dl',
  'dn',
  'du',
  'e',
  'eo',
  'f',
  'fl',
  'fn',
  'fps',
  'g',
  'h',
  'if',
  'l',
  'o',
  'p',
  'pg',
  'q',
  'r',
  'so',
  'sp',
  't',
  'u',
  'vc',
  'vs',
  'w',
  'x',
  'y',
  'z',
]);

function isTransformationSegment(segment: string): boolean {
  // Transformation components are comma-separated flags (`c_fill,w_200`) or a
  // single parameterised component (`q_auto`, `so_0`). Restrict the prefix to
  // Cloudinary's transformation keys so a folder such as `abc_def` is kept.
  if (segment.includes(',')) return true;
  const key = segment.split('_')[0].toLowerCase();
  return segment.includes('_') && TRANSFORMATION_KEYS.has(key);
}

function stripExtension(segment: string): string {
  if (IMAGE_EXTENSIONS.test(segment) || VIDEO_EXTENSIONS.test(segment)) {
    return segment.replace(/\.[^.]+$/, '');
  }
  return segment;
}

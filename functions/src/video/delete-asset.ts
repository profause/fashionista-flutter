import { sanitizeSegment, trendVideoFolder } from '../cloudinary/signature';

export interface DeleteAssetInput {
  uid: string | undefined;
  trendId: unknown;
  assetId: unknown;
  /** `created_by` of the trend document being deleted. */
  ownerId: string | null;
  baseFolder: string;
  cloudName: string;
  apiKey: string;
  apiSecret: string;
}

export class DeleteAssetError extends Error {}

/** The asset must live under the caller's own video folder. */
export function assertAssetOwnership(input: {
  uid: string | undefined;
  assetId: string;
  ownerId: string | null;
  baseFolder: string;
}): void {
  if (!input.uid) throw new DeleteAssetError('You need to be signed in.');
  if (input.ownerId !== input.uid) {
    throw new DeleteAssetError('That post does not belong to you.');
  }

  const folder = trendVideoFolder(input.baseFolder, sanitizeSegment(input.uid));
  if (!input.assetId.startsWith(`${folder}/`)) {
    throw new DeleteAssetError('That asset does not belong to you.');
  }
}

/**
 * Deletes a Cloudinary asset with the Admin API (Basic auth with the API
 * secret, which must never reach the client).
 */
export async function destroyCloudinaryAsset(input: {
  cloudName: string;
  apiKey: string;
  apiSecret: string;
  assetId: string;
  fetchImpl?: typeof fetch;
}): Promise<{ result: string }> {
  if (!input.apiKey || !input.apiSecret || !input.cloudName) {
    throw new DeleteAssetError('Cloudinary is not configured.');
  }

  const doFetch = input.fetchImpl ?? fetch;
  const auth = Buffer.from(`${input.apiKey}:${input.apiSecret}`).toString('base64');
  const body = new URLSearchParams({
    public_id: input.assetId,
    invalidate: 'true',
  });

  const response = await doFetch(
    `https://api.cloudinary.com/v1_1/${input.cloudName}/video/destroy`,
    {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body,
    },
  );

  const payload = (await response.json().catch(() => ({}))) as { result?: string };

  // Cloudinary reports "not found" with HTTP 200 and result: 'not found'.
  if (!response.ok) {
    throw new DeleteAssetError(
      `Cloudinary rejected the delete (${response.status}).`,
    );
  }

  return { result: payload.result ?? 'ok' };
}

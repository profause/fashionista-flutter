import { trendVideoFolder, isValidTrendId, signUploadParams } from '../cloudinary/signature';

export interface UploadSignatureInput {
  uid: string | undefined;
  trendId: unknown;
  baseFolder: string;
  cloudName: string;
  apiKey: string;
  apiSecret: string;
  /** Injected so tests are deterministic. */
  now?: number;
}

export interface UploadSignature {
  cloudName: string;
  apiKey: string;
  timestamp: number;
  signature: string;
  folder: string;
  publicId: string;
}

export class SignatureError extends Error {}

/**
 * Builds the parameters the client echoes back to Cloudinary.
 *
 * The folder is derived from the authenticated uid — never from client input —
 * so one user cannot obtain a signature that writes into another user's folder.
 */
export function buildUploadSignature(input: UploadSignatureInput): UploadSignature {
  if (!input.uid) throw new SignatureError('You need to be signed in.');
  if (typeof input.trendId !== 'string' || !isValidTrendId(input.trendId)) {
    throw new SignatureError('That post id is not valid.');
  }
  if (!input.apiKey || !input.apiSecret || !input.cloudName) {
    throw new SignatureError('Video uploads are not configured.');
  }

  const folder = trendVideoFolder(input.baseFolder, input.uid);
  const timestamp = input.now ?? Math.floor(Date.now() / 1000);

  return {
    cloudName: input.cloudName,
    apiKey: input.apiKey,
    timestamp,
    signature: signUploadParams(
      { folder, public_id: input.trendId, timestamp },
      input.apiSecret,
    ),
    folder,
    publicId: input.trendId,
  };
}

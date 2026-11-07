import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { getFirestore } from 'firebase-admin/firestore';

import { buildUploadSignature, SignatureError } from './upload-signature';
import {
  assertAssetOwnership,
  destroyCloudinaryAsset,
  DeleteAssetError,
} from './delete-asset';

const CLOUDINARY_API_SECRET = defineSecret('CLOUDINARY_API_SECRET');

/** Values that are safe to keep in code/config; only the secret is a secret. */
const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME ?? '';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY ?? '';
const CLOUDINARY_BASE_FOLDER = process.env.CLOUDINARY_BASE_FOLDER ?? 'fashionista';

const TRENDS_COLLECTION = 'trends';

export const createVideoUploadSignature = onCall(
  { secrets: [CLOUDINARY_API_SECRET] },
  (request) => {
    try {
      return buildUploadSignature({
        uid: request.auth?.uid,
        trendId: request.data?.trendId,
        baseFolder: CLOUDINARY_BASE_FOLDER,
        cloudName: CLOUDINARY_CLOUD_NAME,
        apiKey: CLOUDINARY_API_KEY,
        apiSecret: CLOUDINARY_API_SECRET.value(),
      });
    } catch (error) {
      if (error instanceof SignatureError) {
        throw new HttpsError('invalid-argument', error.message);
      }
      throw new HttpsError('internal', 'Unable to sign the upload.');
    }
  },
);

export const deleteCloudinaryAsset = onCall(
  { secrets: [CLOUDINARY_API_SECRET] },
  async (request) => {
    const uid = request.auth?.uid;
    const trendId = request.data?.trendId;
    const assetId = request.data?.assetId;

    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    if (typeof assetId !== 'string' || assetId.length === 0) {
      throw new HttpsError('invalid-argument', 'An asset id is required.');
    }

    let ownerId: string | null = null;
    if (typeof trendId === 'string' && trendId.length > 0) {
      const snapshot = await getFirestore()
        .collection(TRENDS_COLLECTION)
        .doc(trendId)
        .get();
      ownerId = (snapshot.data()?.created_by as string | undefined) ?? null;
    }

    try {
      assertAssetOwnership({
        uid,
        assetId,
        ownerId,
        baseFolder: CLOUDINARY_BASE_FOLDER,
      });

      const result = await destroyCloudinaryAsset({
        cloudName: CLOUDINARY_CLOUD_NAME,
        apiKey: CLOUDINARY_API_KEY,
        apiSecret: CLOUDINARY_API_SECRET.value(),
        assetId,
      });

      return result;
    } catch (error) {
      if (error instanceof DeleteAssetError) {
        throw new HttpsError('permission-denied', error.message);
      }
      throw new HttpsError('internal', 'Unable to delete the asset.');
    }
  },
);

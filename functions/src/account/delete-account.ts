import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import {
  CallableRequest,
  HttpsError,
  onCall,
} from 'firebase-functions/v2/https';

import {
  AccountDeletionBusyError,
  AccountDeletionResult,
  AccountDeletionService,
  DeletionLogger,
  DeletionStore,
} from './deletion-service';
import { FirestoreAccountDeletionStore } from './firestore-deletion-store';

const CLOUDINARY_API_SECRET = defineSecret('CLOUDINARY_API_SECRET');

const CLOUDINARY_CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME ?? '';
const CLOUDINARY_API_KEY = process.env.CLOUDINARY_API_KEY ?? '';

export interface DeleteAccountDependencies {
  store?: DeletionStore;
  logger?: DeletionLogger;
  now?: () => Date;
}

/**
 * Handles one authenticated deletion request.
 *
 * The uid always comes from the verified ID token; the client cannot choose
 * whose account is deleted. Kept separate from the callable export so unit
 * tests can inject an in-memory store.
 */
export async function handleDeleteMyAccount(
  request: CallableRequest,
  dependencies: DeleteAccountDependencies = {}
): Promise<AccountDeletionResult> {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to delete your account.'
    );
  }

  const data =
    typeof request.data === 'object' && request.data !== null
      ? (request.data as Record<string, unknown>)
      : {};

  if (data.confirmation !== 'DELETE') {
    throw new HttpsError(
      'invalid-argument',
      'Type DELETE to confirm account deletion.'
    );
  }

  const store = dependencies.store ?? createFirestoreStore();
  const accountLogger = dependencies.logger ?? logger;
  const service = new AccountDeletionService(
    store,
    accountLogger,
    dependencies.now
  );

  try {
    return await service.delete(uid);
  } catch (error) {
    if (error instanceof AccountDeletionBusyError) {
      throw new HttpsError(
        'failed-precondition',
        'Your account deletion is already in progress.'
      );
    }

    accountLogger.error('Account deletion failed', {
      uid,
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
      'internal',
      'We could not finish deleting your account. Please try again.'
    );
  }
}

export const deleteMyAccount = onCall(
  {
    timeoutSeconds: 540,
    memory: '1GiB',
    secrets: [CLOUDINARY_API_SECRET],
  },
  async (request) => handleDeleteMyAccount(request)
);

function createFirestoreStore(): DeletionStore {
  return new FirestoreAccountDeletionStore({
    db: getFirestore(),
    auth: getAuth(),
    storage: getStorage(),
    cloudinary: {
      cloudName: CLOUDINARY_CLOUD_NAME,
      apiKey: CLOUDINARY_API_KEY,
      apiSecret: CLOUDINARY_API_SECRET.value(),
    },
  });
}

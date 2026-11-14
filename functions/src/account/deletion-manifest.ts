/**
 * Single source of truth for account-owned Firestore data.
 *
 * Every user-owned collection or collection group must appear here. A unit test
 * compares this list against the manifest so a new feature cannot silently
 * leave personal data behind.
 */
export const USER_DATA_COLLECTIONS = [
  'users',
  'closets',
  'trends',
  'likes',
  'followers',
  'comments',
  'reports',
  'notifications',
  'designer_reviews',
  'designer_feedback',
  'bookings',
  'slot_reservations',
  'work_orders',
  'work_order_status_progress',
  'clients',
  'client_measurements',
  'designers',
  'design_collections',
  'designer_services',
] as const;

export type UserDataCollection = (typeof USER_DATA_COLLECTIONS)[number];

export const DELETION_STEP_IDS = [
  'media_scan',
  'interactions',
  'trends',
  'designer_content',
  'commerce',
  'client_records',
  'user_documents',
  'media',
  'legacy_storage',
  'auth_user',
] as const;

export type DeletionStepId = (typeof DELETION_STEP_IDS)[number];

export type DeletionAction =
  | 'scan-media'
  | 'delete-tree'
  | 'delete-query'
  | 'anonymize'
  | 'destroy-media'
  | 'delete-storage'
  | 'delete-auth';

export interface DeletionManifestEntry {
  step: DeletionStepId;
  collections: UserDataCollection[];
  selector: string;
  action: DeletionAction;
}

export const ACCOUNT_DELETION_MANIFEST: DeletionManifestEntry[] = [
  {
    step: 'media_scan',
    collections: [
      'users',
      'trends',
      'designers',
      'design_collections',
      'designer_services',
      'work_orders',
      'work_order_status_progress',
      'clients',
      'closets',
    ],
    selector: 'media referenced by account-owned documents',
    action: 'scan-media',
  },
  {
    step: 'interactions',
    collections: [
      'likes',
      'followers',
      'comments',
      'reports',
      'designer_reviews',
      'designer_feedback',
      'notifications',
    ],
    selector: 'likes/followers/comments/reviews/feedback authored by uid',
    action: 'delete-query',
  },
  {
    step: 'trends',
    collections: ['trends'],
    selector: 'created_by == uid, including comments/likes/followers',
    action: 'delete-tree',
  },
  {
    step: 'designer_content',
    collections: [
      'designers',
      'design_collections',
      'designer_services',
      'designer_reviews',
      'designer_feedback',
    ],
    selector: 'designer uid and content authored by uid',
    action: 'delete-tree',
  },
  {
    step: 'commerce',
    collections: [
      'bookings',
      'slot_reservations',
      'work_orders',
      'work_order_status_progress',
    ],
    selector: 'user_id/designer_id/created_by/client.uid == uid',
    action: 'delete-query',
  },
  {
    step: 'client_records',
    collections: ['clients', 'client_measurements'],
    selector: 'clients created by uid and the uid client-link tree',
    action: 'delete-tree',
  },
  {
    step: 'user_documents',
    collections: ['users', 'closets'],
    selector: 'users/{uid} and closets/{uid} trees',
    action: 'delete-tree',
  },
  {
    step: 'media',
    collections: [],
    selector: 'Cloudinary public ids collected before deletion',
    action: 'destroy-media',
  },
  {
    step: 'legacy_storage',
    collections: [],
    selector: 'legacy Firebase Storage profile/banner objects',
    action: 'delete-storage',
  },
  {
    step: 'auth_user',
    collections: [],
    selector: 'Firebase Auth user',
    action: 'delete-auth',
  },
];

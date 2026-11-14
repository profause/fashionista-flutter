# Account Deactivation / Deletion — Implementation Plan

**Status:** Proposed (not implemented)
**Date:** 2026-11-13
**Related:** [push-notifications-module.md](./push-notifications-module.md), [designer-availability-booking-module.md](./designer-availability-booking-module.md)
**Trigger:** App Store Connect requires account deletion for apps that support account creation (Guideline 5.1.1(v)).

---

## 0. Context — current state

There is no account deletion or deactivation path today. The only account-exit
flow is sign-out, which is implemented inside the profile page widget and
performs a substantial local cleanup inline.

| # | Finding | Evidence |
|---|---|---|
| F1 | **No account deletion or deactivation exists.** The only exit is sign-out. | `lib/presentation/screens/profile/user_profile_page.dart` (`_signOut`), `lib/domain/usecases/auth/signout_usecase.dart` |
| F2 | **Auth is phone OTP only.** There is no email/password or anonymous path. A fresh OTP is available for re-authentication if desired. | `lib/presentation/screens/auth/`, `lib/data/services/firebase/firebase_auth_service.dart` |
| F3 | **The app supports account creation**, which is what triggers Apple's deletion requirement. | `lib/presentation/screens/auth/sign_in_screen.dart` → `/create-profile`, `lib/presentation/screens/profile/create_profile_screen.dart` |
| F4 | **The deletion entry point does not exist.** Settings has an "Account & Privacy" card but only Notifications, Data & Storage and Clear Cache. | `lib/presentation/screens/settings/settings_screen.dart:124-150`; route at `lib/core/routes/app_router.dart:98` |
| F5 | **Clients cannot delete most of their own cross-user data by rules.** Bookings and slot reservations are explicitly `allow delete: if false`; notifications too. | `firestore.rules:191` (bookings), `:230` (slot_reservations), `:251` (notifications) |
| F6 | **The backend can do the cascade.** Cloud Functions v2, `firebase-admin` and an Admin-API Cloudinary delete callable already exist. | `functions/src/index.ts:107-109`, `functions/src/video/callables.ts`, `functions/package.json` |
| F7 | **User identity media is in Cloudinary with derivable public ids.** Profile images use `publicId = uid` under the profile folder; banner images use `publicId = uid` under the banner folder. | `lib/data/services/firebase/firebase_user_service.dart` (`uploadProfileImageToCloudinary`, `uploadBannerImageToCloudinary`), `lib/data/services/firebase/firebase_designers_service.dart` (designer banner) |
| F8 | **Trend images/videos store their public id in the document.** Trend images use `{base}/{trendMediaFolder}/{trendId}_{i}`; videos use `{base}/trends/videos/{uid}/{publicId}` and store the full public id in `featured_media[].uid`. | `lib/presentation/screens/trends/add_trend_screen.dart` (image upload), `lib/data/services/firebase/firebase_video_upload_service.dart` (`toMedia`), `functions/src/cloudinary/folder.ts` |
| F9 | **Sign-out cleanup already exists but is embedded in the UI**, so deletion cannot reuse it without a refactor. | `lib/presentation/screens/profile/user_profile_page.dart:179-215` |
| F10 | **Push registration is per-device under the user document.** The dispatcher resolves active tokens from `users/{uid}/devices`. | `functions/src/notifications/repository.ts` (`getActiveDevices`), `lib/data/services/firebase/firebase_device_service.dart` |
| F11 | **Fashion-interest post counts are maintained by a Firestore trigger.** Deleting a trend decrements its tags; the trigger is the only writer. | `functions/src/triggers/trend.triggers.ts`, `functions/src/trends/interest-counts.ts` |
| F12 | **Designer rating aggregates are trigger-maintained.** Deleting a review recalculates the designer summary, and a missing designer is handled gracefully. | `functions/src/triggers/rating.triggers.ts`, `functions/src/ratings/service.ts` |
| F13 | **The client cannot delete its own Auth user safely/reliably** because Firebase requires a recent login and `user.delete()` only removes the Auth identity, not Firestore or media. | `lib/data/services/firebase/firebase_auth_service.dart` (no delete method) |
| F14 | **Deleting the Auth user changes the stream observed by the profile page.** The auth listener can fire before the deletion callable returns, so a deletion-in-progress guard is required. | `lib/presentation/screens/profile/profile_screen.dart` `userChanges()` listener |
| F15 | **The user model is hydrated locally**, so deletion must also clear `UserBloc` and `AuthProviderCubit` or the next launch can show stale profile data. | `lib/data/models/profile/bloc/user_bloc.dart`, `lib/core/auth/auth_provider_cubit.dart` |
| F16 | **No App Check is configured in the codebase.** The callable relies on Firebase Auth ID tokens only. | repo-wide search for `AppCheck` returned no initialisation |
| F17 | **There is no `account_deletions` collection or deletion job state.** Every retry would start from scratch without one. | Firestore rules and services |

### Current account-owned data map

The existing services/rules make ownership discoverable:

- Profile: `users/{uid}` + `devices`, `settings`, `favourite_designers`,
  `bookmarked_design_collections`, `pinned_clients`.
- Closet: `closets/{uid}` + `closet_items`, `outfits`, `outfit_plans`.
- Social: `trends` (created by), `trends/*/likes` (uid), `trends/*/followers`
  (uid), `trends/*/comments` (author.uid), `designer_reviews`
  (comment.author.uid), `designer_feedback` (author.uid), `notifications`
  (`to`/`from`).
- Commerce: `bookings` (`user_id`/`designer_id`), `slot_reservations`
  (`user_id`/`designer_id`), `work_orders` (`created_by` or `client.uid`),
  `work_orders/*/status_progress`.
- Client/designer: `clients/{uid}` + `measurements`,
  `client_measurements/{uid}/clients`, `designers/{uid}` + `availability`,
  `availability_exceptions`, `designer_services`, `design_collections`.
- Reference: `fashion_interests.number_of_posts` (trigger-owned aggregate).

---

## 1. Executive summary

Apple requires **in-app, self-service account deletion** for any app that
supports account creation. Deactivation alone is not a substitute. The plan is:

1. Add **Settings → Account & Privacy → Delete account**, with a secondary entry
   from the profile page.
2. Show a consequence screen and require an explicit, destructive confirmation.
3. Call a new server-side callable, **`deleteMyAccount`**, which performs an
   idempotent, resumable cascade with the Admin SDK and deletes the Firebase Auth
   user last.
4. Clear local state (blocs, Hive caches, image caches, local notifications) and
   route to sign-in.
5. Add backend unit tests, an emulator integration test, privacy-policy wording,
   and App Store review notes.

Deactivation is **optional and deferred**. If it is later offered, it must be
clearly separate from deletion and must actually hide the profile/content — not
just sign the user out.

---

## 2. Objectives

- Satisfy App Store Guideline 5.1.1(v) with a discoverable in-app deletion flow.
- Permanently remove the Firebase Auth identity and the user's personal data.
- Remove or safely anonymise personal data embedded in other users' records.
- Keep shared aggregates consistent (fashion-interest counts, designer ratings).
- Make deletion idempotent, retryable, observable, and safe against abuse.
- Avoid orphaned Cloudinary media and push-device registrations.
- Reuse the existing sign-out cleanup instead of duplicating it.

---

## 3. Scope

### In scope

- Deletion entry points in Settings and the profile page.
- Confirmation screen with consequences, privacy-policy link, and destructive
  confirmation.
- Server-side cascade: Firestore, Firebase Auth, Cloudinary, devices, Storage.
- Cross-user references: trends, likes, follows, comments, reviews, feedback,
  notifications, bookings, slot reservations, work orders, client/designer data.
- Local session cleanup and auth-state race handling.
- Unit tests, emulator integration test, privacy policy, App Review notes.
- Optional OTP re-authentication.

### Out of scope (first release)

- Soft deactivation with a 30-day grace period and reactivation UI.
- Data export / "Download my data".
- Web-based deletion portal (Apple expects in-app initiation).
- GDPR/CCPA request tooling beyond deletion.
- Repairing pre-existing production data inconsistencies.
- UGC reporting/moderation requirements (separate App Review item).

---

## 4. Assumptions

- `users/{uid}` and `designers/{uid}` use the Firebase Auth UID as the document id.
- Cloud Functions v2 and Admin SDK credentials are available in the
  `fashionista-2025` project.
- Immediate permanent deletion is acceptable (no legal/accounting requirement to
  retain completed transactions).
- Cloudinary remains the media store. The existing `CLOUDINARY_API_SECRET` secret
  and `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` environment configuration can
  be reused.
- A user can be both a client and a designer across different records.
- App Review can be given a Firebase test phone number and a review account.

---

## 5. Open questions

1. **Retention:** delete completed bookings/work orders, or anonymise and retain
   them for designer business records?
   *Recommendation: delete active records, anonymise completed ones only if the
   business requires retention.*
2. **Grace period:** immediate deletion, or soft-delete + 30-day purge?
   *Recommendation: immediate deletion for the first App Review submission.*
3. **Deactivation:** is it a real product requirement? If yes, what does
   "deactivated" mean for feed/search visibility and reactivation?
4. **Notifications authored by the user:** delete them from recipients' inboxes,
   or anonymise the embedded author snapshot?
5. **Re-authentication:** require a fresh phone OTP before deletion, or is typed
   confirmation sufficient?
   *Recommendation: typed confirmation for v1; OTP as a hardening follow-up.*
6. **Legal retention:** are there accounting/consumer-protection obligations for
   bookings/orders?
7. **Analytics/logs:** what retention period will the privacy policy state?
8. **App Review:** which Firebase test phone number and demo account will be used?

---

## 6. Architecture impact

### 6.1 Client (Flutter)

- New screen: `lib/presentation/screens/settings/account_deletion_screen.dart`
  (no code in this task).
- New route under `/settings/delete-account` in `lib/core/routes/app_router.dart`.
- Entry rows in:
  - `lib/presentation/screens/settings/settings_screen.dart` (primary).
  - `lib/presentation/screens/profile/user_profile_page.dart` (secondary, near
    sign-out).
- New domain repository/usecase for the callable, registered in
  `lib/core/service_locator/service_locator.dart`. A dedicated bloc/cubit is
  optional; the screen can use local state, but a small cubit is cleaner for
  progress/retry.
- Extract the sign-out cleanup from `UserProfilePage._signOut` into a shared
  service so both sign-out and deletion use the same code.
- Handle the auth-state race (F14): a deletion-in-progress flag must prevent the
  profile screen's `userChanges()` listener from fetching a deleted profile or
  showing an error.

### 6.2 Cloud Functions

- New module `functions/src/account/`:
  - `delete-account.ts` — callable entry point.
  - `deletion-manifest.ts` — single source of truth for all user-owned
    collections/paths.
  - `deletion-service.ts` — orchestration over small, testable ports.
  - `media.ts` — Cloudinary Admin API helpers.
- Export `deleteMyAccount` from `functions/src/index.ts`.
- Use Admin SDK:
  - `recursiveDelete()` for document trees.
  - `BulkWriter` or 500-doc batches for query results.
  - Paginated queries with explicit `limit` and cursors.
  - `getAuth().revokeRefreshTokens(uid)` before work.
  - `getAuth().deleteUser(uid)` last.
- Configure a callable timeout suitable for large accounts (up to 540s) and a
  retry/scheduled path for partial failures.

### 6.3 Firestore

- Optional `account_deletions/{uid}` job document:
  - `status`: `requested | in_progress | failed | completed`
  - `requested_at`, `started_at`, `completed_at`
  - completed step names / counts
  - `last_error` (message only, no PII)
  - collected media public ids for retry
- No schema changes to existing documents for immediate deletion.
- New indexes in `firestore.indexes.json` for collection-group queries:
  - `likes.uid`
  - `followers.uid`
  - `comments.author.uid`
  - `designer_reviews.comment.author.uid`
  - `designer_feedback.author.uid`
  - `work_orders.client.uid`
  - `clients.created_by`
- If deactivation is added later, add account-status fields and update every
  feed/search query to filter them.

### 6.4 Firebase Auth

- Revoke refresh tokens to invalidate other sessions.
- Delete the Auth user only after all data steps succeed.
- If OTP re-authentication is adopted, verify a fresh credential before calling
  the destructive callable; otherwise typed confirmation is the only gate.

### 6.5 Cloudinary and Firebase Storage

- Destroy profile/banner images by public id.
- Destroy trend images and videos from `featured_media[].uid`.
- Destroy design-collection images and designer media.
- Best-effort delete legacy Firebase Storage paths
  (`profile_images/{uid}.jpg`, banner equivalents).
- Reuse the `CLOUDINARY_API_SECRET` secret pattern from the existing callable.
- Because Firestore documents hold the public ids, collect them **before**
  deleting the documents; store them in the job document for retry.

### 6.6 Security rules

- No changes are required for immediate deletion because the Admin SDK bypasses
  rules.
- If deactivation is added, rules must prevent a deactivated account from
  writing, and reads must be filtered or the content deleted.
- Consider App Check for the callable as follow-up hardening (F16).

### 6.7 Observability

- Log step names, counts and durations; never log names, phone numbers, emails
  or media URLs.
- Alert on `failed` job status and on callable errors.
- Record a minimal audit trail (`account_deletions`) without PII.

---

## 7. Deletion inventory (authoritative)

Encode this table in `deletion-manifest.ts` and assert it in tests. Any new
user-owned collection must be added here before release.

| Area | Selector | Action |
|---|---|---|
| Auth identity | Firebase Auth `uid` | Delete **last** |
| User profile tree | `users/{uid}` + `devices`, `settings`, `favourite_designers`, `bookmarked_design_collections`, `pinned_clients` | Recursive delete |
| Closet | `closets/{uid}` + `closet_items`, `outfits`, `outfit_plans` | Recursive delete |
| Trends authored | `trends` where `created_by == uid` + `likes`, `followers`, `comments` | Recursive delete |
| Trend media | `featured_media[].uid` (images and videos) | Cloudinary destroy |
| Likes given | `trends/*/likes` where `uid == uid` | Delete |
| Saves/follows given | `trends/*/followers` where `uid == uid` | Delete |
| Comments authored | `trends/*/comments` where `author.uid == uid` | Delete |
| Notifications received | `notifications` where `to == uid` | Delete |
| Notifications sent | `notifications` where `from == uid` | Delete or anonymise (open question) |
| Reviews authored | `designer_reviews` where `comment.author.uid == uid` | Delete; trigger recalculates designer ratings |
| Feedback authored | `designer_feedback` where `author.uid == uid` | Delete |
| Reviews/feedback about a deleted designer | `designer_reviews` / `designer_feedback` where `ref_id == uid` | Delete |
| Bookings | `bookings` where `user_id == uid` or `designer_id == uid` | Notify counterpart if active, then delete |
| Slot locks | `slot_reservations` where `user_id == uid` or `designer_id == uid` | Delete |
| Work orders authored (designer) | `work_orders` where `created_by == uid` + `status_progress` | Recursive delete |
| Work orders as client | `work_orders` where `client.uid == uid` | Anonymise client snapshot/measurements |
| Client record | `clients/{uid}` + `measurements` | Recursive delete |
| Client links | `client_measurements/{uid}` tree | Recursive delete |
| Designer-owned clients | `clients` where `created_by == uid` + measurements | Delete (business decision) |
| Designer profile | `designers/{uid}` + `availability`, `availability_exceptions` | Recursive delete |
| Design collections | `design_collections` where `created_by == uid` | Delete + Cloudinary images |
| Designer services | `designer_services` where `created_by == uid` | Delete |
| Reference cleanups (optional) | `users/*/favourite_designers/{uid}`, `users/*/bookmarked_design_collections/*`, `users/*/pinned_clients` | Best-effort cleanup; UI must tolerate missing targets |
| Identity media | Cloudinary `{base}/{profile_images}/{uid}`, `{base}/{banner_images}/{uid}`; legacy Storage paths | Destroy |
| Interest counters | `fashion_interests.number_of_posts` | Maintained by trend-delete trigger; verify/reconcile after deletion |

### Counter/aggregate notes

- **Fashion interests:** deleting a trend triggers `onTrendWritten`, which
  decrements each tag count. No manual counter update is required, but the
  integration test should verify the final values.
- **Designer ratings:** deleting an authored review triggers
  `onDesignerReviewWritten`; deleting a designer is handled by the repository's
  missing-designer guard.
- **Like/comment counts:** the app does not maintain these counters in Firestore
  today (demo data only), so no repair step is required.

---

## 8. User flows

### 8.1 Deletion entry and confirmation

1. User opens **Profile → Settings** (or Profile → user profile page).
2. Taps **Delete account** (red, under Account & Privacy).
3. Screen explains:
   - profile, posts/media, likes/comments, closet, notifications will be deleted;
   - active bookings/orders will be cancelled;
   - completed records may be retained only in anonymised form (if that policy is
     chosen);
   - deletion is permanent and cannot be undone;
   - link to the privacy policy.
4. User types `DELETE` (or performs a hold-to-confirm action).
5. Destructive button becomes enabled.

### 8.2 Re-authentication (optional)

- If adopted, reuse the phone OTP primitives to verify ownership without
  navigating through the sign-in flow.
- Refresh the credential, then call `deleteMyAccount`.
- Keep this step self-service; Apple forbids requiring a phone call or email.

### 8.3 Execution and success

- Show a non-dismissible progress state ("Deleting your account…").
- On success:
  - clear `UserBloc` and `AuthProviderCubit`;
  - cancel local notifications;
  - clear Hive service caches and image/disk caches;
  - navigate to `/sign-in` with a confirmation message.
- On failure:
  - show a retryable error with a support contact;
  - keep the user signed in only if the account still exists; otherwise route to
    sign-in and explain that deletion will finish automatically.
- Repeated taps must be impossible (disable the button, guard the call).

### 8.4 Deactivation (optional, deferred)

Only if the product requires it:

- Definition: sign-in suspended, profile/content hidden, reactivation possible by
  signing in within the retention window.
- Requires account-status fields, query filters across feeds/search, Auth
  disable, and a scheduled purge.
- Must be clearly distinct from deletion in Settings.
- **Never** make deactivation the only option.

---

## 9. Backend design

### 9.1 Callable contract

`deleteMyAccount` (`functions/src/account/delete-account.ts`):

- Authenticated callable only; derives the UID from `request.auth.uid`. Never
  accept a UID from the client.
- Request payload (minimal): `{ confirmation: 'DELETE' }` and optional
  `{ reason }`.
- Reject:
  - unauthenticated callers;
  - missing/incorrect confirmation;
  - concurrent deletion already in progress for the same UID.
- Idempotent: if `account_deletions/{uid}.status == completed`, return success.
- Returns a small status object; internal details stay in logs.

### 9.2 Job document / state machine

`account_deletions/{uid}`:

```text
requested -> in_progress -> completed
                         -> failed (retryable)
```

- Written before any destructive work.
- Holds only the UID, timestamps, step names/counters, media ids, and an error
  message.
- On retry, completed steps are skipped.
- Delete or anonymise the job document only after the Auth user is gone; retaining
  a minimal audit record is acceptable if the privacy policy covers it.

### 9.3 Deletion ordering

1. Validate caller and confirmation.
2. Create/resume the job; revoke refresh tokens.
3. Delete interactions on other users' content (likes, follows, comments,
   reviews, feedback).
4. Delete the user's own trends (recursively) and collect media ids.
5. Delete designer content if present (collections, services, availability,
   designer document, reviews about the designer).
6. Delete bookings and slot reservations (notify active counterparts first).
7. Delete work orders authored by the user; anonymise work orders where the user
   is a client.
8. Delete client records and links (`clients/{uid}`, `client_measurements/{uid}`,
   designer-owned clients if the user is a designer).
9. Delete the `users/{uid}` tree, `closets/{uid}` tree, notifications, and
   reference shortcuts.
10. Delete Cloudinary/Storage assets using the collected ids.
11. Delete the Firebase Auth user.
12. Mark the job completed.

Media deletion order is deliberate: collect public ids before removing the
documents that reference them. If media deletion fails, the job remains failed
and retryable rather than silently orphaning assets.

### 9.4 Deletion manifest

- A single exported manifest lists every collection, selector, action and
  subcollection.
- The delete service iterates the manifest.
- A unit test asserts that every Firestore collection referenced by the
  user-facing services appears in the manifest (maintain a checked-in list of
  collection names alongside it).
- New features that add user-owned data must add a manifest entry and a test.

### 9.5 Media cleanup

- Cloudinary Admin API:
  - destroy by public id (`/image/destroy` and `/video/destroy`);
  - optional list/delete by prefix as a safety net;
  - paginate and respect rate limits;
  - use Basic auth with the API key/secret from environment/Secret Manager.
- Collect ids from:
  - user `profile_image` / `banner_image` URLs (derive public id) **or** the
    known public id pattern `{base}/{folder}/{uid}`;
  - trend `featured_media[].uid`;
  - design-collection `featured_images[].uid`;
  - designer profile/banner public ids.
- Legacy Firebase Storage deletion is best-effort; log failures.

### 9.6 Error handling, retries, idempotency

- All operations are idempotent: deleting a missing document is a no-op.
- Batches are committed in chunks; a failed chunk stops the job and is retried.
- A scheduled retry function (or manual re-invoke) resumes from the job state.
- Do not delete the Auth user until all Firestore/media steps succeed.
- Map internal failures to a generic client error; log the real error server-side.

### 9.7 Security

- Caller can only delete their own account (UID from the ID token).
- Rate-limit deletion requests per UID.
- Do not accept collection names, document ids or media ids from the client.
- Use App Check if/when it is added to the project.
- Ensure the function service account has Auth Admin and Firestore Admin
  permissions, and no broader role than required.

---

## 10. Client implementation

### 10.1 Files and responsibilities

| Area | Proposed change |
|---|---|
| Entry | Add rows to `settings_screen.dart` and `user_profile_page.dart` |
| Routing | Add `/settings/delete-account` to `app_router.dart` |
| UI | New `account_deletion_screen.dart` + confirmation dialog/widgets |
| Domain | `AccountRepository` + `DeleteAccountUsecase` |
| Data | `FirebaseAccountService` wrapping the `deleteMyAccount` callable |
| DI | Register the service/usecase in `service_locator.dart` |
| Session cleanup | Extract the `_signOut` cleanup into a shared service used by both flows |

### 10.2 Session cleanup refactor

Move the steps currently in `UserProfilePage._signOut` into a reusable service:

- clear `UserBloc`;
- set `AuthProviderCubit` to the signed-out state;
- `PushNotificationService.onSignOut()` (best effort after deletion);
- `LocalNotificationService.cancelAll()`;
- clear all Hive service caches listed in the current method;
- `DefaultCacheManager().emptyCache()`;
- clear Flutter image caches.

Sign-out behaviour must remain identical after the refactor.

### 10.3 Auth-state race

Because deleting the Auth user changes `FirebaseAuth.userChanges()`, the
profile screen can react before the callable response arrives. Add one of:

- an `AccountDeletionCubit`/service flag checked by the auth listener; or
- a route-level auth gate that ignores `null` while deletion is in progress.

Only one navigation to `/sign-in` should occur, and it must not show an error
snackbar.

### 10.4 Copy

- The entry row must be unmistakable: "Delete account", destructive colour.
- The confirmation screen should explain data categories, cancellation of
  bookings/orders, and the irreversibility.
- Link the privacy policy.
- If a grace period is not offered, say "This cannot be undone."
- Keep the wording aligned with the privacy policy (especially retention).

---

## 11. Deactivation (optional) — decision and cost

**Recommendation: do not implement deactivation in the first release.**

Why:

- Apple requires deletion; deactivation is not a substitute.
- Hiding "deactivated" profiles from every feed, search, booking and designer
  query is cross-cutting and easy to get wrong.
- A misleading deactivation (sign-out only, content still visible) risks another
  review rejection.

If the business later requires it, implement it as a distinct feature:

- `users/{uid}.status = deactivated`, `deactivated_at`, `scheduled_purge_at`.
- Auth user disabled; refresh tokens revoked.
- Every discovery query filters out deactivated accounts.
- Signing in within the grace window offers reactivation.
- A scheduled function purges after the window.
- Settings shows both actions with a clear explanation of the difference.

---

## 12. Implementation phases

### Phase 0 — Policy and decisions (S)

- Approve the retention/anonymisation matrix.
- Draft the privacy-policy section: what is deleted, what is retained, retention
  periods, contact method.
- Prepare App Review notes and a review account/test phone number.

### Phase 1 — Entry points and confirmation UI (S–M)

- Settings row + profile-page link + route.
- Consequence/confirmation screen with typed `DELETE`.
- Privacy-policy link and copy review.

### Phase 2 — Client service and session cleanup (M)

- Callable service + domain usecase + DI.
- Shared session cleanup refactor.
- Auth-state race guard.
- Success/error/retry UX.

### Phase 3 — Server-side cascade core (L–XL)

- `deleteMyAccount` callable with auth check and confirmation.
- Deletion manifest and job state.
- Recursive deletes and paginated/batched operations.
- Auth user deletion last.

### Phase 4 — Media and cross-user cleanup (M)

- Collect and destroy Cloudinary assets.
- Legacy Storage cleanup.
- Cancel/notify active bookings and work orders.
- Anonymise or delete cross-user records per policy.

### Phase 5 — Optional deactivation (L)

- Only if explicitly approved; implement the full hide/reactivate/purge design.

### Phase 6 — Tests, compliance and release (M)

- Unit tests with fakes.
- Firestore emulator integration test.
- Flutter widget/unit tests.
- Privacy policy and App Store Connect updates.
- Deploy indexes and functions; monitor first deletions.

---

## 13. Task breakdown

| ID | Task | Files / areas | Depends on | Size | Acceptance |
|---|---|---|---|---|---|
| A1 | Approve deletion/retention policy | product/legal | — | S | Signed-off matrix and privacy text |
| A2 | Add entry points | `settings_screen.dart`, `user_profile_page.dart`, `app_router.dart` | A1 | S | Visible within two taps; red/destructive styling |
| A3 | Confirmation screen | new `account_deletion_screen.dart` | A2 | M | Typed confirmation; consequences; cancel works |
| A4 | Callable client service/usecase | new account repo/usecase, `service_locator.dart` | A3 | M | Callable called once; errors mapped |
| A5 | Extract session cleanup | shared cleanup service | A4 | S | Sign-out behaviour unchanged |
| B1 | Callable + job state | `functions/src/account/*`, `functions/src/index.ts` | A4 | M | Anonymous call rejected; idempotent |
| B2 | Delete profile/user tree | `users`, `devices`, `settings`, shortcuts | B1 | S | Recursive delete verified |
| B3 | Delete social content | trends, likes, followers, comments, reviews, feedback, notifications | B1 | L | Zero residual docs; counters consistent |
| B4 | Delete commerce/client data | bookings, slot reservations, work orders, clients, links | B1 | L | Active records handled; no PII remains |
| B5 | Delete designer data | designers, availability, services, collections | B1 | M | All designer content gone |
| B6 | Media cleanup | Cloudinary/Storage helpers | B3, B5 | M | Assets destroyed or tracked for retry |
| B7 | Delete Auth identity | Firebase Auth Admin | B2–B6 | S | User cannot sign in; re-signup starts empty |
| B8 | Add indexes | `firestore.indexes.json` | B3 | S | Collection-group queries run |
| C1 | Backend unit tests | `functions/test/account-deletion.test.ts` | B1–B7 | M | Manifest and failure paths covered |
| C2 | Emulator integration test | `functions/test/integration/*` | B1–B7 | M | Seeded accounts fully purged |
| C3 | Flutter tests | `test/settings/*`, usecase tests | A2–A5 | M | Flow, error, retry covered |
| D1 | Privacy policy + review notes | store/docs | A1 | S | Policy URL live; notes explain reviewer steps |
| D2 | QA matrix | manual | C1–C3 | M | Client/designer/mixed accounts pass |
| D3 | Monitoring and alerts | Cloud Functions logs | B1 | S | Failures alert; counts logged |
| E1 | Optional deactivation | auth/rules/queries | A1 | L | Reactivation and purge behave as specified |

**Estimate:** core compliant deletion ≈ 8–12 developer days; add 3–5 days for
media/cross-user edge cases and 4–6 days if deactivation is included.

---

## 14. Dependencies

- `firebase-admin` and Cloud Functions v2 in `functions/package.json`.
- Firebase Auth Admin permissions for the function service account.
- Cloudinary Admin API credentials (`CLOUDINARY_API_SECRET` secret plus
  `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` environment).
- `firebase deploy --only firestore:indexes`.
- Existing `go_router`, `get_it`, `flutter_bloc`, Hive and cache-manager setup.
- Privacy-policy hosting and App Store Connect access.
- Firebase test phone number / review account.

---

## 15. Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Incomplete deletion (missed collection/subcollection) | High — legal/review rejection | Medium | Deletion manifest; integration test enumerating collections; post-delete assertions |
| Cloudinary orphaning | Medium — privacy/storage cost | Medium | Collect ids before deleting docs; job document + retry; optional prefix sweep |
| Callable timeout on large accounts | High — incomplete deletion | Low–Medium | `recursiveDelete`, bulk writer, paginated queries, 540s timeout, resumable job |
| Cross-user business records lost | Medium — support/legal complaints | Medium | Retention policy; notify counterpart; anonymise instead of delete where required |
| Auth deletion races client UI | Medium — error screen during delete | High | Deletion-in-progress flag; central auth gate; clear local state before navigation |
| Reviewer cannot pass phone OTP | High — review rejection | Medium | Firebase test phone number + review notes + demo account |
| Deactivation mistaken for deletion | High — review rejection | Medium | Ship deletion first; label deactivation clearly; never the only option |
| Analytics/logs retain data | Medium — policy mismatch | Medium | Configure retention; disclose; never log PII |
| Abuse / deleting another account | High — data loss | Low | UID derived from `request.auth`; no client-supplied ids; rate limit |
| Aggregate counters/ratings drift | Medium — wrong numbers | Low | Existing triggers; run reconcile/verify in integration tests |

---

## 16. Acceptance criteria

- A signed-in user can find "Delete account" in Settings within two taps.
- The flow explains consequences, links the privacy policy, and requires explicit
  confirmation.
- Anonymous calls are rejected; a caller can only delete their own account.
- After deletion:
  - `users/{uid}` and its subcollections do not exist;
  - authored trends, likes, follows, comments, reviews and feedback are gone;
  - notifications to/from the user are deleted or anonymised per policy;
  - bookings, slot reservations, work orders, clients and
    `client_measurements` contain no personal data for the user;
  - designer records/content are gone if the account was a designer;
  - Cloudinary/Storage media is destroyed or queued for retry;
  - the Firebase Auth user no longer exists;
  - fashion-interest counts and designer ratings remain consistent.
- Signing in again with the same phone number creates a fresh, empty account.
- A repeated or concurrent deletion completes idempotently.
- A simulated mid-way failure can be retried without duplication/corruption.
- Existing sign-out behaviour is unchanged.
- `flutter analyze` is clean for changed files; backend unit/integration tests
  pass.
- Privacy policy and App Store review notes are updated; review can test deletion.

---

## 17. Definition of Done

- All acceptance criteria pass for client, designer and mixed accounts.
- The deletion manifest and integration test cover every user-owned collection
  and subcollection.
- The callable is deployed with secrets, timeout and monitoring.
- Firestore indexes are deployed.
- Privacy policy is live and consistent with actual retention.
- App Store Connect review notes include the deletion path and reviewer test
  credentials.
- No new analyzer errors and no regressions in the existing test suite.

---

## 18. Recommendations

1. **Ship deletion, not deactivation, for the App Review submission.**
2. **Do the cascade server-side.** Client-side deletion cannot touch bookings,
   notifications, other users' records or Cloudinary.
3. **Use a deletion manifest + job document.** This is the strongest safeguard
   against missing a future collection.
4. **Make the job idempotent and resumable.** Record completed steps and media
   ids so a failure does not strand a half-deleted account.
5. **Notify the counterpart before cancelling active bookings/orders.**
6. **Prefer deleting authored content and reviews**; anonymise only where
   retention is legally required.
7. **Add OTP re-authentication as a hardening step** after the basic flow ships.
8. **Test the reviewer journey explicitly.** App Review cannot receive SMS;
   configure a Firebase test phone number and include exact steps.

---

## 19. App Store review checklist

- Privacy policy URL is live and includes an account-deletion section.
- App Store Connect privacy answers match the actual data collected and deleted.
- The deletion option is visible in the app, not hidden behind support.
- The flow works with the reviewer's demo account / Firebase test phone number.
- Review notes explain:
  - where to find the deletion option;
  - the exact tap path;
  - the reviewer account credentials and OTP handling;
  - what happens to active bookings/orders;
  - any retained/anonymised records and why.
- A screenshot of the deletion entry point and confirmation screen is available
  if requested.

---

## 20. Test plan / matrix

| Account type | Seed data | Verify |
|---|---|---|
| Client only | profile, closet, likes/follows/comments, notifications, booking | All gone; designer's client record removed; booking cancelled |
| Designer only | designer profile, availability, services, collections + images, client records, reviews, bookings/orders | All designer content/media gone; ratings reviewed; client PII removed |
| Mixed | both sets plus trends/media | Full cascade; counters/ratings consistent |
| Large account | many trends/comments/media | Timeout/retry path; job resumes; no duplicates |
| Failure injection | media delete fails after Firestore delete | Job marked failed; retry destroys media; Auth user not deleted until success |
| Security | anonymous call; forged UID payload | Rejected; only caller's account affected |
| Client race | Auth user deleted while UI is mounted | Single clean redirect to sign-in; no profile fetch/error |
| Idempotency | double tap / concurrent calls | One deletion, both return success |

### Test files to add when implementation starts

- `functions/test/account-deletion.test.ts` — manifest, ordering, partial failure,
  idempotency, ownership checks (fakes, mirroring `functions/test/trends.test.ts`).
- `functions/test/integration/account-deletion.test.ts` — emulator + seeded
  Firestore.
- `test/settings/account_deletion_screen_test.dart` — entry, confirmation,
  progress, error/retry.
- `test/domain/delete_account_usecase_test.dart` — callable mapping and errors.

# Plan — Push Notifications (FCM + Cloud Functions)

| | |
|---|---|
| **Status** | Plan — approved for implementation, no code written yet |
| **Created** | 2026-11-04 |
| **Module** | FCM device registration, foreground/background/tap handling, notification routing, inbox completion, Cloud Functions delivery, business-event triggers |
| **Spec source** | "Implement Push Notifications for Fashionista (Flutter + Firebase Cloud Messaging)" (814 lines) |
| **Constraint** | Pushes must be sent from Cloud Functions with the Admin SDK only. Flutter handles registration, reception, presentation and navigation. |

---

## 1. Executive Summary

Add real push delivery (FCM) and a trusted server-side sender (Cloud Functions) on top of the
**in-app notification system that already exists in this repo**. This is not a greenfield
feature: Fashionista already has a notification model, Firestore collection, service, cache,
bloc, inbox screen and four client-side writers. The plan extends those and adds only what is
genuinely missing (Functions project, `firebase_messaging`, device registry, foreground
presentation, routing, badge).

### Three findings that change the shape of the work

| # | Finding | Consequence |
|---|---|---|
| **F1** | **No Cloud Functions project exists.** No `functions/` directory, no `functions` key in [firebase.json](../../firebase.json), no Node tooling anywhere. | Phase 5 is net-new infrastructure, not "extend existing functions". Requires the **Blaze** plan and Firebase CLI access to `fashionista-2025`. |
| **F2** | **The notification collection is a top-level `notifications`, not `users/{uid}/notifications`.** Spec §5.2 proposes a subcollection; the app queries `notifications where to == uid orderBy created_at desc`. | Adapt the spec to the existing schema. Creating a subcollection would fork history and break the inbox, badge and four existing writers. |
| **F3** | **`firestore.rules` is a partial overlay.** It was added recently for the booking module and does not contain rules for any other collection. | Rules work is a *merge* task, not an append. Highest-risk item in the plan (R1). |

---

## 2. Objectives

1. Register every device against the signed-in user, supporting multiple devices and account switching.
2. Receive FCM pushes on Android and iOS in foreground, background and terminated states.
3. Present foreground pushes as local notifications.
4. Route a tap to the correct screen via one central resolver.
5. Keep the existing inbox working and add unread badge, mark-one-read and mark-all-read.
6. Send pushes **only** from Cloud Functions, on meaningful business transitions.
7. Survive invalid/rotated tokens, denied permissions and duplicate trigger executions.

---

## 3. Scope

### In Scope

- `firebase_messaging` (new) + reuse of existing `flutter_local_notifications`.
- Device registration under `users/{uid}/devices/{deviceId}`.
- Central `PushNotificationService` (permission, token, refresh, foreground, taps, cold start).
- Central `NotificationRouter` (payload → route).
- Extending the existing `notifications` documents with the fields the inbox needs for
  read-state, plus Functions-created records.
- Cloud Functions (TypeScript, gen2): reusable dispatcher + triggers for bookings, work orders,
  measurements.
- Security rules for devices + notifications; indexes.
- Tests: Dart unit + Functions unit (Jest), emulator integration.

### Out of Scope

- Notification preferences **UI** (model + server-side check only, per spec §11).
- Appointment reminders (needs a scheduler; schedule-ready design only — see Q6).
- Migrating the other three client-side inbox writers to Functions in V1 (see Q2).
- Replacing `NotificationBloc` with a new state-management pattern.
- Web/React project.

---

## 4. Assumptions

| # | Assumption | Evidence |
|---|---|---|
| A1 | `designerId` = Firebase Auth uid = `designers/{uid}` doc id. | existing booking module |
| A2 | A booking's `user_id` is always a real auth uid → appointments can always notify. | [booking_model.dart](../../lib/data/models/bookings/booking_model.dart) |
| A3 | Work-order `client` is an `AuthorModel` that **may not** be linked to an account → recipient resolution can fail legitimately. | [work_order_model.dart](../../lib/data/models/work_order/work_order_model.dart) |
| A4 | Client↔user linkage lives at `client_measurements/{userId}/clients/{clientId}` with `designer_id`. | [firebase_clients_service.dart](../../lib/data/services/firebase/firebase_clients_service.dart) |
| A5 | `notifications.status` is `'new'` / `'read'` (not `isRead`). | [notification_model.dart](../../lib/data/models/notification/notification_model.dart) |
| A6 | `notifications.created_at` is **int epoch millis**, consumed by `formatRelativeTime`. | [notification_screen.dart](../../lib/presentation/screens/notification/notification_screen.dart) |
| A7 | `firebase_messaging` is **not** installed, not even transitively. | `pubspec.lock` |
| A8 | Local notifications are already initialised at startup and Android desugaring is configured. | [main.dart](../../lib/main.dart), `android/app/build.gradle.kts` |
| A9 | iOS push capability exists: `aps-environment` entitlement + `remote-notification` background mode + `FirebaseAppDelegateProxyEnabled`. | `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist` |

---

## 5. Open Questions

| # | Question | Blocks | Recommended |
|---|---|---|---|
| **Q1** | Is the `fashionista-2025` project on **Blaze**? Gen2 Functions cannot deploy on Spark. | Phase 5 | Confirm before Phase 1; if not, phases 1–4 still ship (device registration + inbox + local presentation) with pushes disabled. |
| **Q2** | The app writes inbox notifications from Flutter in 4 places (`add_client`, `work_order_request`, `work_order_timeline`, `trend_details`). Spec §18.4 forbids client→user notifications. Migrate all now, or keep and only move bookings? | Phase 6 | **Keep legacy writes in V1**, migrate bookings only (they're the newest and already triggered). Migrating all four is a follow-up; each needs its own trigger + idempotency test. |
| **Q3** | `notifications.created_at` is int epoch; spec says server Timestamp. Change the model? | Phase 5 | **Keep int.** Changing it breaks `formatRelativeTime`, Hive adapters and the four writers for zero user benefit. Functions write `Date.now()`. Document the divergence. |
| **Q4** | Should the inbox read the top-level collection (current) or the spec's subcollection? | Phase 3 | **Top-level**, per F2. |
| **Q5** | APNs auth key: is it uploaded to the Firebase console for `fashionista-2025`? | iOS testing | Verify manually; document as a blocking manual step. |
| **Q6** | Appointment reminders: scheduled Cloud Function now or later? | Phase 6 | **Later.** Requires timezone-aware windowing and duplicate guards; design the dispatcher so it's a drop-in trigger. |
| **Q7** | Who can read `users/{uid}/devices`? Designers never need it. | Phase 7 | Owner only. Functions read via Admin SDK (bypasses rules). |
| **Q8** | Does the repo get a `functions/` Node toolchain (commit `package-lock.json`, `node_modules` ignored)? | Phase 5 | Yes — commit lockfile, ignore `node_modules`. |

---

## 6. Architecture Impact

### 6.1 What exists today (reuse map)

| Concern | Existing | Action |
|---|---|---|
| Notification model | [notification_model.dart](../../lib/data/models/notification/notification_model.dart) — `uid, ref_id, ref_type, title, description, type, author, created_at(int), status('new'/'read'), from, to` + Hive type | **Extend** with optional `event`, `read_at`, `data` (add Hive indices 11–13) |
| Firestore collection | top-level `notifications`, queried `where('to' == uid).orderBy('created_at', desc)` | **Reuse** |
| Service | [firebase_notification_service.dart](../../lib/data/services/firebase/firebase_notification_service.dart) (create/update/delete/find/count) | **Extend** with `markAllRead`, paginated fetch |
| Cache | [hive_notification_service.dart](../../lib/data/services/hive/hive_notification_service.dart) + `notificationsBox` | **Reuse** |
| Bloc | [notification_bloc.dart](../../lib/data/models/notification/bloc/notification_bloc.dart) (10 events, `notificationCount` in state) | **Extend** with mark-all-read + unread-count refresh |
| Inbox UI | [notification_screen.dart](../../lib/presentation/screens/notification/notification_screen.dart) + `NotificationTileCard`, `NotificationIconCluster`, `NotificationTitleRow`, `NotificationCardButton`, per-type widgets (`booking`, `workOrderRequest`, `work_order_status_progress`, default) | **Extend** with `appointment` widgets and badge |
| Local notifications | [local_notification_service.dart](../../lib/core/service_locator/local_notification_service.dart) (init + outfit schedule) | **Extend**: channels, payload tap, cold-start, foreground display. Note: `init()` currently requests **camera** permission — fix as part of this work (tightly coupled) |
| Auth | `AuthProviderCubit` (hydrated), `SignOutUsecase`, no central `authStateChanges` listener | **Add** a device-lifecycle listener in the new service |
| Router | global `appRouter` (go_router), mounted in [app_starter.dart](../../lib/app_starter.dart) | **Reuse**; resolver maps payload → existing paths |
| Settings | `Settings` model = display mode / autoplay / image quality only | **Add** a separate `users/{uid}/settings/notifications` doc (per spec §11), not this model |

Existing routes the resolver must use — **no new routes required**:

| Event | Route |
|---|---|
| Booking (designer) | `/designer-bookings?designerId=<uid>` |
| Booking (client) | `/my-bookings` |
| Work order | `/workorders/details/:id` |
| Measurement | `/my-measurement` |
| Unknown / missing id | `/notifications` |

### 6.2 Firestore shapes

**A. `users/{uid}/devices/{deviceId}`** — `deviceId` = locally generated UUID v4 persisted in
`shared_preferences` (stable across restarts, survives token rotation).

```json
{
  "fcm_token": "...",
  "platform": "android|ios",
  "device_name": "Samsung Galaxy S24",
  "is_active": true,
  "app_version": "1.0.0+1",
  "created_at": "Timestamp",
  "updated_at": "Timestamp",
  "last_seen_at": "Timestamp"
}
```

**B. `notifications/{id}`** — existing shape, plus:

```json
{
  "...": "existing fields unchanged",
  "event": "appointment_confirmed",
  "read_at": "Timestamp|null",
  "data": { "booking_id": "...", "designer_id": "...", "user_id": "..." }
}
```

`type` stays the **widget selector** (`booking`, `work_order_status_progress`, `info`, …) so
`NotificationScreen`'s switch keeps working; `event` carries the spec's `appointment_*` /
`order_*` vocabulary.

**C. `users/{uid}/settings/notifications`** —
`appointments`, `orders`, `measurements`, `reminders`, `updated_at`.

### 6.3 Code layout (adapting spec §6 to this repo — **not** `lib/features/`)

```
lib/core/service_locator/push_notification_service.dart      # init, token, lifecycle
lib/core/notifications/notification_router.dart              # pure resolve() + navigate()
lib/core/models/hive/notification_model_hive_type.dart       # +3 indices
lib/data/models/notification/notification_model.dart         # +event/read_at/data
lib/data/models/notification/device_registration_model.dart  # NEW
lib/data/models/notification/notification_payload.dart       # NEW (parsed FCM data)
lib/data/services/firebase/firebase_notification_service.dart# +markAllRead, pagination
lib/data/services/firebase/firebase_device_service.dart      # NEW
lib/data/models/notification/bloc/*                          # +mark-all-read events
lib/presentation/screens/notification/notification_screen.dart
lib/presentation/screens/notification/widgets/notification_appointment_status_widget.dart  # NEW
lib/presentation/widgets/notification_badge.dart             # NEW
functions/                                                   # NEW (TypeScript, gen2)
  src/index.ts
  src/notifications/{types,service,repository,dispatcher,helpers}.ts
  src/triggers/{booking,work-order,measurement}.triggers.ts
  test/*.test.ts
firestore.rules  (merge, not append)
firestore.indexes.json
firebase.json    (+ "functions")
.firebaserc      (NEW)
```

### 6.4 Infrastructure

- `firebase.json` gains `functions.source = "functions"` and an `emulators` block
  (functions 5001, firestore 8080).
- Functions runtime: **Node 20**, TypeScript, `firebase-functions` v5 (gen2).
- Android: no manifest permission work needed (`POST_NOTIFICATIONS`, FCM default icon meta-data
  and the local-notification receivers are already present). Only the plugin dependency is
  missing.
- iOS: entitlements/background modes already correct; APNs key upload is manual (Q5).

---

## 7. Implementation Plan

### Phase 0 — Decisions & guardrails

Confirm Blaze (Q1), merge the rules file with the console set, add emulator config, create
`.firebaserc`.

### Phase 1 — Dependencies & initialisation

`firebase_messaging`; extend `LocalNotificationService` (channels, tap, cold start, foreground)
and fix the camera-permission bug; `PushNotificationService` with idempotent `initialize()`.

### Phase 2 — Device registration

Model, `FirebaseDeviceService`, `users/{uid}/devices` rules, auth-lifecycle hook (sign-in /
token refresh / sign-out / account switch).

### Phase 3 — Inbox completion

Additive fields to `NotificationModel` (Hive 11–13), mark-all-read, pagination, unread badge on
the home bell (currently a static dot), states for loading/empty/error.

### Phase 4 — Handling & routing

Background handler (top-level, `@pragma('vm:entry-point')`), foreground local display,
`onMessageOpenedApp`, `getInitialMessage`, pure `NotificationRouter.resolve()` with
duplicate-tap guard.

### Phase 5 — Cloud Functions

Dispatcher, deterministic notification ids, multicast send, invalid-token cleanup, preferences
gate, logging.

### Phase 6 — Business events

Bookings (create + status transitions with actor), work orders (respect the existing
`notify_client` flag), measurements (linked users only).

### Phase 7 — Security, indexes, tests, devices

Rules merge, indexes, Dart + Functions tests, emulator run, physical device matrix.

---

## 8. Task Breakdown

Sizes: **S** ≤ 4 h · **M** 4–8 h · **L** 1–3 d · **XL** > 3 d.

### Phase 0 — Foundations

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P0.1 | Confirm Blaze + CLI access to `fashionista-2025`; add `.firebaserc` | root | — | S | `firebase projects:list` succeeds |
| P0.2 | Merge `firestore.rules` into a complete rule set (console export + repo file) | `firestore.rules` | — | L | ✅ Complete — 342-line self-contained rule set, verified 30/30 against the emulator (§16) |
| P0.3 | Add emulator config to `firebase.json` | `firebase.json` | P0.1 | S | `firebase emulators:start` boots |

### Phase 1 — Dependencies & initialisation

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P1.1 | Add `firebase_messaging` at a version compatible with `firebase_core 4.x` / Dart 3.8 | `pubspec.yaml` | — | S | `flutter pub get` + `flutter analyze` clean; iOS pods install |
| P1.2 | Extend `LocalNotificationService`: named channels, `onDidReceiveNotificationResponse`, `getNotificationAppLaunchDetails`, foreground `show()`, remove the camera permission request | `local_notification_service.dart` | P1.1 | M | Foreground push shows a banner; tapping it reaches the router; outfit reminders still fire |
| P1.3 | `PushNotificationService`: idempotent init, permission request (non-blocking), token fetch, `onTokenRefresh`, `onMessage`, `onMessageOpenedApp`, `getInitialMessage`, all wired to a callback | new service + `service_locator.dart` + `main.dart` | P1.2 | L | Init twice → listeners registered once; denial does not block startup |

### Phase 2 — Device registration

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P2.1 | `DeviceRegistration` model + `FirebaseDeviceService` (upsert by stable deviceId, deactivate, dedupe token) | new model/service | P1.3 | M | Re-registering the same device updates one doc; a rotated token replaces the old one |
| P2.2 | Auth lifecycle hook: register on sign-in, update on refresh, deactivate on sign-out, re-register on account switch | service + `user_profile_page` sign-out path | P2.1 | L | Sign out → device `is_active:false`; sign in as B → same deviceId doc under B; A's devices untouched |
| P2.3 | Rules for `users/{uid}/devices` | `firestore.rules` | P2.1, P0.2 | S | Owner-only read/write; cross-user write denied |

### Phase 3 — Inbox

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P3.1 | Add `event`, `read_at`, `data` to `NotificationModel` + Hive indices 11–13; regenerate | model + hive type | — | M | Old cached payloads still deserialize (all new fields nullable) |
| P3.2 | `markAllRead`, paginated fetch (20/page), unread count in `NotificationBloc` | service + bloc | P3.1 | M | Mark-all → `status:'read'` for all `to == uid` |
| P3.3 | Unread badge on the home bell, `99+` cap, hidden at 0 | `notification_badge.dart`, `home_screen.dart` | P3.2 | S | Badge tracks the bloc count; no extra listeners |
| P3.4 | Inbox polish: loading/empty/error/pull-to-refresh + `mark all as read` action | `notification_screen.dart` | P3.2 | M | All four states render; existing per-type widgets unchanged |

### Phase 4 — Handling & routing

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P4.1 | Background handler (top-level, `@pragma('vm:entry-point')`, its own `Firebase.initializeApp`) | `push_notification_service.dart`, `main.dart` | P1.3 | M | Background/terminated push does not crash; no UI work in the isolate |
| P4.2 | Pure `NotificationRouter.resolve(Map data)` → route string + duplicate-tap guard + "router ready" deferral | new `notification_router.dart` | — | M | Unit-tested for every type, missing ids, unknown type → `/notifications` |
| P4.3 | Wire all three tap entry points into the router | service + `app_starter` | P4.2 | M | Tap from foreground, background and cold start lands on the right screen exactly once |

### Phase 5 — Cloud Functions

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P5.1 | Scaffold `functions/` (TS, Node 20, gen2, jest) + `firebase.json`/`.firebaserc` wiring | `functions/*` | P0.1 | M | `npm run build` + `firebase deploy --only functions --dry-run` succeed |
| P5.2 | `notification.types.ts` + `helpers.ts` (deterministic id, transition detection, preference gate) | functions | P5.1 | M | Pure functions unit-tested |
| P5.3 | `notification.repository.ts`: recipients, active devices, history write, token cleanup | functions | P5.2 | M | Admin SDK only; no credentials in Flutter |
| P5.4 | `notification.dispatcher.ts`: multicast ≤500/token batch, partial-failure classification, invalid-token deactivation | functions | P5.3 | L | Per-token failures logged without tokens; `messaging/invalid-registration-token` deactivates |
| P5.5 | Idempotency: deterministic doc id + transaction create-or-skip | functions | P5.3 | M | Same event replayed twice → one history doc, one send |

### Phase 6 — Business events

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P6.1 | Booking triggers: created → designer; status transitions → the other party, using an actor field | functions + `firebase_booking_service.dart` (`last_status_actor`), remove the client-side booking inbox write | P5.5 | L | No notification when the actor is the recipient; unrelated updates ignored |
| P6.2 | Work-order triggers: created → designer; status change / `status_progress` with `notify_client == true` → linked client | functions | P5.5 | L | Respects `notify_client`; unlinked client → no send, logged |
| P6.3 | ~~Measurement trigger: designer updates → linked user only; no values in the body~~ | functions | P5.5, Q2 | M | **Removed 2026-11-06** — `measurementWritten` deleted on request (see note below) |
| P6.4 | Preference gate (`users/{uid}/settings/notifications`, default enabled) | functions | P5.4 | S | Disabled category → history skipped |
| P6.5 | Client→user resolution helper (`collectionGroup('clients')` on `client_id`) + index | functions + indexes | P6.2 | M | Resolves booking/work-order client to auth uid |

> **P6.3 removed (2026-11-06).** The `measurementWritten` function
> (`clients/{clientId}/measurements/{measurementId}`) and its handler file were deleted.
> Left in place for backwards compatibility with already-stored inbox records:
> `NotificationType: 'measurement'`, the `measurements` preference key, the
> `/my-measurement` route case in `NotificationRouter`, and
> `NotificationRepository.resolveUserIdForClient` (still used by the work-order triggers).
> No trigger now emits measurement notifications.

### Phase 7 — Security, tests, devices

| ID | Task | Deps | Size | Acceptance |
|---|---|---|---|---|
| P7.1 | Rules: notifications read/update for recipient only; preserve legacy create clause | P0.2 | M | ✅ Recipient-only read, `status`/`read_at`-only update, `from` must be the caller (§16.3) |
| P7.2 | Indexes: `notifications(to, created_at desc)`, collection-group `clients(client_id)`, devices none | P6.5 | S | Every query runs without `failed-precondition` |
| P7.3 | Dart tests: model round-trip, payload parsing, router resolution, unread count | P3–P4 | M | All green under `flutter test` |
| P7.4 | Functions tests: builder, recipient resolution, token cleanup, partial failure, idempotency, suppression, transition detection | P5–P6 | L | All green under `npm test` |
| P7.5 | Emulator integration (booking → notification doc → device query) | P7.4 | M | Documented run output |
| P7.6 | Physical device matrix: 10 scenarios from spec §16 | all | L | Results recorded; iOS production push verified |

---

## 9. Dependencies

**Internal:** booking module (done) → P6.1; work-order model + `notify_client` → P6.2; client
linkage → P6.5; router → P4.2; `NotificationBloc` → P3.

**External:** Firebase Blaze plan, Firebase CLI + deploy rights, APNs auth key in console,
`firebase_messaging` pub version, `firebase-functions` v5 + Admin SDK.

**Operational:** Physical Android + iOS devices for the acceptance matrix. Emulator success is
explicitly *not* proof of delivery (spec §16).

---

## 10. Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| **R1** | **Rules overlay accident** (F3): deploying the current partial `firestore.rules` silently denies every other collection. | **Critical outage** | **High** | P0.2 blocks all deploys until the file is a complete rule set. Verify with `--dry-run` and a read test per collection. |
| **R2** | Duplicate notifications: booking creation writes an inbox doc client-side *and* a Function does. | High (user-visible spam) | **High** | P6.1 removes the client write in the same change that adds the trigger; idempotent deterministic id as a second guard. |
| **R3** | No Functions project / Spark plan → Phase 5 blocked after Phases 1–4 already merged. | High | Medium | Q1 answered before Phase 1; phases 1–4 deliver value without Functions. |
| **R4** | APNs key missing → iOS pushes silently never arrive (FCM returns success). | High | Medium | Q5 verification gate; test on a real iOS device before claiming iOS support. |
| **R5** | Duplicate taps: same push delivered via `onMessageOpenedApp` and `getInitialMessage` on cold start. | Medium | High | Router duplicate guard keyed on notification id + 2s window (P4.2). |
| **R6** | Background isolate lacks plugins (`shared_preferences`, Hive) → crash on background push. | Medium | Medium | Background handler touches Firebase only (P4.1). |
| **R7** | Client→user resolution needs a collection-group index; missing index = silent no-notification. | Medium | High | P6.5 ships the index with the trigger; emulator + real query check. |
| **R8** | `created_at` int vs Timestamp drift between Functions and the app. | Low | Medium | Q3 decision documented in the model; Functions write millis. |
| **R9** | Hive back-compat: new required fields break cached notifications. | Medium | Medium | All three new fields nullable with defaults; test against a pre-existing box. |
| **R10** | `firebase_messaging` version conflicts with `firebase_core 4.x`. | Medium | Low | P1.1 resolves versions first and runs a build before any logic lands. |
| **R11** | Token leakage in logs. | Medium (privacy) | Medium | Redact tokens to a hash prefix in all logs (P5.4). |
| **R12** | Notifications sent for trivial updates (spec §18.8). | Medium | Medium | Transition allow-list per event, unit-tested for "no notify on unrelated update". |

---

## 11. Acceptance Criteria

1. Signing in registers exactly one device doc per device; signing out sets `is_active: false`.
2. Signing in as a second user on the same device registers under B and leaves A's devices intact.
3. A token refresh updates the existing device doc; the old token stops receiving.
4. Foreground push shows a local notification with title/body and routes on tap.
5. Background and terminated pushes are delivered and route on tap.
6. A cold-start tap navigates after the router is ready, exactly once.
7. Inbox shows recipient-only notifications with read/unread state; mark-one and mark-all persist.
8. Unread badge reflects the count, caps at `99+`, hides at zero.
9. Creating a booking produces exactly one history doc and one push to the designer — replaying
   the trigger produces none.
10. Designer confirming/declining notifies the client; the actor never notifies themselves.
11. Work-order status change notifies the linked client only when `notify_client == true`.
12. ~~Measurement update notifies only linked users and never includes values in the body.~~ (removed 2026-11-06, see P6.3)
13. Invalid tokens are deactivated and do not block delivery to valid devices.
14. A user cannot read/modify another user's devices or notifications (verified against deployed
    rules).
15. `flutter analyze` clean for touched files; all Dart and Functions tests pass.

---

## 12. Definition of Done

- All acceptance criteria verified on real Android **and** iOS hardware.
- Rules file is a **complete** set and deployed; deploy verified as non-breaking for all existing
  collections.
- Indexes deployed; no `failed-precondition` in logs.
- Dart tests + Functions tests green; emulator run documented.
- Deliverables §19 of the spec produced (architecture, file lists, collections, rule/index diffs,
  Android/iOS changes, env vars, deploy + run commands, test results, manual steps, limitations).
- Explicitly stated in the write-up: **push is not "operational" until APNs + Functions are
  verified on device.**

---

## 13. Recommendations

1. **Merge rules before writing any notification code.** R1 is the only risk that can take the app
   down for real users; everything else is additive.
2. **Do not migrate the four legacy client-side writers in V1.** Each needs its own trigger,
   recipient resolution and idempotency test; bundling them triples the blast radius. Migrate
   bookings only and track the rest.
3. **Keep `type` as the widget selector and add `event`** rather than repurposing `type`.
   `NotificationScreen`'s switch and the existing per-type widgets keep working untouched.
4. **Make the dispatcher event-agnostic from day one**
   (`NotificationPayload{recipient,title,body,type,event,data}`), so reminders (Q6) and future
   order events are one trigger file each, not new plumbing.
5. **Add `last_status_actor` to bookings.** Without it, "booking cancelled → notify other party"
   is guesswork in the trigger.
6. **Denormalise `user_id` on the client document** at link time instead of relying on a
   collection-group query — cheaper, index-free, and makes `P6.5` trivial. Optional if you'd
   rather not touch `linkClientToUser`.
7. **Fix `LocalNotificationService.init()`'s camera permission** as part of P1.2 — it is a genuine
   bug that will confuse the permission flow you're about to build.
8. **Keep tokens out of logs** from the first commit; retrofitting redaction after an incident is
   worse.

---

## 14. Command Reference

```bash
# Flutter
flutter pub get
flutter analyze
flutter test test/notifications/
flutter run

# Firebase
firebase login
firebase use fashionista-2025
firebase emulators:start --only functions,firestore

# Functions
cd functions && npm install
npm run build
npm test
firebase deploy --only functions
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 15. Implementation Status (2026-11-04)

Phases 0–7 implemented at the code level. Everything that can be verified without
Firebase project access, the Blaze plan or physical devices has been verified.

### Files created

```
functions/package.json, tsconfig.json, jest.config.js, .eslintrc.json, .gitignore
functions/src/index.ts
functions/src/notifications/{types,helpers,repository,dispatcher}.ts
functions/src/triggers/{booking,work-order,measurement}.triggers.ts
functions/test/{helpers,dispatcher}.test.ts
.firebaserc
lib/core/notifications/notification_router.dart
lib/core/notifications/notification_navigator.dart
lib/core/service_locator/push_notification_service.dart
lib/data/models/notification/notification_payload.dart
lib/data/models/notification/device_registration_model.dart (+ .g.dart)
lib/data/services/firebase/firebase_device_service.dart
lib/presentation/widgets/notification_badge.dart
test/notifications/notification_router_test.dart
test/notifications/notification_model_test.dart
```

### Files modified

| File | Change |
|---|---|
| `pubspec.yaml` | `firebase_messaging ^16.7.1` |
| `lib/core/service_locator/local_notification_service.dart` | channels, tap stream, cold-start payload, foreground `show()`, removed the camera permission request |
| `lib/data/models/notification/notification_model.dart` | `event`, `read_at`, `data` (+ Hive indices 11–13) |
| `lib/data/services/firebase/firebase_notification_service.dart` | awaited update, `getUnreadCount`, batched `markAllAsRead`, `findNotificationsPage`, bounded inbox query |
| `lib/data/models/notification/bloc/*` | `LoadNotificationsPage`, `MarkAllNotificationsRead`, unread count, `hasMore` |
| `lib/presentation/screens/notification/notification_screen.dart` | one batched mark-all-read |
| `lib/presentation/screens/home/home_screen.dart` | count badge instead of a dot |
| `lib/main.dart` | background handler registration + non-blocking push init |
| `lib/app_starter.dart` | router-ready signal for cold-start taps |
| `lib/presentation/screens/profile/user_profile_page.dart` | deactivate device before sign-out |
| `lib/data/models/bookings/booking_notification.dart` | `event` + routing `data` |
| `lib/data/services/firebase/firebase_booking_service.dart` | writes `last_status_actor` |
| `firestore.rules` | notification read/update, devices, delivery markers, preferences |
| `firestore.indexes.json` | notifications, devices, collection-group clients |
| `firebase.json`, `.firebaserc` | functions + emulators config |
| `android/app/src/main/AndroidManifest.xml` | default notification channel id |

### Verified

- `flutter analyze` → only the pre-existing `test/client_measurement_firestore_test.dart:88`
  error; **zero warnings** project-wide.
- `flutter test test/notifications/ test/bookings/ test/scheduling/` → **94 tests pass**
  (25 notification model/payload/router + 69 booking/scheduling).
- `cd functions && npm run build` → clean TypeScript compile.
- `cd functions && npm test` → **22 tests pass** (helpers + dispatcher: idempotency,
  preference suppression, invalid-token cleanup, batch limits, partial failure).

- `firebase emulators:start --only firestore` → rules compile, then a 30-check auth matrix
  against the emulator with three unsigned JWTs (`u1` client, `u2` unrelated user, `d1`
  designer) → **30/30 pass**. See §16.

### Not verified (blocked in this environment)

1. **Rules deploy** — the file is now complete (§16) but `firebase deploy --only
   firestore:rules,firestore:indexes` has not been run (no authenticated CLI session).
2. **Functions deploy** — requires the Blaze plan (Q1). `firebase.json` and `.firebaserc` are
   ready.
3. **Real push delivery** — requires APNs key upload (Q5) and physical devices.
4. **Emulator run** — `firebase emulators:start` needs the project/CLI session.
5. **Android APK build** — blocked by pre-existing toolchain state, unrelated to this module:
   the wrapper is Gradle 8.12 while the installed Flutter requires ≥ 8.14, and after bypassing
   that check the build stops on `platforms;android-37` missing for `sms_autofill`. Both failures
   reproduce without any notification code.

### Deviations from the plan

| Item | Deviation | Reason |
|---|---|---|
| P3.2 pagination | Service method `findNotificationsPage` exists and is used by the bloc, but the inbox screen still renders from the Hive cache with a bounded 100-item network fetch. | The screen is `ValueListenableBuilder`-based; converting it to paged bloc state is a separate refactor with no behavioural gain at current volumes. |
| P6.1 client write | The client-side booking inbox write is **kept**; the dispatcher uses a separate `notification_deliveries` marker for send idempotency. | Without deployed Functions the booking notification would disappear entirely. The marker makes both paths coexist without duplicate pushes. Remove the client write when Functions go live. |
| P0.2 complete rules | **Done in §16** — the exported console ruleset was supplied and merged into a complete `firestore.rules`. | The production wildcard `match /{document=**} { allow read, write: if request.auth.uid != null }` could not stay alongside per-collection rules. |

---

## 16. Firestore rules — completed rule set (2026-11-05)

The console export showed the deployed ruleset consisted of the booking-module overlay **plus** a
catch-all:

```
match /{document=**} { allow read, write: if request.auth.uid != null; }
```

That catch-all grants every signed-in user read/write on every collection, so the overlay's
restrictions were decorative. Risk **R1** was therefore not only "deploying the overlay denies
everything" but also "leaving the console as-is makes every rule meaningless".

`firestore.rules` is now a self-contained 342-line rule set for all 28 collections the app touches.
No overlay, no catch-all. Deployable with:

```
firebase deploy --only firestore:rules,firestore:indexes
```

### 16.1 Helpers

| Helper | Purpose |
|---|---|
| `signedIn()` | `request.auth != null` |
| `isSelf(uid)` | caller owns the document |
| `statusIn(list)` | validates a status enum |
| `isLinkedUser(clientId)` | caller is the client doc's `uid` |
| `ownsClient(clientId)` | designer of the parent `created_by`, guarded by `exists()` |
| `createsAsSelf()` | stamps `created_by`/`uid` as the caller |
| `updatesOwnedDocument()` | updates allowed only by `created_by` |

### 16.2 Access model

- **Discovery data** (`designers`, `trends`, `designs`, `fashion_interests`, `work_orders` feed)
  — readable by any signed-in user, writable by the owner.
- **Private data** (`clients`, `client_measurements`, `closets`, `users`) — read scoped to the
  owner or a designer-client link; writes owner-only.
- **Bookings / `slot_reservations`** — read scoped to the two participants; create restricted to
  `user_id == request.auth.uid` + `status == 'pending'` + `client.id == client_id`; update split
  between the designer (status transitions) and the client (cancel only).
- **`notifications`** — recipient-only read; update limited to `status`/`read_at`; legacy create
  requires `from == request.auth.uid`.
- **`users/{uid}/devices`** — owner-only, `is_active` toggled on sign-out.
- **`notification_deliveries`** — denied to all clients; only the Admin SDK (Cloud Functions) touches it.
- **`fashion_interests`** — read-only reference data.

Note: ownership fields differ per collection — `designer_reviews`, `designer_feedback` and trend
`comments` use `author.uid` (nested under `comment.author.uid` for comments), everything else uses
`created_by`.

### 16.3 Verification matrix (Firestore emulator, 30/30 pass)

Authenticated with unsigned JWTs for `u1` (client), `u2` (unrelated user) and `d1` (designer):

| Collection | Check | Result |
|---|---|---|
| bookings | client reads own booking / designer reads / stranger denied | 200 / 200 / 403 |
| bookings | stranger creates for someone else; client creates `confirmed` | 403 / 403 |
| notifications | recipient read; non-recipient read | 200 / 403 |
| notifications | recipient marks read (`status`+`read_at`); changes `title`; spoofs `from` | 200 / 403 / 403 |
| users/*/devices | owner registers; cross-user write; owner deactivates | 200 / 403 / 200 |
| designers | signed-in read; owner update; non-owner update | 200 / 200 / 403 |
| designers/*/availability | owner write; non-owner write; signed-in read | 200 / 403 / 200 |
| clients | owner read; linked user read; stranger read; linked user update | 200 / 200 / 403 / 403 |
| clients/*/measurements | owner write; stranger write | 200 / 403 |
| closets/*/closet_items | owner write; stranger write | 200 / 403 |
| fashion_interests | signed-in read; any write | 200 / 403 |
| notification_deliveries | client write | 403 |

**Important:** the emulator matrix uses REST `PATCH` **with `updateMask`**, which is what the app's
`set(..., SetOptions(merge: true))` compiles to. A mask-less REST `PATCH` *replaces* the document, so
fields such as `from` vanish from `request.resource.data` and rules referencing them raise
"Property … is undefined on object" and deny. The Flutter client always merges, so this is only a
gotcha for hand-written REST calls.

### 16.4 Remaining deployment caveats

1. `firebase deploy --only firestore:rules,firestore:indexes` must be run before the app ships —
   the console still has the permissive wildcard.
2. Cloud Functions still require the Blaze plan; rules alone do not deliver push.
3. iOS push still requires the APNs auth key upload.

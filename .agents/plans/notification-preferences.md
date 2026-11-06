# Notification Preferences — Implementation Plan

**Status:** Implemented (2026-11-06) — see §17 for what shipped
**Date:** 2026-11-06
**Related:** [push-notifications-module.md](./push-notifications-module.md), [designer-availability-booking-module.md](./designer-availability-booking-module.md)

---

## 0. Context — current state

The backend half of this feature already exists. `deliverNotification()` reads
`users/{uid}/settings/notifications`, checks a category, and either sends or returns
early. No client ever writes that document, so every user silently runs on defaults and
there is no way to change them.

| # | Finding | Evidence |
|---|---|---|
| F1 | A preference gate **already exists** and every trigger goes through it | `functions/src/notifications/types.ts` (`NotificationPreferences`, `DEFAULT_PREFERENCES`, `preferenceKeyFor`); `functions/src/notifications/dispatcher.ts:49` |
| F2 | Schema mismatch — 6 keys exist, the product wants 7 different ones | current: `appointments, orders, measurements, reminders, social, clients` |
| F3 | `social` gates **three** unrelated events | trend like, trend comment and designer review all map to `social` |
| F4 | `measurement_updates` has **no producer** — the measurement trigger was removed | `functions/src/triggers/measurement.triggers.ts` deleted 2026-11-06 |
| F5 | ~~`appointment_reminder` has no producer~~ — **superseded**: local reminders now exist (`AppointmentReminderService`, 5 minutes before a confirmed appointment) | no `onSchedule` job emits reminders (reminders are device-local by design) |
| F6 | `clients` (client-link push) exists but is not in the product list | `functions/src/triggers/client-link.triggers.ts` |
| F7 | **No preference document is written today** — zero migration burden | repo-wide grep found no writer |
| F8 | No preferences UI; the settings row is a placeholder | `lib/presentation/screens/settings/settings_screen.dart:128` → `_comingSoon(context)` |
| F9 | **A disabled preference currently drops inbox history too.** The dispatcher comment says "disabling push must not delete history" but it returns *before* `createHistoryIfAbsent` | `functions/src/notifications/dispatcher.ts:49` |
| F10 | Rules allow self read/write on the settings doc, but do not validate field types | `firestore.rules:107` |

---

## 1. Executive summary

Add the missing client half — model, repository, cubit, screen — and rework the backend
taxonomy so both sides speak the same eight keys. One behavioural correction is included:
**a disabled category stops the push but keeps writing the in-app inbox record**, which
is what the dispatcher's own comment already promises.

---

## 2. Objectives

1. A signed-in user can view and change notification categories, stored per account
   (`users/{uid}/settings/notifications`), never per device.
2. Disabling a category stops **FCM delivery only**; the inbox keeps receiving the event.
3. Existing users are unaffected — a missing document or a missing field falls back to
   its default (`true`).
4. Both languages agree on the key strings, enforced by a parity test.

---

## 3. Scope

**In scope**

- Dart model, repository, usecases, cubit, screen, route, settings entry
- Backend key taxonomy, gate on `(type, event)`, history/push split
- Rules validation, tests, documentation

**Out of scope**

- Building new notification producers (reminders, measurements)
- Per-device preferences, quiet hours, digest batching
- Migrating old preference documents (none exist — F7)
- Changing notification payloads or deep-link destinations

---

## 4. Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Hide dormant toggles.** `appointment_reminder` and `measurement_updates` stay in the schema (default `true`) but render no row | Neither had a producer (F4, F5). A toggle that does nothing is worse than no toggle. `appointment_reminder` is now **visible** because `AppointmentReminderService` produces reminders |
| D2 | **History survives a disabled preference.** Inbox records are always written; the gate only short-circuits device lookup and the FCM send | Confirms spec §8 and fixes F9. In-app history is an event log, not a push artefact |
| D3 | Keep `clients` as an 8th key, default `true` | Already shipped and gating `clientLinked`; dropping it would silently change behaviour |
| D4 | Keep the document at `users/{uid}/settings/notifications` | Already read by the dispatcher and permitted by rules; no reason to move it |
| D5 | Do **not** rename the persisted `notification.type` values | They drive the inbox widget switch and exist on already-stored records |
| D6 | No master "mute all" switch | Not requested; adds a second code path and a second denial reason |
| D7 | **Bottom sheet, not a route.** The settings row opens a modal sheet (`showNotificationPreferencesSheet`) instead of pushing `/notification-preferences` | Matches the existing `_showImageQualityBottomsheet` pattern in the settings screen; no new route, no app bar |

**Visible UI (6 rows, 4 sections):**

| Section | Row | Key |
|---|---|---|
| Social activity | Likes on my trends | `trend_like` |
| Social activity | Comments on my trends | `trend_comment` |
| Appointments | Appointment updates | `appointments` |
| Designer activity | Ratings and reviews | `designer_rating` |
| Designer activity | Added as a client | `clients` |
| Fashion updates | Order updates | `order_updates` |

Hidden but present in the model and backend: `measurement_updates` only — `appointment_reminder`
became visible when local appointment reminders were added.

---

## 5. Assumptions

- The authenticated user id is the document owner; no preference is ever written while
  signed out.
- `updated_at` is a Firestore `Timestamp` written by the client on each save.
- The backend remains the only enforcement point; Flutter never suppresses an event it
  has already sent.

---

## 6. Architecture impact

### 6.1 Event → preference mapping

`preferenceKeyFor(type)` becomes `preferenceKeyFor(payload)` — `type` alone cannot
separate likes from comments (F3), so the fine-grained `event` participates.

| Business event | `payload.type` | `payload.event` | Preference key |
|---|---|---|---|
| Trend liked | `trend` | `trend_liked` | `trend_like` |
| Trend commented | `trend` | `trend_commented` | `trend_comment` |
| Booking created | `appointment` | `appointment_requested` | `appointments` |
| Booking confirmed / declined | `appointment` | `appointment_confirmed` / `appointment_declined` | `appointments` |
| Booking cancelled | `appointment` | `appointment_cancelled` | `appointments` |
| *no producer* | — | — | `measurement_updates` |
| Designer reviewed | `review` | `review_received` | `designer_rating` |
| Work order created | `work_order_status_progress` | `order_received` | `order_updates` |
| Work order status / progress | `work_order_status_progress` | `order_status_updated` | `order_updates` |
| *no producer* | — | — | `measurement_updates` |
| Client linked | `client` | `client_linked` | `clients` |

### 6.2 Legacy key fallback (read path)

Old keys may exist in a document written by a future/older build. Resolution order:

```
new key present        → use it
legacy key present     → use it   (social → trend_like, trend_comment, designer_rating
                                   orders → order_updates
                                   measurements → measurement_updates
                                   reminders → appointment_reminder)
neither                → default true
```

The client always **writes the new keys**; legacy keys are left untouched (unknown
fields are preserved), and they simply stop being consulted once the new key exists.

### 6.3 Dispatcher restructure (D2)

```
1. read preferences        throw on failure (log first) → platform retries
2. create history          ALWAYS
3. claim delivery marker   ALWAYS
4. if category disabled    return after history, before device lookup
5. multicast + token cleanup
```

Steps 1–3 keep their current semantics; only the early return moves.

### 6.4 Flutter layering

```
domain/repository/notifications/notification_preferences_repository.dart   (interface)
data/repository/notifications/notification_preferences_repository_impl.dart
data/services/firebase/firebase_notification_preferences_service.dart
data/models/notification/notification_preferences.dart                    (model + key enum)
data/models/notification/bloc/notification_preferences_cubit.dart
domain/usecases/notification_preferences/{load,update,save}_*.dart
presentation/screens/settings/widgets/notification_preferences_sheet.dart
```

Registered in `lib/core/service_locator/service_locator.dart` and the cubit provider in
`lib/main.dart`, following the existing conventions.

---

## 7. Firestore

### 7.1 Document

```
users/{userId}/settings/notifications
{
  "trend_like": true,
  "trend_comment": true,
  "appointments": true,
  "appointment_reminder": true,     // gates local reminders, 5 min before
  "designer_rating": true,
  "order_updates": true,
  "measurement_updates": true,      // hidden in UI
  "clients": true,
  "updated_at": <Timestamp>
}
```

One `set(..., { merge: true })` per toggle — never a full-document overwrite.

### 7.2 Security rules

`users/{userId}/settings/notifications` currently allows any self write. Tighten to:

- read: `isSelf(userId)`
- write: `isSelf(userId)` **and** every present field is one of the eight booleans, with
  `updated_at` a timestamp, and no key outside that set
- absence of any/all keys remains valid (first save may be partial)

No index changes — every access is a direct document read.

---

## 8. Implementation phases

| Phase | Work |
|---|---|
| 0 | Shared contract: the 8 keys + defaults, defined once per language, asserted identical by tests |
| 1 | Dart model → repository → service → usecases → DI |
| 2 | Cubit with optimistic updates, rollback and per-key sequencing |
| 3 | Screen, route `/notification-preferences`, settings row wired |
| 4 | Backend: keys, `preferenceKeyFor(payload)`, legacy fallback, history/push split |
| 5 | Verify all producers map correctly (no new triggers) |
| 6 | Rules validation |
| 7 | Tests + emulator verification |

---

## 9. Task breakdown

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P0.1 | Canonical keys + defaults in both languages | `lib/data/models/notification/notification_preferences.dart`, `functions/src/notifications/types.ts` | — | S | Dart and TS tests assert the same 8 strings |
| P1.1 | Preferences model | `notification_preferences.dart` | P0.1 | M | Round-trips; missing fields default `true`; unknown keys preserved |
| P1.2 | Repository interface + impl | `domain/repository/notifications/*`, `data/repository/notifications/*` | P1.1 | M | Merge write; typed `Either`; missing doc ⇒ defaults |
| P1.3 | Service + usecases + DI | `data/services/firebase/firebase_notification_preferences_service.dart`, `domain/usecases/notification_preferences/*`, `service_locator.dart` | P1.2 | S | Resolvable from `sl`; matches existing pattern |
| P2.1 | Cubit | `data/models/notification/bloc/notification_preferences_cubit.dart`, `main.dart` | P1.3 | M | Optimistic set, rollback on error, rapid toggles converge on last value |
| P3.1 | **Bottom sheet** + settings entry (D7) | `presentation/screens/settings/widgets/notification_preferences_sheet.dart`, `settings_screen.dart` | P2.1 | M | 6 rows in 4 sections; loading, error + retry; dormant keys render nothing |
| P4.1 | Key taxonomy + `preferenceKeyFor(payload)` + legacy fallback | `functions/src/notifications/types.ts`, `helpers.ts` | P0.1 | M | Mapping matrix passes |
| P4.2 | History/push split | `functions/src/notifications/dispatcher.ts` | P4.1 | M | Disabled ⇒ history exists, zero sends |
| P4.3 | Log + rethrow on preference read failure | `functions/src/notifications/dispatcher.ts` | P4.2 | S | Throwing store ⇒ no send, error surfaces, retry safe |
| P5.1 | Verify producers map to the right key | `functions/src/triggers/*.ts` | P4.1 | S | One assertion per trigger |
| P6.1 | Rules validation | `firestore.rules` | P1.1 | S | 8 booleans accepted; junk rejected; cross-user denied |
| P7.1 | Dart tests | `test/notifications/*` | P1–P3 | M | Model, repo, cubit, widget |
| P7.2 | Functions tests | `functions/test/*` | P4–P5 | M | Checker matrix + per-trigger |
| P7.3 | Emulator run | scripts + emulator | P7.2 | M | Disabled key ⇒ history written, no push; enabled ⇒ both |

**Sizes:** S ≤ 0.5 day · M ≈ 1 day · L ≈ 2–3 days (with alternatives documented) · XL > 3 days (break down).
No L/XL items above — the work decomposes cleanly.

---

## 10. Dependencies

Internal: `NotificationBloc` (inbox), `RoundToggle`, `AppTheme`, `sl`, `appRouter`, the
six existing trigger modules, `firestore.rules`.
External: `firebase-admin`, `firebase-functions`, `cloud_firestore`, `dartz`, `flutter_bloc`
— all already present. **No new packages.**

---

## 11. Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | Key rename breaks existing writes | Low — no documents exist (F7) | Low | Legacy read fallback retained |
| R2 | History/push split makes the inbox busier than today | Medium (visible) | Medium | Explicit decision D2; called out in release notes |
| R3 | Splitting `social` changes granularity | Low | Low | `social` still honoured as a fallback |
| R4 | Optimistic UI desync on rapid toggles | Medium | Medium | Per-key sequence number + rollback |
| R5 | Preference read failure loops retries | Medium | Low | Log then throw; the delivery marker prevents duplicate pushes on retry |
| R6 | Rules validation rejects a future/older client | Medium | Low | Validate only known keys; partial documents allowed |
| R7 | Hiding two keys confuses future devs | Low | High | Documented here and in the model's constants |

---

## 12. Acceptance criteria

- 6 rows render across 4 sections; toggling persists exactly one merged field.
- A new user (no document) sees every default enabled and receives every event.
- `trend_comment: false` ⇒ no comment push **and** the inbox row still appears.
- An explicit `false` always wins; a missing field falls back to its default.
- A failed save rolls the toggle back.
- Two rapid toggles of one key persist the last value, not the first.
- Cross-user read/write on the settings path is denied (emulator-verified).
- All existing Dart and Functions tests still pass.

## 13. Definition of done

Acceptance criteria met; rules and functions deployed; `flutter analyze` clean for touched
files; the **Status** header above updated to *Implemented*; no preference document created
for signed-out users; `.agents/plans/push-notifications-module.md` cross-referenced.

---

## 14. Test matrix

**Dart** — defaults; serialization round-trip; missing document; missing individual field;
`withValue`; repository merge persistence; cubit load/error/rollback; rapid-toggle
convergence; screen renders 7 rows and hides the dormant one.

**Functions** — enabled ⇒ history + send; disabled ⇒ history, no send; missing document ⇒
defaults; missing field ⇒ its default; explicit `false` respected; read failure ⇒ no send,
error surfaces; every producer maps to the expected key; duplicate event ⇒ one history,
one push.

---

## 15. Deployment & manual steps

```
firebase deploy --only firestore:rules,functions
```

- No data migration: no preference documents exist (F7).
- No new indexes.
- Rollout is additive; existing clients keep working on defaults.
- After deploy, verify with the emulator that a disabled key still writes the inbox
  record (D2) before announcing the feature.

---

## 16. Sequencing recommendation

1. **P0.1 first** — the key list is the only thing both languages must agree on.
2. **P4.2 as its own change** — the history split is a visible behaviour change,
   independent of the UI; ship and verify it alone.
3. **P1 → P3 next** — client stack.
4. **P6/P7 last** — rules and full verification.

---

## 17. Implementation record (2026-11-06)

Delivered as planned, with the UI as a bottom sheet (D7).

### Files created

| Layer | File |
|---|---|
| Model | `lib/data/models/notification/notification_preferences.dart` |
| State | `lib/data/models/notification/bloc/notification_preferences_state.dart` |
| Cubit | `lib/data/models/notification/bloc/notification_preferences_cubit.dart` |
| Service | `lib/data/services/firebase/firebase_notification_preferences_service.dart` |
| Repository interface | `lib/domain/repository/notifications/notification_preferences_repository.dart` |
| Repository impl | `lib/data/repository/notifications/notification_preferences_repository_impl.dart` |
| Usecases | `lib/domain/usecases/notification_preferences/{load,update}_*.dart` |
| UI | `lib/presentation/screens/settings/widgets/notification_preferences_sheet.dart` |
| Tests | `test/notifications/notification_preferences_{model,cubit,sheet}_test.dart`, `functions/test/preference-keys.test.ts` |

### Files modified

`functions/src/notifications/{types,helpers,repository,dispatcher}.ts`, `functions/test/{helpers,dispatcher}.test.ts`,
`lib/core/service_locator/service_locator.dart`, `lib/main.dart`,
`lib/presentation/screens/settings/settings_screen.dart`, `firestore.rules`.

### Verified

- **Rules** — 11/11 emulator checks: one-field and all-eight writes accepted; legacy key, unknown key,
  non-boolean value and non-timestamp `updated_at` rejected; cross-user read/write denied; owner delete allowed.
- **Backend gate** — emulator, three scenarios:
  - `trend_comment: false` → inbox history written, **no delivery marker** (log: `Push suppressed by preferences`)
  - legacy `social: false` → like history written, no marker
  - defaults → history **and** marker (push attempted)
- **Tests** — 149 Functions, 76 Dart notification tests.

### Deviations

| Item | Deviation | Reason |
|---|---|---|
| P3.1 | Bottom sheet instead of a route | Requested (D7); matches the image-quality sheet already in the settings screen |
| Retry affordance | The empty state no longer renders its own Retry when the error banner is visible | Both rendered `Retry`, which is confusing and broke the widget assertion |


---

## Follow-up — `appointment_reminder` now has a producer

The dormant `appointment_reminder` toggle is **visible** again because local reminders now exist.
Unlike the other categories, this one is not server-side: a scheduled local notification only fires
on the device that created it, so the gate is read on the device.

| Piece | File |
|---|---|
| Toggle | `NotificationPreferenceKey.appointmentReminder` (`visible: true`) |
| Scheduler | `lib/data/services/local/appointment_reminder_service.dart` |
| Plugin wrapper | `LocalNotificationService.scheduleNotification` gained a channel, an optional one-shot mode and a payload |
| Trigger | `BookingBloc` — designer confirms/cancels, and every bookings list load reconciles |

Behaviour:

- fires **5 minutes** before `start_at` (`AppointmentReminderService.leadTime`), once, on the
  `appointment_reminders` channel;
- a disabled preference **cancels** an already-scheduled reminder rather than leaving it armed;
- the notification id is an FNV-1a hash of the booking id, so re-confirming replaces the reminder and
  a cancel can remove one scheduled in an earlier session (`String.hashCode` is not stable across
  launches);
- tapping routes through `NotificationPayload` → `/my-bookings`, or `/designer-bookings` for the
  designer;
- sign-out calls `LocalNotificationService.cancelAll()` so one account's reminders never fire for the
  next account on the device;
- scheduling is best-effort: a denied permission or refused exact-alarm request is logged and never
  fails the booking action.

Limitation: a client only gets a reminder once their device has seen the confirmed booking, because
local notifications cannot be scheduled remotely. Guaranteed delivery would need a server job, which
is deliberate scope left out.

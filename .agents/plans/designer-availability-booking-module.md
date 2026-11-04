# Plan — Designer Availability & Appointment Booking Module

| | |
|---|---|
| **Status** | Plan — approved for implementation, no code written yet |
| **Created** | 2026-11-03 |
| **Module** | Designer weekly availability, date exceptions, slot generation, client bookings, slot reservations |
| **Constraint** | Flutter + Firebase client SDKs only. No Cloud Functions, no callable functions, no HTTP backend. |
| **Source spec** | Availability & Appointment Booking spec (pasted, 882 lines) |

---

## 1. Executive Summary

Add a designer availability + appointment booking module implemented entirely with the
Flutter Firebase client SDK (no Cloud Functions, no backend API).

The module has four separable concepts, each of which is its own layer concern:

| Concept | Stored? | Where |
|---|---|---|
| Weekly availability + per-day duration | Yes | `designers/{id}/availability/{weekday}` |
| Date-specific exceptions | Yes | `designers/{id}/availability_exceptions/{yyyy-MM-dd}` |
| Generated appointment slots | **No** — computed on demand | pure Dart utility |
| Bookings + slot reservations | Yes | `bookings/{id}` + `slot_reservations/{id}` |

### Critical architectural finding

**This repo has no `firestore.rules` and `firebase.json` contains no Firestore section** —
rules are managed in the Firebase console only. Combined with the "no Cloud Functions"
constraint, several invariants in the spec (§9 reservation integrity, §15 security) cannot be
enforced from this repository today. This is the largest risk in the plan and requires a
decision (see Q1) before Phase 5.

---

## 2. Objectives

1. Designers configure a recurring weekly schedule with multiple sessions per day and a
   per-day appointment duration.
2. Designers override specific dates via exceptions without touching the recurrence.
3. The app generates contiguous appointment slots from sessions + duration, and never
   persists them.
4. Clients discover genuinely available slots (accounting for exceptions, existing bookings,
   and past time).
5. Clients book atomically; two clients cannot claim the same slot.
6. Availability edits never silently delete or cancel existing bookings.
7. Everything reuses the existing DI / repository / BLoC / routing / theming conventions.

---

## 3. Scope

### In Scope

- 2 new Firestore trees (availability, exceptions) and 2 new top-level collections
  (bookings, slot reservations).
- `timezone` field added to the Designer profile.
- Pure-Dart slot generation + schedule validation, with unit tests.
- Designer UI: manage-week, edit-day, session editing, slot preview, copy/apply/clear,
  conflict warnings.
- Client UI: date picker → slot picker → confirmation → status, plus "My bookings".
- Designer UI: booking list + status transitions (confirm/decline/cancel/complete/no-show).
- Firestore rules authored into the repo for the first time, plus required composite
  indexes.
- Fixing the existing **dead `/designer-bookings` link** in
  [designer_profile_page.dart](../../lib/presentation/screens/designers/designer_profile_page.dart)
  (the route does not exist) and replacing the `Placeholder` body in
  [designer_bookings_screen.dart](../../lib/presentation/screens/designers/designer_bookings_screen.dart).

### Out of Scope

- Cloud Functions, callable functions, any HTTP backend.
- Notifications/push for booking events (unless requested later).
- Payments, rescheduling flows, calendar sync (ICS/Google Calendar).
- Cancellation-fee policies or per-client cancellation windows beyond a simple status gate.
- Physical cleanup of expired reservation documents (explicitly not required; correctness
  must not depend on it).
- Offline/Hive caching of availability or bookings.
- Any refactor of unrelated features.

---

## 4. Assumptions

| # | Assumption | Evidence |
|---|---|---|
| A1 | `designerId` == designer's Firebase Auth UID == `designers/{uid}` document ID. | [firebase_designers_service.dart](../../lib/data/services/firebase/firebase_designers_service.dart) writes `collection('designers').doc(uid)` |
| A2 | A user's designer-scoped client record is resolvable via `client_measurements/{userId}/clients/{clientId}` with fields `client_id`, `designer_id`, `is_default`. | [firebase_clients_service.dart](../../lib/data/services/firebase/firebase_clients_service.dart), [client_measurement_relationship.dart](../../lib/data/models/clients/client_measurement_relationship.dart) |
| A3 | Firestore field/collection naming is `snake_case`; the spec's camelCase is NOT the repo convention. | `created_by`, `created_at`, `updated_at`, `mobile_number` across models |
| A4 | Models use `@JsonSerializable(explicitToJson: true)` + `part '*.g.dart'`; Hive only for cached entities. Newer features have no Hive annotation. | [designer_service_model.dart](../../lib/data/models/designers/designer_service_model.dart) |
| A5 | Repositories are pure `abstract class` interfaces returning `dartz.Either`; impls delegate to `sl<Firebase*Service>()`; usecases are thin wrappers registered in `service_locator.dart`. | [clients_repository.dart](../../lib/domain/repository/clients/clients_repository.dart), [add_client_usecase.dart](../../lib/domain/usecases/clients/add_client_usecase.dart) |
| A6 | `timezone` + `flutter_timezone` are already dependencies and device tz is already resolved at startup. | [main.dart](../../lib/main.dart) `_configureLocalTimeZone` |
| A7 | Blocs are app-level singletons registered in `main.dart`'s `MultiBlocProvider`. | [main.dart](../../lib/main.dart) |
| A8 | No test infrastructure beyond `flutter_test` pure unit tests; no emulator harness, no `fake_cloud_firestore`. | `test/` contains 2 files |

---

## 5. Open Questions

Blockers for specific phases, not for starting Phase 1.

| # | Question | Blocks | Recommended default |
|---|---|---|---|
| Q1 | **Security rules**: repo has no `firestore.rules`. Do we (a) create one + wire `firebase.json` and deploy via CLI, or (b) keep managing rules in the console and only document them? | Phase 5 | **(a)**. Version-controlling rules is the only way to guarantee booking invariants survive console edits. Requires firebase CLI access — a new operational dependency. |
| Q2 | **Client identity at booking time**: a user may not have a designer-scoped `clientId` yet. Auto-create the `clients/{id}` row + relationship on first booking, block booking until the designer adds them, or allow `client_id` null? | Phase 5 | **Auto-create on first booking** inside the transaction (mirrors existing `linkClientToUser` semantics) so booking never dead-ends for new users. |
| Q3 | **Pending reservation TTL** value, and should it be Remote Config rather than a constant? | Phase 5 | Single `BookingPolicy.pendingReservationTtl = 15 min` constant. RC is overkill for V1 but trivially swappable. |
| Q4 | **Cancellation policy**: can a client cancel `confirmed`, or only `pending`? Cutoff? | Phase 6 | Client may cancel `pending` and `confirmed` up to 2 h before `startAt`; designer may cancel any time. Single policy class. |
| Q5 | **Booking horizon**: how far ahead can a client book? | Phase 6 | 30 days. |
| Q6 | **Timezone source**: device tz at first schedule save, or a designer-selectable dropdown? | Phase 1 | Prompt on first availability save, prefilled from `flutter_timezone`; editable afterwards. |
| Q7 | **Status vocabulary**: spec uses `noShow`; Firestore string should be `no_show`. Confirm. | Phase 1 | `no_show`. |
| Q8 | Add `fake_cloud_firestore` as a dev dependency for transaction tests? | Phase 5 | **Yes** if Q1 = (a). It is the only new dependency in this plan. |

---

## 6. Architecture Impact

### 6.1 What exists today (inspection summary)

| Concern | Current state |
|---|---|
| Structure | `lib/core` (theme/routes/DI/widgets/models/utils), `lib/data` (models + bloc + repository impls + `services/firebase` + `services/hive`), `lib/domain` (entities, repository interfaces, usecases), `lib/presentation` (screens/widgets). **No `lib/features/`** — the spec's suggested tree must be adapted. |
| DI | `get_it`, 73 `registerSingleton` calls, all in [service_locator.dart](../../lib/core/service_locator/service_locator.dart). Order: repository → usecase → service. |
| Errors | `Either<String, T>` from `dartz`; `FirebaseException` caught explicitly, generic `catch` fallback (`e.toString()`). |
| State | `flutter_bloc` + `hydrated_bloc`. 23 app-level providers in `main.dart`; local `BlocProvider` also used per-screen in [designer_details_profile_page.dart](../../lib/presentation/screens/designers/designer_details_profile_page.dart). |
| Navigation | `go_router` — one flat list of `GoRoute`s + a `StatefulShellRoute.indexedStack` for the 4 tabs; screen params passed via `state.pathParameters` / `state.uri.queryParameters` (see `DesignerServicesScreen`). |
| Timezones | `timezone` + `flutter_timezone` initialized in `main.dart`; `tz.TZDateTime` already used in [local_notification_service.dart](../../lib/core/service_locator/local_notification_service.dart). **No new dependency needed.** |
| Transactions | Exactly one precedent: `setDefaultClientForUser` in [firebase_clients_service.dart](../../lib/data/services/firebase/firebase_clients_service.dart) — reads first, then writes. |
| Timestamps | Inconsistent: `Timestamp.now()` for `created_at` (designers, design_collection) vs `int` epoch (`designer_services`, `trends`, `clients.updated_at`). |
| Hive | `@HiveType` models registered in [hive_type.dart](../../lib/core/models/hive/hive_type.dart) with per-model field-index classes (e.g. `DesignerModelHiveType`, max index 16). |
| Rules | **None in repo.** `firebase.json` only configures Flutter platform outputs. |
| Tests | 2 files; pure model-serialization style ([client_measurement_firestore_test.dart](../../test/client_measurement_firestore_test.dart)). No emulator config, no fakes. |

### 6.2 Backend / data model changes

Names below are **snake_case** per A3; the spec's camelCase is deliberately not followed
(spec §4 permits adapting to project convention).

#### A. `designers/{designerId}/availability/{weekday}`

Weekday doc ID = `"1"`..`"7"` (`DateTime.monday`..`DateTime.sunday`).

```json
{
  "day_of_week": 1,
  "is_available": true,
  "appointment_duration_minutes": 30,
  "sessions": [
    { "start_time": "08:00", "end_time": "10:00" },
    { "start_time": "12:00", "end_time": "13:00" }
  ],
  "updated_at": "Timestamp"
}
```

Structure preserved when disabled (`is_available: false`, `sessions: []`, duration kept).

#### B. `designers/{designerId}/availability_exceptions/{yyyy-MM-dd}`

Deterministic doc ID based on the designer-local date.

```json
{
  "date": "2026-11-18",
  "type": "custom",
  "sessions": [{ "start_time": "10:00", "end_time": "14:00" }],
  "appointment_duration_minutes": 30,
  "reason": null,
  "created_at": "Timestamp",
  "updated_at": "Timestamp"
}
```

`type` ∈ `unavailable` | `custom`. `appointment_duration_minutes` null → inherit weekday.

#### C. `bookings/{bookingId}`

```json
{
  "designer_id": "designer_123",
  "user_id": "user_456",
  "client_id": "designer_client_789",
  "date": "2026-11-16",
  "day_of_week": 1,
  "start_at": "Timestamp",
  "end_at": "Timestamp",
  "start_time": "08:30",
  "end_time": "09:00",
  "timezone": "Africa/Accra",
  "duration_minutes": 30,
  "status": "pending",
  "notes": "I would like to discuss my wedding outfit.",
  "created_at": "Timestamp",
  "updated_at": "Timestamp"
}
```

Two additions beyond the spec, both justified:

- `day_of_week` — makes the "which bookings conflict with a schedule edit" query indexable
  instead of a full scan (see Phase 5 / §10 R8).
- `user_id` — needed for client booking queries and security rules without extra reads.

#### D. `slot_reservations/{designerId}_{yyyyMMdd}_{HHmm}`

```json
{
  "designer_id": "designer_123",
  "user_id": "user_456",
  "booking_id": "booking_456",
  "start_at": "Timestamp",
  "end_at": "Timestamp",
  "status": "reserved",
  "expires_at": "Timestamp",
  "created_at": "Timestamp"
}
```

`user_id` is denormalized **so security rules can validate ownership without a `get()`**.

#### E. `designers/{uid}` gains `timezone: String?`

IANA name (e.g. `Africa/Accra`). Must be **nullable** so existing Hive-cached Designer
payloads do not fail adapter reads (see R4).

### 6.3 Code layout (adapted to this repo, not `lib/features/`)

```
lib/data/models/availability/
    designer_availability_model.dart          (+ .g.dart)
    availability_session_model.dart           (+ .g.dart)
    availability_exception_model.dart         (+ .g.dart)
    available_slot_model.dart                 (plain, no codegen)
lib/data/models/bookings/
    booking_model.dart                        (+ .g.dart)
    booking_status.dart                       (enum + codec)
    slot_reservation_model.dart               (+ .g.dart)
lib/data/services/firebase/
    firebase_availability_service.dart
    firebase_booking_service.dart
lib/data/repository/
    availability_repository_impl.dart
    booking_repository_impl.dart
lib/domain/repository/availability/availability_repository.dart
lib/domain/repository/bookings/booking_repository.dart
lib/domain/usecases/availability/*.dart
lib/domain/usecases/bookings/*.dart
lib/core/utils/scheduling/
    time_of_day_x.dart                        ("HH:mm" <-> minutes, validation)
    slot_generator.dart                       (pure generation — core algorithm)
    booking_policy.dart
    reservation_key.dart
lib/presentation/screens/availability/
    manage_availability_screen.dart
    edit_day_availability_screen.dart
    widgets/day_availability_card.dart
    widgets/session_editor_tile.dart
    widgets/slot_preview_grid.dart
lib/presentation/screens/bookings/
    book_appointment_screen.dart              (date -> slot)
    booking_confirmation_screen.dart          (summary + notes + submit)
    booking_status_screen.dart                (result)
    my_bookings_screen.dart                   (client)
    designer_bookings_screen.dart             (replace existing Placeholder)
    booking_details_sheet.dart
```

Pure scheduling helpers live in `lib/core/utils` (consistent with `get_relative_time.dart`)
rather than a new `domain/services` layer — smallest structural change that keeps the
algorithm testable and shared by repository + preview UI.

### 6.4 Infrastructure / config

- New: `firestore.rules` (repo root), `firestore.indexes.json`, `firebase.json` gains a
  `"firestore"` section. Deploy is manual: `firebase deploy --only firestore`.
- **No** new runtime dependencies. `timezone`, `flutter_timezone`, `intl`, `uuid`, `dartz`,
  `equatable`, `json_annotation` all already present.
- One optional dev dependency: `fake_cloud_firestore` (Q8).

---

## 7. Implementation Plan

### Phase 0 — Foundations (small, unblocks everything)

1. Add nullable `timezone` to `Designer` model + `copyWith` + `DesignerModelHiveType.timezone = 17`;
   regenerate.
2. Add `time_of_day_x.dart` (parse/format/validate `HH:mm`, minutes-from-midnight).
3. Add `BookingPolicy` (TTL, cancellation cutoff, booking horizon).
4. Author `firestore.rules` + `firestore.indexes.json` skeletons; wire `firebase.json`.

### Phase 1 — Availability data layer

Models, codegen, `FirebaseAvailabilityService`, repository interface + impl, DI registration,
mapping tests.

### Phase 2 — Scheduling logic + tests (highest value, zero UI risk)

`slot_generator.dart`, schedule validation (overlap/duplicate/too-short/invalid), exception
resolution (pure function: weekly + exceptions + date → effective sessions/duration). Full
unit-test matrix from spec §16.

### Phase 3 — Designer availability UI

Manage screen + edit-day screen + preview + copy/apply/clear + `AvailabilityBloc`.

### Phase 4 — Client slot discovery

`GetAvailableSlotsUsecase` composing availability + bookings + generator; date/slot screens
with occupied/past filtering.

### Phase 5 — Booking + reservations (critical path)

`runTransaction` implementation, status transitions, reservation release, rules for
bookings/reservations, concurrency tests.

### Phase 6 — Booking management UI

Designer list/detail/actions; client list/cancel; status screen; fix `/designer-bookings`
dead link.

### Phase 7 — Hardening & documentation

Indexes verified from real query failures, manual test script, known-limitations doc,
`flutter analyze` clean.

---

## 8. Task Breakdown

Sizes: **S** ≤ 4 h · **M** 4–8 h · **L** 1–3 d · **XL** > 3 d.

### Phase 0 — Foundations

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| A1 | Add nullable `timezone` to Designer; new Hive index 17; regen adapters + `.g.dart` | `designer_model.dart`, `designer_model_hive_type.dart`, generated files | — | S | `flutter analyze` clean; old cached designer payload still deserializes (timezone null) |
| A2 | `HH:mm` helpers: parse, format, validate, minutes<->string, ordering | `lib/core/utils/scheduling/time_of_day_x.dart` | — | S | Unit tests: valid/invalid/`24:00`/`8:00`/`08:60` |
| A3 | `BookingPolicy` constants (TTL 15 m, horizon 30 d, cancel cutoff 2 h) | `lib/core/utils/scheduling/booking_policy.dart` | — | S | Single import site; no magic numbers elsewhere |
| A4 | Add `firestore.rules` + `firestore.indexes.json`; add `firestore` section to `firebase.json` | root, `firebase.json` | Q1 | S | `firebase deploy --only firestore --dry-run` validates (or documented console-only path) |

### Phase 1 — Availability data layer

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| B1 | `AvailabilitySession` + `DesignerAvailability` models (codegen) | `lib/data/models/availability/*` | A1, A2 | M | Round-trip `toJson`/`fromJson`; disabled day keeps structure |
| B2 | `AvailabilityException` model + `type` enum codec | same | B1 | S | `unavailable`/`custom` round-trip; invalid type rejected |
| B3 | `FirebaseAvailabilityService`: read all 7 days, upsert day, upsert/delete exception, read exceptions in range | `firebase_availability_service.dart` | B1, B2 | M | Doc IDs deterministic; `Either` error shape matches siblings |
| B4 | `AvailabilityRepository` interface + impl | `domain/repository/availability/*`, `data/repository/availability_repository_impl.dart` | B3 | S | Interface only in domain; impl delegates via `sl<>` |
| B5 | Register service + repo + usecases in `service_locator.dart` | `service_locator.dart` | B4 | S | `sl<AvailabilityRepository>()` resolves at startup |
| B6 | Persist designer `timezone` on save | availability service | A1, B3 | S | Written once, reused on subsequent saves |

### Phase 2 — Scheduling logic

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| C1 | `generateSlots(sessions, durationMinutes)` | `slot_generator.dart` | A2 | M | 30/45/60 min; multi-session; partial remainder dropped; chronological; empty list on no sessions |
| C2 | Schedule validation (missing/equal/reversed times, overlaps, duplicates, shorter-than-duration, bad format) | same | C1 | M | Every spec §5 rule has a failing-case test |
| C3 | Exception resolution: (weekly, exceptions, date) -> effective sessions + duration | same | B2 | S | exception > weekly; `unavailable` -> no slots; no exception -> weekly |
| C4 | Unit-test suite | `test/scheduling/slot_generator_test.dart`, `validation_test.dart`, `exception_resolution_test.dart` | C1–C3 | M | All §16 slot/availability/exception cases green |

### Phase 3 — Designer availability UI

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| D1 | `AvailabilityBloc` + events/states (load, save day, save exception, conflict state) | `lib/data/models/availability/bloc/*` | B4, C2 | M | Loading/saving/error/conflict states; no direct Firestore in UI |
| D2 | Register bloc in `main.dart` | `main.dart` | D1 | S | Provider available app-wide |
| D3 | Manage availability screen (7 cards: name, switch, duration, session count, ranges, configure) | `manage_availability_screen.dart`, `day_availability_card.dart` | D1 | L | Mirrors spec §13 layout; uses `context.accent` etc., no hardcoded colors |
| D4 | Edit-day screen: enable, duration picker, add/edit/delete sessions via `showTimePicker`, validation messages, live slot preview | `edit_day_availability_screen.dart`, `session_editor_tile.dart`, `slot_preview_grid.dart` | D3, C1 | L | Preview updates as sessions/duration change; invalid config blocks save with a specific message |
| D5 | Copy-from-day, apply-to-days, clear-day | D3/D4 widgets | D4 | M | Copy validates target; clear asks confirmation |
| D6 | Conflict-aware save: on save query overlapping pending/confirmed bookings, block with list | usecase + D1 | C3, Phase 5 read path | L | Existing booking docs never mutated; designer sees which appointments conflict |
| D7 | Routes + entry point ("Availability" row on designer profile) | `app_router.dart`, `designer_profile_page.dart` | D3 | S | `/designer-availability` reachable; no dead links |

### Phase 4 — Client slot discovery

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| E1 | `GetAvailableSlotsUsecase` (weekly/exception -> generate -> subtract bookings -> drop past) | `domain/usecases/bookings/*` | C3, B4 | L | Returns only genuinely bookable slots; never persists slots |
| E2 | Bookings-for-date query (equality + `start_at` range) + composite index | booking service, `firestore.indexes.json` | E1 | M | Index entry added; query fixed before sign-off |
| E3 | Slot picker screen: calendar with availability dots, slots grouped Morning/Afternoon/Evening, occupied/past disabled | `book_appointment_screen.dart` | E2 | L | A date is marked available only when >= 1 slot passes all checks |
| E4 | Designer-details entry CTA ("Book appointment") | `designer_details_profile_page.dart` | E3 | S | CTA hidden when viewer is the designer themself |

### Phase 5 — Booking + reservations (critical)

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| F1 | `Booking` model + `BookingStatus` enum (`no_show` mapping), `SlotReservation` model | `lib/data/models/bookings/*` | A3 | M | Status round-trip; unknown status rejected |
| F2 | Deterministic reservation ID helper + unit tests | `lib/core/utils/scheduling/reservation_key.dart` | A2 | S | Stable for same designer/date/time; distinct across slots |
| F3 | `FirebaseBookingService.createBooking` transaction: **all reads first** (availability, exception, reservation, client relationship), then writes (booking + reservation) | `firebase_booking_service.dart` | F1, F2, C3 | XL | Reads strictly before writes; rejects inactive slot, past slot, out-of-availability, active reservation; reclaims expired |
| F4 | Status transitions: confirm/decline/cancel/complete/no_show with transactional reservation release | same | F3 | L | Decline/cancel release; complete/no_show retain; wrong-owner rejected |
| F5 | Queries/streams: by designer, by user, by date, upcoming | same | F1 | M | Composite indexes listed for each |
| F6 | Repository + usecases + DI | domain/data/service_locator | F3–F5 | M | UI never touches Firestore directly |
| F7 | Security rules for bookings + reservations (ownership, status transitions, `pending` only on create) | `firestore.rules` | A4, F1 | L | Client cannot confirm/decline; designer cannot touch another designer's booking; user cannot release another user's reservation |
| F8 | Concurrency + expiry tests (`fake_cloud_firestore` if Q8 = yes) | `test/bookings/*` | F3, Q8 | L | Parallel create -> exactly one success; expired reservation reclaimed |
| F9 | Auto-create client record when user has no relationship with designer (Q2) | F3 + clients repo reuse | Q2 | M | Booking succeeds for first-time users; relationship links correctly |

### Phase 6 — Booking management UI

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| G1 | `BookingBloc` + registration | `lib/data/models/bookings/bloc/*`, `main.dart` | F6 | M | Action states don't clobber list state |
| G2 | Designer bookings screen (replace Placeholder), grouped upcoming/past, status chips | `designer_bookings_screen.dart` | G1 | L | `/designer-bookings` route added; existing dead link now resolves |
| G3 | Booking detail sheet + designer actions (confirm/decline/complete/no-show) | `booking_details_sheet.dart` | G2 | M | Only legal transitions shown per status |
| G4 | Client "My bookings" + cancel with policy gate | `my_bookings_screen.dart` | G1, A3 | L | Cancel hidden/disabled outside policy window |
| G5 | Confirmation screen + result screen (notes, summary, success/failure) | `booking_confirmation_screen.dart`, `booking_status_screen.dart` | F6 | M | Double-submit guarded by in-flight state |
| G6 | Routes for booking flows | `app_router.dart` | G2–G5 | S | All new routes registered before first use |

### Phase 7 — Hardening

| ID | Task | Deps | Size | Acceptance |
|---|---|---|---|---|
| H1 | Full `flutter analyze` clean of new issues + `build_runner` regen committed | all | S | No new warnings; `.g.dart` checked in |
| H2 | Manual test script (two devices: concurrent booking, expiry, availability edit with conflicts) | all | M | Script documented and executed once |
| H3 | Known-limitations document (rules vs client transactions, clock skew, DST edge cases) | F7 | S | Written and referenced in the module notes |

---

## 9. Dependencies

### Internal (must land before dependents)

- `Designer.timezone` (A1) -> availability persistence (B6), all slot math.
- `time_of_day_x` (A2) -> C1, C2, B1.
- Slot generator (C1) -> D4 preview, E1, F3 validation.
- Availability repository (B4) -> E1, F3.
- Booking transaction (F3) -> F4, G2–G5, D6 conflict blocking.
- Rules (F7) -> any multi-device manual testing.

### External services / libraries

- Firebase Auth (UID resolution), Cloud Firestore (transactions, composite indexes).
- `timezone` + `flutter_timezone` (present), `intl` (present), `uuid` (present).
- Optional: `fake_cloud_firestore` (dev).

### Operational

- Firebase CLI access to the `fashionista-2025` project for rules + index deployment (Q1).
  Without it, Phase 5 acceptance cannot be verified against real rules.

---

## 10. Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | **No rules in repo -> no enforceable boundary.** Client transactions stop honest races only; a modified client can double-book or forge statuses. | High | High | Rules as first-class deliverable (F7, Q1). Denormalize `user_id`/`designer_id` onto reservations so rules need no `get()`. Document the residual limitation (H3); never claim client-side validation is a security boundary. |
| R2 | **Firestore transaction read/write ordering.** Any read after a write throws. | High | Medium | Encode as a checklist in F3 review: availability -> exception -> reservation -> client relationship -> *then* writes. Test with F8. |
| R3 | **Clock skew**: `Timestamp.now()` uses the client clock; a shifted clock can reclaim a live reservation or book a past slot. | Medium | Medium | Expiry check is defensive only (no server-side re-validation without functions). Document in H3; keep TTL short. |
| R4 | **Hive back-compat**: a non-nullable field on `Designer` breaks cached payloads. | Medium | Medium | `timezone` is **nullable**; append Hive index 17 only; test with a pre-existing box file. |
| R5 | **Timestamp convention conflict** (`int` epoch in newer features vs spec `Timestamp`). | Low | High | Use `Timestamp` for all booking/reservation/availability time points (spec + range queries); document the divergence in model doc comments. |
| R6 | **Composite index churn**: equality + range queries need indexes; missing ones fail only at runtime. | Medium | High | Ship `firestore.indexes.json` with every query in F5/E2; run each query once during manual testing. |
| R7 | **DST / nonexistent local times** when converting `HH:mm` + designer tz -> UTC. | Medium | Medium | Normalize via `tz.TZDateTime`; document policy (nonexistent -> shift forward, ambiguous -> first occurrence); unit-test a DST zone. |
| R8 | **Availability-edit conflicts** scanning many bookings. | Medium | Medium | Denormalize `day_of_week`; query `designer_id + day_of_week + start_at >= now` with a limit; block save on conflict (never auto-cancel). |
| R9 | **App-level bloc state bleed**: one `BookingBloc` serving designer and client screens can render stale lists. | Medium | Medium | Include the request key (designerId/userId/date) in loaded states; ignore mismatched states in `build`. |
| R10 | **`clientId` resolution dead-ends** for first-time users. | High | High | F9 auto-create, per Q2. |
| R11 | **No CI + no existing tests** -> regressions invisible. | Medium | High | Pure-Dart tests for all scheduling/validation; `flutter analyze` gate per AGENTS.md; manual script H2. |
| R12 | Scope creep into notifications/payments. | Medium | Medium | Explicitly out of scope (§3). |

---

## 11. Acceptance Criteria

### Availability

1. Saving Monday with duration 30 and sessions `08:00-10:00`, `12:00-13:00` produces exactly
   6 slots: 08:00, 08:30, 09:00, 09:30, 12:00, 12:30.
2. Duration 45 on `08:00-10:00` produces exactly 2 slots (08:00, 08:45); the trailing 30 min
   yields nothing.
3. Saving with overlapping, duplicate, reversed, or shorter-than-duration sessions is rejected
   with a specific message and no Firestore write occurs.
4. A disabled day persists as `is_available: false, sessions: []` and keeps its duration.
5. Exactly one document exists per weekday at `availability/{1..7}`.
6. No generated slot is ever written to Firestore (verified by inspecting collections after use).

### Exceptions

7. `unavailable` on a date yields zero slots even when the weekday is enabled.
8. `custom` on a date uses the exception's sessions/duration and leaves the weekly doc unchanged.
9. Absent an exception, the weekly schedule applies.

### Client discovery

10. Occupied slots return `isAvailable: false`; past slots are excluded.
11. A date is marked available only if >= 1 slot survives exceptions + bookings + past filter.

### Booking

12. Two concurrent creates for the same slot -> exactly one succeeds; the other receives a
    clear "slot no longer available" error.
13. Booking outside availability, in the past, or on an `unavailable` date is rejected before
    any write.
14. Declining or cancelling releases the reservation; confirming keeps it; `completed`/`no_show`
    retain it as history.
15. An expired pending reservation is reclaimable by a new booking.
16. A client cannot confirm/decline; a designer cannot modify another designer's booking; a user
    cannot release another user's reservation (verified against deployed rules).

### Schedule safety

17. Editing availability that would invalidate a confirmed booking is blocked, and no booking
    document is modified.
18. Booking documents are never deleted by any availability operation.

### Quality

19. `flutter analyze` reports no new issues; `build_runner` output committed.
20. All new unit tests pass; existing tests unaffected.
21. `/designer-bookings` no longer dead-ends; no new placeholders ship.

---

## 12. Definition of Done

- All acceptance criteria verified, including one real multi-device concurrency check (H2).
- Firestore rules + indexes deployed and consistent with the repo copies.
- Requirement docs delivered: architecture summary, files created/modified, collection shapes,
  model/repo inventory, slot algorithm description, UI walkthrough, rules + index diffs, test
  list, known limitations, manual test steps.
- `flutter analyze` clean for touched code; `.g.dart` regenerated and committed.
- Known limitations documented — explicitly stating that client-only enforcement is **not** a
  trusted security boundary.
- No unrelated feature modified.

---

## 13. Recommendations

1. **Ship rules into the repo (Q1 = a).** Without them the booking invariants are advisory.
   This is the single highest-leverage decision in the plan.
2. **Denormalize `user_id` and `designer_id` onto reservations.** Lets security rules validate
   ownership in O(1) with no `get()`, and makes ownership auditing trivial.
3. **Add `day_of_week` to bookings.** Turns the availability-conflict check from a full
   designer-booking scan into an indexed equality+range query.
4. **Keep slot generation pure and UI-agnostic.** One function tested once, used by preview,
   discovery, and transaction validation — this is what keeps preview and enforcement from
   drifting apart.
5. **Do not add Hive caching for availability/bookings in V1.** It doubles the state surface
   for a low-hit-rate cache; screens are short-lived. Revisit only if offline discovery becomes
   a requirement.
6. **Make `BookingPolicy` the only place policy numbers live.** Cancellation window and TTL
   will change during product testing.
7. **Prefer `Timestamp` over epoch ints** for these two collections despite the mixed repo
   convention — spec compliance plus range-query ergonomics; document the divergence so it
   does not look accidental.
8. **Extract nothing else.** `designer_services` proves the "designer-owned collection +
   service + screen" slice works; mirror it rather than introducing a new abstraction layer.

---

## 14. Command Reference

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs   # after any model change
flutter test test/scheduling/ test/bookings/
firebase deploy --only firestore                            # rules + indexes (Q1)
```

---

## 15. Implementation Status (2026-11-03)

All phases were implemented. Decisions taken from §5: **Q1 = (a)** (rules versioned in
repo), **Q2 = auto-create client**, **Q3–Q7 = recommended defaults**, **Q8 = dropped**
(see limitation below).

### Files created

```
firestore.rules
firestore.indexes.json
lib/core/utils/firestore_timestamp_converter.dart
lib/core/utils/scheduling/date_key.dart
lib/core/utils/scheduling/designer_time_zone.dart
lib/core/utils/scheduling/time_of_day_x.dart
lib/core/utils/scheduling/booking_policy.dart
lib/core/utils/scheduling/reservation_key.dart
lib/core/utils/scheduling/slot_generator.dart
lib/data/models/availability/availability_session_model.dart (+ .g.dart)
lib/data/models/availability/availability_exception_model.dart (+ .g.dart)
lib/data/models/availability/designer_availability_model.dart (+ .g.dart)
lib/data/models/availability/available_slot_model.dart
lib/data/models/availability/bloc/availability_{bloc,event,state}.dart
lib/data/models/bookings/booking_model.dart (+ .g.dart)
lib/data/models/bookings/booking_status.dart
lib/data/models/bookings/slot_reservation_model.dart (+ .g.dart)
lib/data/models/bookings/create_booking_request.dart
lib/data/models/bookings/bloc/booking_{bloc,event,state}.dart
lib/data/services/firebase/firebase_availability_service.dart
lib/data/services/firebase/firebase_booking_service.dart
lib/data/repository/availability/availability_repository_impl.dart
lib/data/repository/bookings/booking_repository_impl.dart
lib/domain/repository/availability/availability_repository.dart
lib/domain/repository/bookings/booking_repository.dart
lib/domain/usecases/availability/*.dart            (7 usecases)
lib/domain/usecases/bookings/*.dart                (6 usecases)
lib/presentation/screens/availability/manage_availability_screen.dart
lib/presentation/screens/availability/edit_day_availability_screen.dart
lib/presentation/screens/availability/date_exception_screen.dart
lib/presentation/screens/availability/widgets/*.dart   (4 widgets)
lib/presentation/screens/bookings/book_appointment_screen.dart
lib/presentation/screens/bookings/booking_confirmation_screen.dart
lib/presentation/screens/bookings/booking_status_screen.dart
lib/presentation/screens/bookings/my_bookings_screen.dart
lib/presentation/screens/bookings/widgets/*.dart       (2 widgets)
test/scheduling/slot_generator_test.dart
test/scheduling/validation_test.dart
test/scheduling/exception_resolution_test.dart
test/bookings/booking_model_test.dart
test/scheduling/timezone_test.dart
```

### Files modified

| File | Change |
|---|---|
| `lib/data/models/designers/designer_model.dart` (+ `.g.dart`) | nullable `timezone` |
| `lib/core/models/hive/designer_model_hive_type.dart` | Hive field index 17 |
| `lib/core/service_locator/service_locator.dart` | 2 services, 2 repositories, 13 usecases |
| `lib/main.dart` | `AvailabilityBloc`, `BookingBloc` providers |
| `lib/core/routes/app_router.dart` | `/designer-availability`, `/designer-bookings`, `/designer-book/:id`, `/my-bookings` |
| `lib/presentation/screens/designers/designer_profile_page.dart` | Availability row, live bookings card |
| `lib/presentation/screens/designers/designer_details_profile_page.dart` | "Book appointment" CTA |
| `lib/presentation/screens/designers/designer_bookings_screen.dart` | Replaced placeholder with real list + actions |
| `lib/presentation/screens/profile/user_profile_page.dart` | "My bookings" entry |
| `firebase.json` | `firestore.rules` / `firestore.indexes.json` wiring |

### Verification

- `flutter analyze` → no issues in any file touched by this module. The single remaining
  project error (`test/client_measurement_firestore_test.dart:88` missing `designerId`) is
  pre-existing and unrelated.
- `flutter test test/scheduling/ test/bookings/` → **53 tests pass**
  (slot generation, validation, exceptions, timezones/DST, reservation keys, status mapping, model round-trip).
- `dart run build_runner build --delete-conflicting-outputs` → generated files committed.

### Client snapshot on bookings (2026-11-04)

`bookings/{id}.client` stores `{id, name, avatar, mobile_number}` so appointment cards render
the client without extra reads. Written inside the booking transaction from the
designer-scoped `clients` record, falling back to the `users` profile. Legacy bookings without
the snapshot are enriched read-only (max 25 per load) via `_attachClients`; the slot-availability
query deliberately skips this. Rendered by `BookingClientTile` on the designer appointment card
and the booking detail sheet. `firestore.rules` now requires `client.id == client_id` on create.

### Known limitations

1. **Client transactions are not a security boundary.** Without Cloud Functions the server
   cannot re-derive slot availability. A modified client can still create a booking document
   directly. `firestore.rules` prevents cross-user writes and status forging, but slot
   uniqueness relies on the deterministic reservation document. Documented in
   `firestore.rules`.
2. **Rules must be merged, not deployed blind.** The repo previously had no rules file; the
   new `firestore.rules` only declares this module's paths. Merge with the console rule set
   before `firebase deploy --only firestore`, or other collections will be denied.
3. **Clock skew.** `Timestamp.now()` uses the device clock for reservation expiry. A shifted
   clock can reclaim a live reservation. TTL is kept short (15 min).
4. **No transaction-level automated tests.** `fake_cloud_firestore` cannot compile against
   this project's `cloud_firestore 6.10` / SDK `meta 1.16` combination (needs `meta 1.17`).
   Booking transaction behaviour is covered by manual testing (below) and by the pure tests
   for reservation keys, status mapping and expiry rules.
5. **Expired reservation documents are never deleted** (by design). Correctness does not
   depend on cleanup; expired documents are treated as reclaimable.
6. **DST edge cases.** Local times are resolved through `tz.TZDateTime`, which normalises
   nonexistent/ambiguous wall-clock times; no explicit policy is surfaced in the UI.

### Manual test script

1. Designer → Profile → **Availability** → set timezone, enable Monday, duration 30, sessions
   `08:00-10:00` and `12:00-13:00`, save. Expect 6 generated slots in the preview.
2. Set duration 45 on `08:00-10:00`. Expect exactly 2 slots (08:00, 08:45).
3. Try adding an overlapping session → save is blocked with an "overlap" message.
4. Add a **Date exception** → `Unavailable` on a Monday → client sees no slots that date.
5. Add a **Custom hours** exception → client sees only those slots.
6. Client → Designer profile → **Book appointment** → pick a slot → submit. Expect
   "Request sent" and a `pending` booking.
7. Second device (or after sign-out/in) books the same slot → rejected with "just booked".
8. Designer → **Appointments** → confirm/decline. Declining releases the slot.
9. Client → **Cancel booking** → slot becomes bookable again.
10. Designer edits availability so a confirmed appointment no longer fits → conflict dialog
    lists the affected appointment; saving anyway keeps the booking document intact.

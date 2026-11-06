# Notification Infinite Scroll — Implementation Plan

**Status:** Planned (not implemented)
**Date:** 2026-11-06
**Related:** [notification-preferences.md](./notification-preferences.md), [push-notifications-module.md](./push-notifications-module.md)

---

## 0. Context — current state

The notification screen is **not driven by its bloc**. It renders a Hive box through a
`ValueListenableBuilder` and sorts the cached values in memory, while the network fetch
that fills that box has **no limit** — it pulls every notification the user has ever
received. Adding pagination to the bloc alone would change nothing on screen.

A partial paging path already exists from the push-notification work (`LoadNotificationsPage`
event → `_onLoadPage` → `findNotificationsPage`), but it is dead code, and its cursor is a
timestamp the spec explicitly forbids.

| # | Finding | Evidence |
|---|---|---|
| F1 | **Screen renders Hive, not bloc state** — paging cannot surface without changing this | `lib/presentation/screens/notification/notification_screen.dart:49` |
| F2 | Inbox fetch is **unbounded** — fetches the whole collection | `lib/data/services/firebase/firebase_notification_service.dart:110` |
| F3 | Paging scaffolding exists but nothing calls it | `lib/data/models/notification/bloc/notification_bloc.dart:228`, `notification_bloc_event.dart:80` |
| F4 | Cursor is `where('created_at', isLessThan: …)` — **forbidden by spec §3**; equal timestamps skip or duplicate rows | `firebase_notification_service.dart:229` |
| F5 | `hasMore = page.length >= limit` — an exactly-full last page costs an extra empty request | `notification_bloc.dart:256` |
| F6 | An empty *subsequent* page emits an empty list — would wipe the UI once consumed | `notification_bloc.dart:244` |
| F7 | `UpdateNotification` emits `NotificationLoaded(single)` — would destroy list state | `notification_bloc.dart:66` |
| F8 | The recipient field is **`to`**, not `user_id` as the spec example shows | `firebase_notification_service.dart:227` |
| F9 | Composite index `(to ASC, created_at DESC)` **already exists** | `firestore.indexes.json` |
| F10 | Models built from `doc.data()`, not `doc.id` — relies on the stored `uid` field | `firebase_notification_service.dart:239` |
| F11 | No `ScrollController`; plain `ListView.separated` | `notification_screen.dart:94` |
| F12 | Read/unread works today *because* Hive is the truth — moving to bloc state requires patching the update path | F7 |
| F13 | The home badge uses its **own** bounded stream (`limit(100)` on unread) and does not read the bloc | `lib/presentation/screens/home/home_screen.dart:86` |
| F14 | No screen-level real-time listener exists; the badge's listener is unrelated | F13 |

---

## 1. Executive summary

Move the screen's source of truth to `NotificationBloc`, rebuild the page contract around a
`DocumentSnapshot` cursor with an exact `hasMore`, and add append/refresh semantics to the
bloc. Hive demotes from truth to a first-paint cache holding only the newest page.

---

## 2. Objectives

1. First load fetches **20** notifications, newest first, through a document cursor.
2. Scrolling within 300px of the bottom appends the next 20; existing rows never disappear.
3. Loading more never triggers the full-screen loader and can be retried.
4. `hasMore` is exact — no speculative requests.
5. Item design, tap routing, read/unread and mark-all-read are unchanged.

---

## 3. Scope

**In scope** — page contract, bloc append/refresh/generation, screen rebuild on bloc state,
scroll controller, bottom loader/retry, pull-to-refresh, first-page Hive seed, tests.

**Out of scope** — document schema, push delivery, preference gating, the badge's stream,
badge counting, other screens, real-time listeners for the list.

---

## 4. Decisions

| # | Decision | Rationale |
|---|---|---|
| **D1** | **Screen reads bloc state.** `BlocBuilder<NotificationBloc, NotificationBlocState>` replaces `ValueListenableBuilder` | Only way pagination is visible; matches the app's bloc architecture. Confirmed no other consumer reads `NotificationsLoaded`/`notificationCount` (F13), so the blast radius is the screen |
| **D2** | **Pull-to-refresh added** (`RefreshIndicator`) | Spec §5 requires a refresh path; it is the natural gesture on a feed |
| **D3** | Hive holds **the first page only** | Keeps the offline cache bounded and consistent with the "first 20" contract; paging old pages into Hive would persist unlimited history and make page 1 grow on every launch |
| **D4** | Cursor is a **`DocumentSnapshot`**, never a timestamp | Spec §3; equal `created_at` values cannot skip or duplicate rows |
| **D5** | **No real-time listener** for the list | Spec §8: do not introduce streaming to support pagination. The badge keeps its own independent stream (F13) |
| **D6** | Fetch `limit + 1` and slice | Exact `hasMore` with no extra round trip |
| **D7** | `pageSize = 20` as a single const, overridable per call | Configurable without scattering literals |

### Consequences of D1

- `UpdateNotification`, `DeleteNotification` and `MarkAllNotificationsRead` must **patch the
  current list** and re-emit `NotificationsLoaded`; today they emit single-item or result
  states, which would blank the feed (F7, F12).
- The badge is untouched — it never read the bloc (F13).

---

## 5. Assumptions

- `created_at` is an int (millis) in every document; the server writes `Timestamp.now().toMillis()`.
- `uid` is present on every stored notification (the dispatcher writes it), so dedupe can key on it.
- The signed-in user id is the only filter; no role or status filters are added or removed.

---

## 6. Architecture

### 6.1 Data flow

```
screen open ─→ Hive seed (instant paint, ≤20) ─→ page 1 (21 docs)
                                                 ├─→ replace list
                                                 ├─→ store cursor
                                                 └─→ reseed Hive (first page only)

scroll < 300px ─→ LoadMoreNotifications ─→ startAfterDocument(cursor) (21 docs)
                                            ├─→ append (dedupe by uid)
                                            ├─→ update cursor + hasMore
                                            └─→ never touches Hive

pull to refresh ─→ LoadNotificationsPage(refresh: true) ─→ generation++
                                                            └─→ stale page discarded
```

### 6.2 Page contract

```dart
class NotificationPage {
  final List<NotificationModel> notifications; // ≤ pageSize
  final DocumentSnapshot? lastDocument;        // cursor of the last returned row
  final bool hasMore;                          // exact, from the +1 probe
}
```

Returned from a single query — list and cursor are always consistent.

### 6.3 Query and cursor strategy

```dart
// first page
FirebaseFirestore.instance
    .collection('notifications')
    .where('to', isEqualTo: uid)              // NOT user_id — F8
    .orderBy('created_at', descending: true)
    .limit(pageSize + 1);

// subsequent pages
   ...same... .startAfterDocument(cursor).limit(pageSize + 1);
```

- `hasMore = docs.length > pageSize`; slice to `pageSize`, so the probe row is never shown.
- The cursor is the last **returned** document.
- No secondary `orderBy` is needed for timestamp ties: Firestore positions document cursors
  by document name under a single `orderBy`.
- **No `offset()`**, no client-side slicing of a full fetch.

### 6.4 Bloc changes

| Concern | Approach |
|---|---|
| Append | Build a **new** list — `Equatable` compares list identity, so in-place mutation would not rebuild |
| Cursor | Bloc-private `DocumentSnapshot? _lastDocument` (not Equatable — not serialisable) |
| Rapid scroll | `isLoadingMore` in state + early return in the handler |
| Refresh vs in-flight | Integer `_generation`; a load-more result is dropped when the generation moved |
| Duplicate pages | `Set<String>` of `uid`; fallback key `refId:createdAt` when `uid` is null |
| Empty subsequent page | `hasMore = false`, keep the list (fixes F6) |
| Update / delete / mark-read | Patch the loaded list, re-emit `NotificationsLoaded` |

New events: `LoadNotificationsPage(uid, {refresh})`, `LoadMoreNotifications()`.
State: `NotificationsLoaded` gains `isLoadingMore` and `loadMoreError`.

### 6.5 Screen changes

- `BlocBuilder` replaces `ValueListenableBuilder`.
- `ScrollController` created in `initState`, listener added, **removed and disposed** in `dispose`.
- Threshold `position.extentAfter < 300`.
- **Short-list fill (spec §6):** after the first page renders, a post-frame callback requests
  another page when `hasMore` and the viewport is not yet scrollable — otherwise a 20-item
  page that fits the screen can never trigger the listener.
- Bottom slot inside the list: spinner while `isLoadingMore`, retry row on `loadMoreError`,
  nothing when `!hasMore`.
- `RefreshIndicator` → `LoadNotificationsPage(refresh: true)`.
- Empty state and all item widgets unchanged.

### 6.6 Hive demotion (D3)

`LoadNotificationsCacheFirstThenNetwork` stays as the first-paint seed but writes only the
first page. Pages 2..N are never persisted.

---

## 7. Implementation phases

| Phase | Work |
|---|---|
| 0 | `NotificationPage` + service rewrite (document cursor, `limit+1`, `doc.id`) |
| 1 | Bloc: append, dedupe, guards, generation, refresh, list-preserving updates |
| 2 | Screen: bloc state, scroll controller, bottom states, pull-to-refresh, short-list fill |
| 3 | Hive reduced to first-page seed |
| 4 | Tests + emulator verification |

---

## 8. Task breakdown

| ID | Task | Files | Deps | Size | Acceptance |
|---|---|---|---|---|---|
| P0.1 | `NotificationPage` model | `lib/data/models/notification/notification_page.dart` | — | S | Carries list + cursor + exact `hasMore` |
| P0.2 | Rewrite `findNotificationsPage` | `lib/data/services/firebase/firebase_notification_service.dart` | P0.1 | M | Doc cursor; `limit+1`; builds from `doc.id`; typed `Either` errors |
| P1.1 | State fields | `lib/data/models/notification/bloc/notification_bloc_state.dart` | P0.1 | S | `isLoadingMore`, `loadMoreError`; included in `props` |
| P1.2 | Append + dedupe | `notification_bloc.dart` | P1.1, P0.2 | M | Page 2 appends; no duplicates |
| P1.3 | Guards: `isLoadingMore`, `_generation`, empty page | `notification_bloc.dart` | P1.2 | M | Rapid scroll = 1 request; refresh wins over stale page |
| P1.4 | Patch update/delete/mark-read to keep the list | `notification_bloc.dart` | P1.2 | M | Read/unread still reflects with bloc as truth |
| P2.1 | Screen on bloc state + controller + bottom states | `notification_screen.dart` | P1.3 | M | Loader, retry, no scroll jump, empty state intact |
| P2.2 | Short-list post-frame fill | `notification_screen.dart` | P2.1 | S | Short first page still paginates |
| P2.3 | Pull-to-refresh (D2) | `notification_screen.dart` | P2.1 | S | Resets list + cursor; stale page discarded |
| P3.1 | First-page-only Hive seed | `notification_bloc.dart`, `hive_notification_service.dart` | P1.2 | S | Cache ≤ pageSize; offline paint works |
| P4.1 | Bloc tests | `test/notifications/notification_bloc_pagination_test.dart` | P1–P3 | M | §11 matrix |
| P4.2 | Widget tests | `test/notifications/notification_screen_pagination_test.dart` | P2 | M | Bottom loader, retry, no full-screen loader on page 2 |
| P4.3 | Emulator verification | emulator + seed script | P4.1 | S | 45 docs = 3 pages, including a timestamp tie |

**Sizes:** S ≤ 0.5 day · M ≈ 1 day. No L/XL items — the work decomposes cleanly.

---

## 9. Dependencies

Internal: `NotificationModel`, `HiveNotificationService`, `AppTheme`, `sl`, `NotificationBloc`
consumers (`lib/main.dart` registration only).
External: `cloud_firestore`, `flutter_bloc`, `equatable` — all present.
**No new packages. No new Firestore index (F9). No security-rule changes** (reads stay
recipient-scoped; pagination does not alter access).

---

## 10. Risks

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | Moving off Hive regresses read/unread | High | Medium | P1.4 patches the list; widget test asserts a toggle persists |
| R2 | Bloc is app-level; list state shared across screens | Medium | Medium | Scope pages to the signed-in uid; reset on refresh |
| R3 | Rapid scroll duplicates requests | Medium | High | `isLoadingMore` guard + generation token |
| R4 | Equal timestamps skip rows | Medium | Medium | Document cursor (D4) |
| R5 | A short page never triggers the listener | Medium | Medium | P2.2 post-frame fill |
| R6 | Hive regrows if pages are cached | Low | Medium | P3.1 first page only |
| R7 | Existing tests assert the old signature | Low | High | Update in the same change |
| R8 | Unread count derived from the page | Low | Low | Badge is independent (F13); `NotificationsLoaded` keeps accepting `unreadCount` |

---

## 11. Test matrix

| Spec item | Test |
|---|---|
| 1, 2 | Bloc: initial load requests `pageSize`; newest-first order preserved |
| 3, 4 | Bloc: load-more appends rather than replaces |
| 5 | Bloc: final page sets `hasMore=false`; no further service calls |
| 6 | Bloc: two `LoadMoreNotifications` while loading → one service call |
| 7, 8 | Bloc: failure keeps the list, sets `loadMoreError`; retry succeeds |
| 9, 10 | Bloc: refresh resets the cursor; stale page discarded via generation |
| 11 | Bloc + widget: empty collection → `NotificationsEmpty` |
| 12 | Bloc: overlapping ids appended once |
| UI | Widget: spinner while loading more; retry row; no full-screen loader on page 2 |
| Cursor | Service: `startAfterDocument` used; no timestamp cursor remains |

---

## 12. Acceptance criteria

- First load issues one query limited to 21 documents; 20 are shown.
- Scrolling within 300px appends page 2; page-1 rows stay rendered and unchanged.
- A rapid scroll burst issues **one** page request.
- `hasMore` is false right after the last page — no trailing empty request.
- A failed page-2 request keeps page 1 visible and offers a retry that works.
- Pull-to-refresh replaces the list and discards an older in-flight page.
- Empty collection shows the existing empty UI.
- Read/unread and delete still work with Hive no longer the truth.
- `flutter analyze` clean for touched files; Dart and Functions suites pass.

## 13. Definition of done

All acceptance criteria met; no schema change; no new index; the old timestamp-cursor path
**removed**, not left beside the new one; this plan's §17 records files, query strategy,
index status, tests and limitations; `flutter analyze` clean for touched files.

---

## 14. Deployment & manual steps

- **No Firestore deploy required** for the query — index `(to ASC, created_at DESC)` is already
  declared and live (F9).
- No rules change.
- No data migration.
- Verify against the emulator with ~45 seeded notifications across three pages, including two
  documents sharing a `created_at` value.

## 15. Final report contents

At completion: summary of changes; files created/modified; pagination explanation; query and
cursor strategy; index status (none added); tests executed with results; any limitations found
(e.g. Hive cache now holds only the newest page).

---

## 16. Sequencing recommendation

1. **P0.2 + P1.2 first** — cursor correctness and append semantics carry all the risk and are
   UI-independent.
2. **P1.4 before P2.1** — read/unread must survive the switch to bloc state; doing it after the
   screen move means debugging two changes at once.
3. **Remove the dead path** in the same change that introduces the new one.
4. **P2.2 and P2.3 last** — polish that is easy to verify once paging works.

---

## 17. Implementation record

Status: **implemented** (`flutter analyze` clean on touched paths, 98 notification tests green,
149 cloud-function tests green, 7/7 emulator pagination checks green).

### Files created

| File | Purpose |
| --- | --- |
| `lib/data/models/notification/notification_page.dart` | `NotificationPage{notifications, cursor, hasMore}` page contract |
| `test/notifications/notification_bloc_pagination_test.dart` | 15 bloc tests (initial append, dedupe, refresh race, failure retention) |
| `test/notifications/notification_screen_pagination_test.dart` | 7 widget tests (scroll trigger, footer states, pull-to-refresh, viewport fill) |

### Files modified

| File | Change |
| --- | --- |
| `lib/data/services/firebase/firebase_notification_service.dart` | `findNotificationsPage()` with document cursor + `limit+1` probe; unbounded `findNotificationsFromFirestore()` removed |
| `lib/data/models/notification/bloc/notification_bloc_event.dart` | `LoadNotificationsPage`, `LoadMoreNotifications`; `LoadNotifications` / `LoadNotificationsCacheFirstThenNetwork` removed |
| `lib/data/models/notification/bloc/notification_bloc_state.dart` | `NotificationsLoaded{isLoadingMore, loadMoreError, copyWith}` |
| `lib/data/models/notification/bloc/notification_bloc.dart` | paging state machine, generation guard, list-preserving update/delete/mark-read, injected `userIdProvider` |
| `lib/presentation/screens/notification/notification_screen.dart` | `BlocConsumer` on bloc state, `ScrollController` listener, footer slot, `RefreshIndicator`, viewport fill |

### Cursor strategy

`NotificationPage.cursor` is an **opaque `Object?`** holding the last `DocumentSnapshot` of the
page. The service casts it (`if (cursor is DocumentSnapshot<Map<String, dynamic>>)`) and calls
`startAfterDocument`; the opaque type keeps the bloc testable without a live Firestore. Fetching
`limit + 1` documents makes `hasMore` exact (`docs.length > limit`) with no extra request, and the
probe document is discarded from the returned list.

Query: `collection('notifications').where('to', isEqualTo: uid).orderBy('created_at',
descending: true).limit(limit + 1)` — the recipient field is `to`, not `user_id`.

### Index status

None added. `firestore.indexes.json` already declares `notifications (to ASC, created_at DESC)`.

### Emulator verification

45 notifications seeded for one recipient, three pages, with **two documents sharing a
`created_at` value positioned exactly on the page-1/page-2 boundary**:

- 3 pages of 20/20/5, 45 unique documents, ascending-free descending order preserved.
- No duplicates and nothing skipped across the tie.
- Control run using a timestamp-only cursor **silently drops the tied document** (`n_20`),
  confirming why the snapshot cursor is required rather than `startAfter(timestamp)`.

### Behaviour decisions made during implementation

- **No auto-retry after a failed page.** The scroll listener fires on every tick, so an unguarded
  retry cleared the error row before it could be read (and hammered the backend). The listener now
  bails when `loadMoreError != null`; recovery is the explicit `Retry` action.
- **Viewport fill** (`_fillViewport`) is guarded by `_autoFilledLength` so a short first page loads
  page 2 once, and never re-dispatches on later emissions, during a page load, or after a failure.
- **`userIdProvider`** is injected (defaults to `FirebaseAuth.currentUser?.uid`), which is what
  makes the bloc testable.
- `Equatable` compares lists by identity, so every append/refresh builds a new list.

### Known limitations

- The Hive cache now seeds **only the newest page**; older pages are network-only by design.
- `_fillViewport` uses `maxScrollExtent == 0` as its "did not fill" signal, which is exact for the
  current fixed-height cards but would over-fetch slightly if card heights became highly variable.
- Removing `await bloc.close()` from widget-test teardown is deliberate: closing a bloc with a
  handler awaiting a pending future deadlocks under `FakeAsync`.

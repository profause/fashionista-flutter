# Plan — Paginate the Trends (Discover) feed with load-more

Status: **implemented** · Scope owner: Trends / Home feed · Follows the pattern established in
`.agents/plans/notification-infinite-scroll.md`.

---

## 1. Executive Summary

The Home → **Discover** tab currently renders the entire local Hive box of trends in a
`MasonryGridView` nested inside a `SliverToBoxAdapter` with `shrinkWrap: true` and
`NeverScrollableScrollPhysics`. That construction defeats lazy building and gives the feed no
reliable scroll extent, so nothing can trigger "load the next page".

At the same time the network call that fills that box, `FirebaseTrendsService.fetchTrends(int limit)`,
**ignores its `limit` argument** and reads the whole collection, then issues **two extra queries per
trend** (`isLikedTrend`, `isFollowedTrend`) whose results the feed card never renders.

This plan paginates the Discover feed with a cursor over `created_at` and a lazy sliver masonry
grid, keeping the Hive box as the persistent feed store (cache-first paint, pages appended into
Hive) and moving the pagination state machine into a dedicated bloc.

---

## 2. Objectives

1. Fetch trends in pages of 20, newest first, using a Firestore document cursor (no `offset()`).
2. Load the next page automatically as the user approaches the end of the feed.
3. Append pages to the existing list without reloading or reordering what is already shown.
4. Render the feed with a **lazy** sliver grid so only visible cards are built.
5. Stop requesting when the server reports no more data.
6. Keep the cache-first experience: cached items paint instantly, network refreshes behind them.
7. Show a footer loader, a bottom retry on failure, and an empty state — without blanking the list.
8. Support pull-to-refresh that resets the cursor and reloads the newest page.
9. Remove the unbounded read and the dead code paths that keep it reachable.

---

## 3. Scope

### In scope

- `DiscoverTrendsPage` (Home tab "Discover") — the trends feed.
- New `TrendFeedBloc` + state/events for the paginated feed.
- Paged fetch through the existing layers: service → repository → usecase.
- `SliverMasonryGrid`-based feed rendering, lazy, with a load-more sentinel and footer slot.
- Removal of the unbounded `fetchTrends`, the two per-card flag lookups, and the three dead
  trend screens that would otherwise keep the old contract alive.
- Unit tests for the bloc and widget tests for the feed.

### Out of scope

- **For You → "My Posts"** (`LoadTrendsCacheForYouPage`). It is bounded by the signed-in user's own
  posts and already reads Hive; it keeps working unchanged against the same box.
- **Search by tag** (`interest_details_screen.dart` → `fetchTrendsByTag`, client-side filter over
  100 documents). Separate bounded query; noted as a follow-up.
- `trend_details_screen.dart`, comments, likes/follows behaviour, notification widgets.
- Any change to the `trends` document schema or to `firestore.rules`.
- Real-time listeners on the whole collection (deliberately not introduced).

---

## 4. Decisions

Confirmed with the user:

| # | Decision |
| --- | --- |
| **D1** | Paginate the **Discover feed only**. |
| **D2** | **Keep the Hive box as the feed source** — cache-first paint, network pages appended into Hive. |
| **D3** | **Drop** `isLiked` / `isFollowed` resolution for feed cards (not rendered there). |
| **D4** | Default page size **20**, configurable via a named parameter. |

Design decisions taken while planning:

| # | Decision | Rationale |
| --- | --- | --- |
| **D5** | Pagination metadata (cursor, `hasMore`, loading/error flags) lives in the **bloc**; the item list is a **projection of the Hive box** emitted into state. | D2 keeps Hive as the store, but a single state slice keeps the UI simple and testable, and lets one place own "what is currently in the feed". |
| **D6** | Cursor is the **`DocumentSnapshot` of the last document of the last fetched page** (same as notifications) — *not* a keyset `(createdAt, uid)` cursor. | Hive accumulates across sessions, so the number of visible items can exceed the walked cursor chain. Fix that with **duplicate-page auto-continue** (§5.4) instead of coupling the cursor to local sort order and risking an index requirement. |
| **D7** | Local ordering is `createdAt` **DESC**, tie-broken by `uid` **ASC**. | Mirrors Firestore's `created_at DESC` + implicit `__name__ ASC`, so appended pages land in the visually correct place. |
| **D8** | Load-more is driven by a **sentinel sliver at the end of the feed**, not by a `ScrollController` listener. | The feed lives inside `NestedScrollView` + `TabBarView`; a sentinel is nesting-independent, needs no controller lifecycle, and handles short lists for free. |
| **D9** | New **`TrendFeedBloc`** rather than extending `TrendBloc`. | `TrendBloc` is an app-level singleton already serving single-trend reads, CRUD *and* My Posts. A paginated feed state replacing the shared state would be clobbered whenever My Posts dispatches. A second bloc per concern has precedent (`TrendCommentBloc`). |
| **D10** | Delete the dead trend screens instead of porting them. | `TrendsScreen`, `TrendsSliver`, `DiscoverTrendsScreen` are unreachable (routes of those names build `HomeScreen`); keeping them means keeping the old unbounded contract alive. |

---

## 5. Architecture Impact

### 5.1 Current flow (to be replaced)

```
DiscoverTrendsPage.initState
  └─ TrendBloc.add(LoadTrendsCacheFirst(limit: 10))
        ├─ HiveTrendService.getItems("")            → emit TrendsLoaded(cache)
        └─ FirebaseTrendsService.fetchTrends(10)    → WHOLE collection + 2N queries
              └─ HiveTrendService.insertItems(...)  → box grows forever

DiscoverTrendsPage.build
  └─ BlocBuilder<TrendBloc>                        (used only for a spinner)
        └─ ValueListenableBuilder<Box<TrendFeedModel>>
              └─ box.values.toList()..sort(createdAt desc)   ← entire cache, every change
                    └─ TrendsStaggeredView → MasonryGridView(shrinkWrap, never-scroll)  ← builds ALL cards
```

### 5.2 Target flow

```
DiscoverTrendsPage.initState → TrendFeedBloc.add(TrendFeedOpened())

TrendFeedBloc
  ├─ subscribes to HiveTrendService.itemListener()
  │     └─ emits items = box.values sorted (createdAt DESC, uid ASC)
  ├─ TrendFeedOpened  : emit cache projection (isLoadingInitial) → fetch page 1 → merge → emit
  ├─ TrendFeedLoadMore: guard → fetch page N+1 with cursor → merge → emit → maybe auto-continue
  ├─ TrendFeedRefresh : reset cursor → fetch page 1 → merge → emit  (generation-guarded)
  └─ TrendFeedRetry   : clear error → trendFeedLoadMore()
```

### 5.3 Data layer

| Layer | Change |
| --- | --- |
| `FirebaseTrendsService` | Add `fetchTrendsPage({int limit = 20, Object? cursor}) → Either<String, TrendFeedPage>`; **remove** `fetchTrends` and `fetchTrendsWithFilter` (both unbounded / unused). |
| `TrendFeedPage` (new model) | `{List<TrendFeedModel> trends, Object? cursor, bool hasMore}` — opaque cursor, same contract as `NotificationPage`. |
| `TrendRepository` / `trend_feed_repository_impl.dart` | Replace `fetchTrends()` with `fetchTrendsPage({limit, cursor})`. |
| Domain usecase | New `find_trend_feed_page_usecase.dart`; remove `find_trends_usecase.dart` once `LoadTrends` is gone. |
| `HiveTrendService` | Add `List<TrendFeedModel> getSortedItems()` implementing D7 so ordering exists in exactly one place. |

Query:

```dart
FirebaseFirestore.instance
    .collection('trends')
    .orderBy('created_at', descending: true)
    // No where() clause: the whole public feed. `created_at` is stored as
    // epoch milliseconds, not a Timestamp.
    .startAfterDocument(cursor as DocumentSnapshot)   // only when cursor != null
    .limit(limit + 1)                                 // probe for an exact hasMore
    .get();
```

`created_at` is written as `DateTime.now().millisecondsSinceEpoch` by `add_trend_screen.dart`, so
documents without that field never appear — unchanged from today.

### 5.4 Duplicate-page auto-continue (the D2/D6 fix)

Because Hive keeps everything it has ever fetched, a cold start can show 60+ items while the
session's cursor only covers the newest 20. Requesting "the page after #20" returns documents that
are already in the box, so nothing visibly grows and the user stalls at the bottom.

Rule: after merging a page, if **no new document was added** and `hasMore` is still true, request
the next page immediately, up to **5 consecutive fully-duplicate pages** per trigger. The sentinel
then simply re-arms on the next scroll. This keeps pagination correct without coupling the cursor
to the local sort order, and prevents a runaway loop.

### 5.5 Rendering

`TrendsStaggeredView` (shrink-wrapped, non-lazy) is replaced for the feed by a real sliver:

```dart
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  sliver: SliverMasonryGrid.count(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childCount: items.length,
    itemBuilder: (context, index) => TrendInfoCardWidget(
      key: ValueKey(items[index].uid),
      trendInfo: items[index],
      aspectRatio: 3 / 4,
    ),
  ),
)
```

`SliverMasonryGrid` (`flutter_staggered_grid_view: ^0.7.0`, already a dependency) is a real
`SliverMultiBoxAdaptorWidget`, so cards build lazily and the scroll view gets a true extent.
`TrendInfoCardWidget` is reused untouched — it is already stateless and does no per-card fetching.

---

## 6. Implementation Plan

### Phase 0 — Baseline

- `flutter analyze lib` (expect the 70 known issues), `flutter test`, and record the current
  rendering behaviour of the Discover tab on a device/emulator for later comparison.

### Phase 1 — Data layer

1. Add `TrendFeedPage` (limit+1 probe → exact `hasMore`, opaque cursor).
2. Add `FirebaseTrendsService.fetchTrendsPage` — one query, no per-document flag lookups (D3).
3. Extend the repository + add `FindTrendFeedPageUsecase`; register in `service_locator.dart`.
4. Add `HiveTrendService.getSortedItems()` (D7).
5. Delete `fetchTrends`, `fetchTrendsWithFilter`, `FindTrendsUsecase`.

### Phase 2 — Feed bloc

6. `TrendFeedState`: `items`, `isLoadingInitial`, `isLoadingMore`, `hasMore`, `loadMoreError`,
   `initialError`, `pagesLoaded`, `fromCache` + `copyWith` (all fields in `props`).
7. `TrendFeedEvent`: `TrendFeedOpened`, `TrendFeedLoadMore`, `TrendFeedRefresh`, `TrendFeedRetry`,
   and an internal `TrendFeedCacheChanged`.
8. `TrendFeedBloc`: cursor + generation guard, dedupe by `uid`, cache-changed re-projection,
   bounded duplicate-page auto-continue, list-preserving failures.
9. Register the bloc in `main.dart`'s `MultiBlocProvider`.

### Phase 3 — Screen

10. Rewrite `DiscoverTrendsPage` as a `CustomScrollView` over `TrendFeedBloc` state:
    - `SliverMasonryGrid` feed (lazy) → sentinel sliver → footer slot (spinner / retry / nothing).
    - `RefreshIndicator` → `TrendFeedRefresh()`; keep the existing FAB hide-on-scroll behaviour.
    - Empty and initial-error states reuse the current styling; a failed page keeps the list and
      shows the bottom retry.
11. Remove the `ValueListenableBuilder<Box>` and the `BlocListener` that re-shows the refresh
    indicator on every `TrendLoading`.

### Phase 4 — Cleanup

12. Delete `trends_screen.dart`, `trends_sliver.dart`, `discover_trends_screen.dart`,
    `widgets/trend_info_card_widget_discover_page.dart`, `widgets/trends_staggered_view.dart`.
13. Remove from `TrendBloc`: `LoadTrends`, `LoadTrendsCacheFirst`, `LoadTrendsCacheFirstThenNetwork`
    and their handlers. Keep `LoadTrend`, `LoadTrendsCacheForYouPage`, add/update/delete.
14. Migrate `interest_details_screen.dart` to the new sliver widget (3-line change) if the old view
    is deleted.

### Phase 5 — Tests and verification

15. Bloc tests with fake service + fake Hive store; widget tests for the feed.
16. `flutter analyze lib test`, full `flutter test`, manual run on a device.

---

## 7. Task Breakdown

| # | Task | Files | Depends on | Size |
| --- | --- | --- | --- | --- |
| T1 | `TrendFeedPage` model with limit+1 `hasMore` | `lib/data/models/trends/trend_feed_page.dart` | — | S |
| T2 | `fetchTrendsPage` (single query, no N+1), delete `fetchTrends` / `fetchTrendsWithFilter` | `firebase_trends_service.dart` | T1 | M |
| T3 | Repository + `FindTrendFeedPageUsecase` + DI | `trend_repository.dart`, `trend_feed_repository_impl.dart`, new usecase, `service_locator.dart` | T2 | S |
| T4 | `HiveTrendService.getSortedItems()` (D7) | `hive_trend_service.dart` | — | S |
| T5 | `TrendFeedState` / `TrendFeedEvent` | `lib/data/models/trends/bloc/trend_feed_*` | T1 | S |
| T6 | `TrendFeedBloc` — cursor, generation guard, dedupe, auto-continue, box subscription | `trend_feed_bloc.dart` | T3, T4, T5 | L |
| T7 | Register bloc in `main.dart` | `main.dart` | T6 | S |
| T8 | Sliver feed widget + sentinel + footer | `lib/presentation/screens/trends/widgets/trend_feed_sliver.dart` | T6 | M |
| T9 | Rewrite `DiscoverTrendsPage` on bloc state | `discover_trends_page.dart` | T6, T8 | M |
| T10 | Delete dead screens/widgets, prune `TrendBloc` feed events | 5 files + `trend_bloc*.dart` | T9 | M |
| T11 | Migrate `interest_details_screen.dart` to the sliver | `interest_details_screen.dart` | T8 | S |
| T12 | Bloc tests (12 cases, §9) | `test/trends/trend_feed_bloc_test.dart` | T6 | M |
| T13 | Widget tests (6 cases, §9) | `test/trends/trend_feed_screen_test.dart` | T9 | M |
| T14 | Emulator e2e against real Firestore (3 pages, timestamp tie) | throwaway script | T2 | M |

`T6` is **Large** because it carries the correctness risk: cursor lifecycle, generation guard,
duplicate handling and the bounded auto-continue interact, and they are the only parts a UI test
cannot easily catch.

**Sequencing:** T1 → T2 → T3 and T4 → T5 → T6 → (T7, T8) → T9 → T10/T11 → T12/T13 → T14.
Land T2 before T10 so the dead screens are deleting a contract that is already gone.

---

## 8. Dependencies

- `flutter_staggered_grid_view 0.7.0` — `SliverMasonryGrid` (already installed).
- `cloud_firestore` — `startAfterDocument`, `DocumentSnapshot` cursors (already installed).
- `HiveTrendService` / `trends_feed_cache` box — already open at app start.
- `TrendInfoCardWidget` — unchanged, reused.
- `sl` (get_it) — new usecase registration.
- No new packages. No Cloud Functions. No rules changes.

---

## 9. Tests

**Bloc (`test/trends/trend_feed_bloc_test.dart`, fake service + fake Hive store)**

1. Opening emits cached items first, then the merged network page, without a full-screen reload.
2. Initial page requests `limit + 1` and keeps 20 items, `hasMore == true`.
3. `hasMore == false` when the server returns exactly `limit` items.
4. Load-more appends and passes the previous page's cursor.
5. Load-more is ignored while one is in flight (rapid sentinel fires → one request).
6. Load-more is ignored when `hasMore == false`.
7. A failed page keeps the existing items and sets `loadMoreError`; no further automatic request.
8. `TrendFeedRetry` clears the error and loads the next page.
9. `TrendFeedRefresh` resets the cursor and replaces the list with the newest page.
10. A refresh cannot be overwritten by an older in-flight load-more (generation guard).
11. A duplicate-only page triggers at most 5 follow-up requests, then stops.
12. Items are stored/emitted ordered `createdAt DESC, uid ASC`, and duplicates are not appended twice.

**Widget (`test/trends/trend_feed_screen_test.dart`)**

1. First paint shows cached cards before the network page resolves.
2. Reaching the bottom builds the sentinel and triggers exactly one load-more.
3. Footer spinner is shown while loading and the existing cards stay on screen.
4. A failed page shows the bottom retry; tapping it loads the page.
5. Pull-to-refresh reloads the newest page and keeps the list visible.
6. Empty cache + empty server shows the empty state.

Follow the notification tests' hard-won constraints: build the bloc **inside** the test body, avoid
`pumpAndSettle` while a `CircularProgressIndicator` is alive, and never `await bloc.close()` when a
handler may be awaiting a fake pending future.

---

## 10. Risks

| Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- |
| Sentinel sliver fires eagerly because it lands inside the viewport's cache extent, looping pages | Medium | Medium | Guards (`isLoadingMore`, `hasMore`, `loadMoreError`) + the 5-page auto-continue cap + a widget test asserting exactly one request per bottom arrival |
| Nested `CustomScrollView` inside `NestedScrollView` + `TabBarView` gives surprising metrics | Medium | Medium | The sentinel does not read metrics at all; if it misbehaves, fall back to a `NotificationListener` threshold at the `HomeScreen` level (spike first, §12 Q3) |
| Hive grows without bound; sorting it on every box change is O(n log n) per emission | Medium | Medium | Emit only on box changes, keep the grid lazy, and (optional, T15) prune to the newest 500 while never deleting `createdBy == currentUser` so My Posts stays intact |
| `TrendBloc` refactor breaks My Posts or trend details | High | Low | My Posts uses `LoadTrendsCacheForYouPage` and the same box; only feed events are removed — verify both tabs manually before finishing |
| Hive retains trends deleted by other users, so the feed can show stale cards until restart | Low | High | Pre-existing behaviour; document as a limitation (a prune-on-refresh would need a per-page existence check — out of scope) |
| Removing `fetchTrends` breaks a caller missed by the audit | Medium | Low | Only `TrendBloc` and the repository call it (verified); `flutter analyze` catches the rest |
| Emulator cannot validate Firestore index requirements | Low | Medium | The chosen query has no `where` clause, so it uses the automatic `created_at` index; no composite index expected and none added |

---

## 11. Acceptance Criteria

- The Discover tab renders with `SliverMasonryGrid`: scrolling a long feed does **not** build every
  card up front (verify with the widget inspector's build counts).
- Opening the tab issues one Firestore read of at most 21 documents for the first page, and **no**
  per-document `likes` / `followers` queries.
- Reaching the bottom appends the next 20 older trends; already-rendered cards keep their scroll
  position (no jump, no flicker, no duplicate keys).
- No further requests once the server has no more data; the footer shows nothing.
- A failed page leaves the existing cards on screen and shows a working bottom retry.
- Pull-to-refresh resets the cursor and shows the newest trends; an in-flight older request cannot
  overwrite it.
- Cached items paint before the network responds (airplane mode still shows the last feed).
- Adding or deleting a trend is reflected in the feed without reopening the tab.
- `flutter analyze lib test` reports no **new** issues; all new tests pass; My Posts and trend
  details behave exactly as before.

---

## 12. Open Questions — resolved

1. **`TrendFeedBloc` vs extending `TrendBloc`** → new bloc, as recommended.
2. **Cache cap** → prune to the newest 500, never dropping the viewer's own posts.
3. **Sentinel vs scroll threshold** → started sentinel-only; it fired too early on the first layout
   (§15.4), so the sentinel now validates the real `extentAfter` and a scroll-threshold trigger was
   added for the case where the sentinel never rebuilds.
4. **`interest_details_screen`** → migrated; `TrendsStaggeredView` deleted.
5. **Page size** → 20.

---

## 13. Recommendations

- **Do T2 first and in isolation.** Deleting the N+1 lookups is a pure win: a 20-card page drops
  from 41 reads to 1, and it is the single biggest cost in this feed today.
- **Keep the bloc state as the UI's only input** even though Hive stays the store (D5). Two readers
  of the same box (a `ValueListenableBuilder` plus a `BlocBuilder`) is exactly how the current feed
  ends up sorting the whole cache four times per update.
- **Do not introduce a real-time listener** on `trends` to "make new posts appear". The box
  subscription plus pull-to-refresh covers it; a collection-wide stream would undo the read savings.
- **Follow-up, separate plan:** `fetchTrendsByTag` pages its 100 newest documents and then filters
  tags client-side, so a popular tag can miss older matches. That wants a denormalized tag field and
  a server-side `array-contains` query, not pagination.

---

## 14. Definition of Done

- All tasks T1–T14 complete; T15 (prune) only if confirmed in §12 Q2.
- No dead trend feed code left (`grep` finds no `fetchTrends(`, `TrendsStaggeredView`,
  `LoadTrendsCacheFirst`).
- New bloc + widget tests pass; full `flutter test` shows no new failures beyond the two known
  pre-existing ones.
- `flutter analyze lib test` shows no new issues.
- Manually verified on a device: Discover scroll-to-load, refresh, airplane mode, add/delete trend,
  and both Home tabs.
- This document updated with a §15 implementation record (files, cursor strategy, index status,
  test results, limitations), mirroring the notification plan.

---

## 15. Implementation record

Status: **implemented** — `flutter analyze lib test` reports no new issues, 24 trend tests pass,
the full suite is green apart from two pre-existing failures, and the paged query was verified
against the Firestore emulator.

### 15.1 Files created

| File | Purpose |
| --- | --- |
| `lib/data/models/trends/trend_feed_page.dart` | `TrendFeedPage{trends, cursor, hasMore}` — opaque cursor, `limit + 1` exactness |
| `lib/data/models/trends/bloc/trend_feed_bloc.dart` | Pagination state machine for the feed |
| `lib/data/models/trends/bloc/trend_feed_event.dart` | `TrendFeedOpened`, `TrendFeedLoadMore`, `TrendFeedRefresh`, `TrendFeedRetry`, `TrendFeedCacheChanged` |
| `lib/data/models/trends/bloc/trend_feed_state.dart` | `items` + pagination flags, `copyWith` with explicit error clearing |
| `lib/domain/usecases/trends/find_trend_feed_page_usecase.dart` | `FindTrendFeedPageParams` + usecase |
| `lib/presentation/screens/trends/widgets/trend_feed_sliver.dart` | `TrendFeedSliver` (lazy `SliverMasonryGrid`), `TrendFeedSentinel`, `TrendFeedFooter` |
| `test/trends/trend_feed_fakes.dart` | Shared fake service + in-memory Hive store |
| `test/trends/trend_feed_bloc_test.dart` | 13 bloc tests |
| `test/trends/trend_feed_screen_test.dart` | 11 widget tests (incl. three screen sizes) |

### 15.2 Files modified

| File | Change |
| --- | --- |
| `firebase_trends_service.dart` | Added `fetchTrendsPage` (one query, no per-card flag lookups); removed `fetchTrends` and `fetchTrendsWithFilter` |
| `trend_repository.dart`, `trend_feed_repository_impl.dart` | `fetchTrendsPage` replaces `fetchTrends` |
| `hive_trend_service.dart` | `getSortedItems()`, `itemChanges()`, `pruneCache(keepAuthorUid:)`, `maxCachedItems = 500` |
| `discover_trends_page.dart` | Rewritten on bloc state: `CustomScrollView` + lazy grid + footer + sentinel + pull-to-refresh; scroll-threshold trigger |
| `interest_details_screen.dart` | Uses `TrendFeedSliver` instead of the deleted shrink-wrapped view |
| `trend_bloc.dart` / `trend_bloc_event.dart` / `trend_bloc_state.dart` | Removed `LoadTrends`, `LoadTrendsCacheFirst`, `LoadTrendsCacheFirstThenNetwork`, `TrendsLoaded`, `TrendsNewData` |
| `main.dart` | `BlocProvider(create: (_) => TrendFeedBloc())` |
| `service_locator.dart` | `FindTrendFeedPageUsecase` replaces `FindTrendsUsecase` |

### 15.3 Deleted

`trends_screen.dart`, `trends_sliver.dart`, `discover_trends_screen.dart`,
`trends_staggered_view.dart`, `trend_info_card_widget_discover_page.dart`,
`find_trends_usecase.dart` — all unreachable once the route names were traced to `HomeScreen`.

### 15.4 The sentinel needed a guard (the predicted risk, confirmed)

Sentinel-only was tried first and **fired on the very first layout**: the masonry grid reports no
measured extent yet, so the sentinel was built while the user was still at the top of a 1400px feed.
`expect(service.requests, hasLength(1))` failed with `2`.

Two changes fixed it:

1. `TrendFeedSentinel` re-reads `Scrollable.maybeOf(context)!.position.extentAfter` in its
   post-frame callback and returns without firing while it is more than `threshold` (300) away from
   the end. A feed shorter than the screen passes, because `extentAfter` is then `0`.
2. A scroll-threshold trigger in the page (`_handleScrollNotification`) covers the case the sentinel
   cannot: once it has been built and rejected, it does not rebuild on scroll, so the page dispatches
   from `notification.metrics.extentAfter < 300` instead. A `_pendingLoadMore` flag, cleared by a
   `BlocListener` when `isLoadingMore` turns false, stops one flick from queueing several pages.

Verified across `375×667`, `834×1112`, `1440×900` and an `800×4000` viewport where three cards can
never fill the screen — one page per bottom arrival, and the short feed still fills itself.

### 15.5 Cursor strategy

`created_at DESC` on `trends` with `startAfterDocument(lastDoc)` and `limit(limit + 1)`; the extra
document makes `hasMore` exact and is sliced off. The cursor stays inside `TrendFeedPage` as an
`Object?` so the bloc can be tested without Firestore.

Because the Hive cache outlives a session, a page can legitimately add nothing (the documents are
already cached). The bloc therefore walks up to `maxDuplicatePages = 5` fully-duplicate pages before
yielding, which is what lets a cold start with 60 cached trends keep paginating past the cursor's
starting point.

### 15.6 Index status

None added. The feed query has **no `where` clause**, so it resolves against the automatic
`created_at` single-field index. Note that other trend queries (`fetchTrendsCreatedBy`, which filters
`created_by` and orders `created_at`) would need a composite index and have none declared — they are
currently unreachable from the UI, so they were left alone.

### 15.7 Emulator verification

45 trends seeded, `created_at` as epoch millis, with two trends sharing a timestamp on the
page-1/page-2 boundary: 3 pages of 20/20/5, 45 unique documents, descending order preserved, the
`limit + 1` probe reported the final page exactly (5), and the tie was neither skipped nor repeated.
A control run with a timestamp-only cursor did not reproduce the same window, which is why the
snapshot cursor stays.

### 15.8 Tests executed

| Command | Result |
| --- | --- |
| `flutter test test/trends/` | 24 passed |
| `flutter test` | 192 passed, 2 pre-existing failures (`client_measurement_firestore_test.dart`, boilerplate `widget_test.dart`) |
| `flutter analyze lib test` | 68 issues, all pre-existing; no errors outside the known one |

### 15.9 Limitations

- Deleting trends made by other users still requires a refresh; the cache is merge-only.
- `pruneCache` protects the viewer's own posts, but a very old post of theirs keeps a slot in the
  500-item window only while its author matches — My Posts stays correct, the cap is approximate.
- Two rapid bottom arrivals prefetch one extra page (the bloc cannot see a queued event); the extra
  page is 20 documents and is cached, so this was accepted over adding timing heuristics.
- Search-by-tag pagination is still out of scope (§13).

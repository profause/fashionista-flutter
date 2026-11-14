# Trend Reporting Module — Implementation Plan

> Status: Planning only. No implementation code has been written yet.
>
> Last updated: 2026-11-14

---

## 1. Executive Summary

Add a long-press action sheet to trend cards with **Download**, **Share**, and **Report**. Tapping **Report** opens a report screen that lists reasons from the Firestore collection `report_trend_content` (title, description, Markdown content). After the user picks a reason, a confirmation sheet renders the reason's Markdown with `flutter_markdown_plus` and submits the report.

Reports are recorded in `reported_trends/{trendId}` using the requested `trend_id` + `details[]` shape. When the number of unique reporters reaches a configurable threshold, the backend marks `trends/{trendId}.status = "reported"`, and all client feeds, tag rails, search results, cache projections, and deep links stop showing the trend.

I recommend enforcing the threshold and status change with a **Cloud Functions callable** rather than a direct client write. Direct client writes would let any user hide any trend by forging `status` or `number_of_times_reported`.

### Flow at a glance

```text
User long-presses a trend card
  → TrendActionsSheet (Download | Share | Report)
  → Report selected
  → /trends/:id/report
  → Fetch active reasons from report_trend_content
  → User selects a reason
  → ReportConfirmationSheet renders the reason's Markdown
  → Confirm
  → reportTrend callable
      → report receipt at reported_trends/{trendId}/reports/{uid}
      → aggregated details at reported_trends/{trendId}
      → trends/{trendId}.status = "reported" when threshold is reached
  → Client hides the trend locally if the response says it is hidden
  → All clients hide it on their next refresh/projection
```

---

## 2. Objectives

1. Make trend actions discoverable through a long press, without disrupting normal tap-to-open behavior.
2. Keep report reasons editable in Firestore without an app release.
3. Render reason content as Markdown.
4. Prevent duplicate reports from the same user.
5. Enforce the reporting threshold server-side.
6. Hide reported trends consistently from public surfaces.
7. Keep the author able to see and manage their own reported post.
8. Leave an audit trail for moderation.

---

## 3. Scope

### In Scope

- Long-press bottom sheet on trend cards: Download, Share, Report.
- Report route at `/trends/:id/report`.
- Reason list from `report_trend_content`.
- Confirmation bottom sheet with Markdown rendering.
- Report submission and aggregation.
- Threshold-based `trends.status` update.
- Feed, tag-feed, details, cache, and deep-link handling for reported trends.
- Firestore rules and Cloud Function.
- Function unit tests and `flutter analyze` verification.

### Out of Scope

- Admin/moderation console or review queue UI.
- Notifying the reporter or the trend author about the outcome.
- Appeals workflow.
- ML/automatic content moderation.
- Downloading every media item in a multi-image trend. V1 downloads the first featured media only.
- Showing report counts to end users.
- Bulk migration of legacy trend documents, because missing `status` is treated as visible.
- Backfilling old app versions that still show reported trends.

---

## 4. Assumptions

- A user can report a given trend once. A second attempt returns "already reported."
- The threshold counts **unique users**, not raw report taps, so one person cannot hide a trend alone.
- The threshold is configurable and defaults to **5**.
- `report_trend_content.title` is the reason name, `description` is the short subtitle, and `content` is the Markdown shown in the confirmation sheet.
- `report_trend_content` documents are created from the Firebase console or an admin script; there is no in-app editor.
- `updated_at` may be a Firestore `Timestamp`; the Dart service normalizes it to epoch milliseconds to match existing model conventions.
- Users do not see the Report option on their own posts. The backend also rejects self-reports.
- Reported trends remain visible to the author under "My Posts" with a "Reported" badge, but disappear from public surfaces. This is a recommendation, not a fixed requirement.
- A missing `status` field means the trend is visible.
- The project can deploy Cloud Functions and Firestore rules, as it already does for trend notifications and interest counts.
- Cloudinary media URLs are publicly deliverable.

---

## 5. Open Questions

| # | Question | Recommended default |
|---|---|---|
| 1 | What threshold should hide a trend? | `5` unique reporters, stored in `app_config/trend_reporting` and editable without a deploy |
| 2 | Should reported trends stay visible to the author? | Yes, in "My Posts" only, with a "Reported" badge |
| 3 | Is Download/Share required in the first release, or can it follow Report? | Ship the sheet with all three; implement Report first if time is tight |
| 4 | Should Report also be available from the trend details screen? | Yes, add it to the existing more-options sheet; long press alone is hard to discover |
| 5 | Should `report_trend_content` get an `order` and `is_active` field? | Yes, optional with safe defaults; lets operations reorder/retire reasons without deleting them |
| 6 | Should tapping a reported trend from an old client show an error or a blank screen? | Error state: "This trend is no longer available" |

No answer is required before starting Phases 0–3; the backend decision in particular is covered by the recommendation below.

---

## 6. Architecture Impact

### Client

New feature area under Trends:

- `ReportTrendReasonModel` — JSON model for `report_trend_content`.
- `TrendReportResult` — result of a submission (`hidden`, `alreadyReported`, `numberOfReports`).
- `FirebaseReportTrendService` — fetches reasons and invokes the `reportTrend` callable.
- `ReportTrendRepository` + implementation.
- `FetchReportTrendReasonsUsecase` and `SubmitTrendReportUsecase`.
- `ReportTrendBloc` registered globally in [main.dart](/Users/profause/Workspace/flutter/fashionista/lib/main.dart), with dependencies registered in [service_locator.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/service_locator/service_locator.dart).
- `TrendActionsSheet` reusable widget.
- `ReportTrendScreen` and `ReportConfirmationSheet`.
- Route in [app_router.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/routes/app_router.dart).
- Download and share services under `lib/data/services/media/`.

### Existing trend changes

- [TrendFeedModel](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/trend_feed_model.dart) gains a nullable `status` field and `isReported` getter.
- [HiveTrendService](/Users/profause/Workspace/flutter/fashionista/lib/data/services/hive/hive_trend_service.dart) excludes reported items from public projections.
- [FirebaseTrendsService](/Users/profause/Workspace/flutter/fashionista/lib/data/services/firebase/firebase_trends_service.dart) filters reported items from tag feeds and rejects reported details for non-authors.
- [TrendFeedBloc](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/bloc/trend_feed_bloc.dart) must count only *visible* additions during pagination.
- [TrendBloc](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/bloc/trend_bloc.dart) should reject a cached reported trend before the details screen renders it.

### Data model

```text
report_trend_content/{reasonId}
  title: string
  description: string
  content: string                 # Markdown
  updated_at: Timestamp           # normalized to milliseconds in Dart
  order: number                   # optional, default 999
  is_active: boolean              # optional, default true

reported_trends/{trendId}
  trend_id: string
  details: [
    {
      reason: string              # report_trend_content doc id
      reason_title: string        # snapshot for audit
      number_of_times_reported: number
    }
  ]
  number_of_times_reported: number
  first_reported_at: Timestamp
  updated_at: Timestamp

reported_trends/{trendId}/reports/{uid}
  trend_id: string
  reason: string
  reason_title: string
  reported_by: string
  created_at: Timestamp

trends/{trendId}
  status: "reported"             # added only when threshold is reached
  reported_at: Timestamp
  number_of_times_reported: number

app_config/trend_reporting
  threshold: number
  enabled: boolean
```

No composite Firestore indexes are required because filtering remains client-side, matching the current draft-filtering approach.

#### Sample report content document

The supplied policy text can be used as the Markdown `content` for a reason such as "Misleading content":

```json
{
  "title": "Misleading content",
  "description": "Claims or behaviour that mislead people",
  "content": "We usually review all submitted reports within 48 hours. We won't notify this account that you submitted a report.\n\n**We remove things like**\n\n- Misleading content or behaviour\n- Repetitive posts\n- Unsolicited commercial messages",
  "updated_at": "<Firestore Timestamp>",
  "order": 1,
  "is_active": true
}
```

### Backend

New callable `reportTrend` in `functions/src/trends/report.ts`, exported from [functions/src/index.ts](/Users/profause/Workspace/flutter/fashionista/functions/src/index.ts).

It should run a single transaction that:

1. Validates authentication and inputs.
2. Rejects self-reports.
3. Returns idempotently if the user already reported the trend.
4. Reads the reason document and rejects missing/inactive reasons.
5. Reads or creates `reported_trends/{trendId}`.
6. Increments the matching `details` entry and total count.
7. Writes the per-user report receipt.
8. Reads `app_config/trend_reporting`.
9. Sets `trends/{trendId}.status = "reported"` when the total reaches the threshold.
10. Returns `{ hidden, alreadyReported, numberOfReports }`.

### Firestore rules

Add to [firestore.rules](/Users/profause/Workspace/flutter/fashionista/firestore.rules):

- `report_trend_content`: readable by signed-in users, writable only by admins/console.
- `reported_trends`: client reads and writes denied. The callable uses Admin SDK privileges.
- Optionally allow a user to read their own receipt at `reported_trends/{trendId}/reports/{uid}`.
- Keep the existing `trends/{trendId}` update restriction; only the function may change status.
- `app_config` remains client-denied by default.

### Native

- iOS: add `NSPhotoLibraryAddUsageDescription` to [Info.plist](/Users/profause/Workspace/flutter/fashionista/ios/Runner/Info.plist).
- Android: the existing `WRITE_EXTERNAL_STORAGE` permission covers older APIs; `gal` uses MediaStore on newer versions.

---

## 7. Implementation Plan

### Phase 0 — Foundation

- Add `flutter_markdown_plus`, `share_plus`, and `gal` to [pubspec.yaml](/Users/profause/Workspace/flutter/fashionista/pubspec.yaml).
- Seed `report_trend_content` with at least: Misleading content, Repetitive posts, Unsolicited commercial messages. Use the supplied policy text as Markdown content.
- Create `app_config/trend_reporting`.
- Add Firestore rules for report content.

### Phase 1 — Visibility model

- Add `status` to `TrendFeedModel` with a new Hive field, then regenerate with `build_runner`.
- Exclude `reported` from `HiveTrendService.getSortedItems()`.
- Keep reported items in the Hive cache so a later refresh overwrites stale copies; filter them only when projecting the feed.
- Ensure `pruneCache` still counts reported items so the cache remains bounded.
- Filter reported trends from tag feeds, discovery rails, and non-author detail lookups.
- Add an "unavailable" state to the details screen.
- Update pagination so a page containing only hidden trends does not stop the feed.

### Phase 2 — Action sheet and media actions

- Implement `showTrendActionsSheet` returning a `TrendAction` enum.
- Wire `onLongPress` on [TrendInfoCardWidget](/Users/profause/Workspace/flutter/fashionista/lib/presentation/screens/trends/widgets/trend_info_card_widget.dart) and [MyPostFeedCardWidget](/Users/profause/Workspace/flutter/fashionista/lib/presentation/screens/trends/widgets/my_post_feed_card_widget.dart).
- Add the same sheet entry to the existing options sheet in [TrendDetailsScreen](/Users/profause/Workspace/flutter/fashionista/lib/presentation/screens/trends/trend_details_screen.dart).
- Hide Report for own posts.
- Download: use `dio` + `path_provider` + `gal`, first media only.
- Share: use `share_plus` with caption and media URL; pass a `sharePositionOrigin` on iPad.

### Phase 3 — Report UI

- Add `ReportTrendScreen` at `/trends/:id/report`.
- Load reasons through `ReportTrendBloc`.
- Show loading, error/retry, empty, and populated states.
- Require a selected reason before enabling **Continue**.
- On Continue, open `ReportConfirmationSheet`.
- Render `MarkdownBody(data: reason.content)` inside a scrollable, height-constrained sheet.
- Confirm calls `SubmitTrendReportUsecase`; show an in-button spinner; surface errors in the sheet.
- On success: close the sheet, pop the report screen, show a toast, and update the local cache if the server returned `hidden`.

### Phase 4 — Backend

- Add the `reportTrend` callable with pure, testable helpers for reason aggregation and threshold decisions.
- Add Jest tests for: first report, repeated reason, new reason, duplicate user, threshold reached, threshold not reached, self-report, missing reason, and missing trend.
- Deploy Firestore rules and the function before shipping the client.

### Phase 5 — Hardening and QA

- Run `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, and `flutter analyze`.
- Run `npm --prefix functions run build && npm --prefix functions test`.
- Test on both Android and iOS, including video cards, permission denial, iPad share, offline submission failure, and two concurrent reports.

---

## 8. Task Breakdown

| ID | Task | Files / Modules | Depends / Estimate | Acceptance |
|---|---|---|---|---|
| T0.1 | Seed report reasons and threshold config | Firebase console; [firestore.rules](/Users/profause/Workspace/flutter/fashionista/firestore.rules) | — / S | Signed-in users can read active reasons; clients cannot write them |
| T0.2 | Add packages and native permission strings | [pubspec.yaml](/Users/profause/Workspace/flutter/fashionista/pubspec.yaml); [Info.plist](/Users/profause/Workspace/flutter/fashionista/ios/Runner/Info.plist) | — / S | `flutter pub get` succeeds; photo-add permission present |
| T1.1 | Add `status` to trend model | [trend_feed_model.dart](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/trend_feed_model.dart); [trend_feed_model_hive_type.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/models/hive/trend_feed_model_hive_type.dart); generated `.g.dart` | T0.2 / S | Legacy JSON/Hive documents parse; `isReported` works |
| T1.2 | Hide reported trends from public surfaces | [hive_trend_service.dart](/Users/profause/Workspace/flutter/fashionista/lib/data/services/hive/hive_trend_service.dart); [firebase_trends_service.dart](/Users/profause/Workspace/flutter/fashionista/lib/data/services/firebase/firebase_trends_service.dart); [trend_bloc.dart](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/bloc/trend_bloc.dart); [trend_details_screen.dart](/Users/profause/Workspace/flutter/fashionista/lib/presentation/screens/trends/trend_details_screen.dart) | T1.1 / M | Feed, tag rails, search, and non-author details hide reported content |
| T1.3 | Fix pagination accounting for hidden items | [trend_feed_bloc.dart](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/bloc/trend_feed_bloc.dart) | T1.2 / S | A page of reported items does not halt loading of later pages |
| T2.1 | Build trend actions sheet and wire long press | New `trend_actions_sheet.dart`; trend cards; details screen | T0.2 / M | Long press opens Download/Share/Report; Report is hidden on own posts |
| T2.2 | Implement media download | New `trend_media_download_service.dart`; DI registration | T2.1 / M | First image/video saves to gallery; denial produces a friendly toast |
| T2.3 | Implement share | New `trend_share_service.dart`; DI registration | T2.1 / S | Native share sheet opens with caption and media link |
| T3.1 | Add report data layer | New model, service, repository, usecases; [service_locator.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/service_locator/service_locator.dart) | T0.1, T0.2 / M | Reasons load sorted; callable result maps to typed state |
| T3.2 | Add `ReportTrendBloc` | New bloc/event/state; [main.dart](/Users/profause/Workspace/flutter/fashionista/lib/main.dart) | T3.1 / M | Loading, selection, submission, success, and error states work; state resets on exit |
| T3.3 | Add report screen and route | New `report_trend_screen.dart`; [app_router.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/routes/app_router.dart) | T3.2 / M | Reasons render; empty/error/retry states work; Continue requires a selection |
| T3.4 | Add Markdown confirmation sheet | New `report_confirmation_sheet.dart` | T3.3 / M | Markdown renders; Cancel/Confirm work; loading and failure are visible |
| T4.1 | Add `reportTrend` callable | New `functions/src/trends/report.ts`; [index.ts](/Users/profause/Workspace/flutter/fashionista/functions/src/index.ts) | T0.1 / L | Transaction is idempotent, rejects self-reports, aggregates reasons, and sets status at threshold |
| T4.2 | Add function tests | New `functions/test/report.test.ts` | T4.1 / S | All threshold and duplicate cases pass |
| T5.1 | Full verification | Entire feature | T1–T4 / S | `flutter analyze`, functions build/tests, and manual QA matrix pass |

T4.1 is **Large** because it is security-critical, involves a transaction, depends on rules and deployment order, and must be rehearsed against the emulator or a staging project.

---

## 9. Dependencies

### Internal

- [TrendFeedModel](/Users/profause/Workspace/flutter/fashionista/lib/data/models/trends/trend_feed_model.dart), Hive adapter, and feed bloc.
- [FirebaseTrendsService](/Users/profause/Workspace/flutter/fashionista/lib/data/services/firebase/firebase_trends_service.dart) and trend repository.
- [HiveTrendService](/Users/profause/Workspace/flutter/fashionista/lib/data/services/hive/hive_trend_service.dart).
- [app_router.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/routes/app_router.dart), [service_locator.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/service_locator/service_locator.dart), and [main.dart](/Users/profause/Workspace/flutter/fashionista/lib/main.dart).
- Existing `dio`, `path_provider`, `cloud_functions`, and `url_launcher`.
- Cloudinary URL helpers in [cloudinary_video_urls.dart](/Users/profause/Workspace/flutter/fashionista/lib/core/media/cloudinary_video_urls.dart).

### External

- `flutter_markdown_plus` — Markdown rendering.
- `share_plus` — native share sheet.
- `gal` — save image/video to the device gallery.
- Firebase Cloud Functions deployment.
- Firestore rules deployment.
- Firebase project `fashionista-2025`.

---

## 10. Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Client-side status writes let a user hide any trend | High | High if used | Use the callable function; deny client writes to report docs and status |
| Old app versions still show reported trends | Medium | High | Deploy backend first, release client promptly, treat this as a known rollout limitation |
| Cached reported trend remains visible | High | Medium | Insert fetched documents with `status` into Hive, filter only during projection; clear locally on successful hidden result |
| Feed pagination stalls on a page of reported items | Medium | Medium | Count only visible additions in the feed bloc; add a regression case |
| Duplicate reports from one user inflate the count | High | Medium | Per-user report document keyed by uid; transaction returns idempotently |
| Threshold too low allows brigading | Medium | Medium | Configurable threshold, default 5, unique reporters; add App Check/rate limiting later |
| Long press conflicts with video gestures | Medium | Medium | Test the video card specifically; keep an overflow-menu fallback on the details screen |
| `gal` or `share_plus` native integration issues | Medium | Medium | Verify current Flutter/AGP compatibility; add iOS photo-add string; test on a physical iPhone/iPad |
| Markdown links open unsafe schemes | Medium | Low | Allow only `https`, `mailto`, and internal routes in `onTapLink` |
| Rules/function deployed out of order | High | Medium | Deploy rules + function before the app; verify with a staging account |
| Author loses access to a reported post | Medium | Medium | Keep reported posts in the author's My Posts with a badge, and allow the author to open details |
| Missing or malformed report content | Medium | Medium | Seed all documents with `updated_at`; show a safe empty/error state; log malformed docs |
| Threshold semantics unclear (unique vs raw reports) | Medium | Medium | Document unique reporters; surface total in `number_of_times_reported` only for audit |

---

## 11. Acceptance Criteria

1. Long-pressing a trend card opens a bottom sheet with Download, Share, and Report, each with an icon.
2. Tapping Report navigates to `/trends/:id/report`.
3. The report screen lists active `report_trend_content` documents with title and description.
4. Loading, empty, error, and retry states are handled.
5. The Continue/Report button stays disabled until a reason is selected.
6. Confirming opens a bottom sheet that renders the selected reason's `content` as Markdown using `flutter_markdown_plus`.
7. Confirming the report creates `reported_trends/{trendId}/reports/{uid}` and aggregates into `reported_trends/{trendId}.details`.
8. A second report from the same user does not increase counts.
9. When the unique report count reaches the configured threshold, `trends/{trendId}.status` becomes `reported`.
10. Reported trends disappear from Discover, For You, tag feeds, search rails, and non-author deep links.
11. The author can still see their own reported trend in "My Posts," with a visible "Reported" badge.
12. Client writes to `reported_trends`, `report_trend_content`, and `trends.status` are denied by rules.
13. A failed submission leaves no partial report data and lets the user retry.
14. Download saves the first featured image or video to the gallery; permission denial and network failure show a clear message.
15. Share opens the native share sheet with the trend caption and media URL.
16. `flutter analyze` reports no new issues.
17. `npm --prefix functions run build` and `npm --prefix functions test` pass.

---

## 12. Definition of Done

- All acceptance criteria pass on Android and iOS.
- Firestore rules and the `reportTrend` function are deployed to the `fashionista-2025` project.
- `report_trend_content` and `app_config/trend_reporting` are seeded.
- The generated `trend_feed_model.g.dart` is regenerated and checked in.
- Native permission strings are added.
- `flutter analyze` is clean.
- Function unit tests pass.
- Manual QA covers image cards, video cards, own posts, duplicate reports, threshold crossing, deep links, offline failure, download permission denial, and iPad share.
- Rollback plan is documented: disable reporting via config, and if necessary remove `status` from affected trends or revert the function.
- Changes are committed to `dev` with a terse message, per project convention.

---

## 13. Recommendations

1. **Use a callable Cloud Function, not direct client writes.** The extra backend work is small compared with the risk of letting clients forge counts or hide arbitrary posts.
2. **Set the default threshold to 5 unique reporters**, configurable in `app_config/trend_reporting`. Three is too easy to abuse.
3. **Keep reported posts visible to the author only.** Hiding the author's own post entirely removes their ability to understand or delete it.
4. **Add Report to the trend details options sheet.** Long press is useful, but not discoverable enough on its own.
5. **Cache reasons locally later.** V1 can load on open; a Hive cache can be added if reporting needs to work offline.
6. **Add App Check and a per-user rate limit before scale.** The transaction prevents duplicate reports, but it does not prevent a user from mass-reporting many different trends.
7. **Deploy the backend before the client.** Older app builds will still display reported trends because they do not yet read `status`; plan the release accordingly.
8. **Use `status` rather than deleting reported trends.** It preserves auditability and allows moderators to restore content if needed.
9. **Do not add composite indexes yet.** The current feed strategy filters client-side, consistent with draft handling; revisit only if you move status filtering into Firestore queries after a backfill.

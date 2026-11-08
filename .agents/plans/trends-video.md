# Plan — Short-form fashion videos in Trends (Milestone 1: architecture)

Status: **proposed (Milestone 1, reviewed)** · Feature: user-recorded / gallery video posts in Trends
Companion plans: `trends-pagination.md`, `push-notifications-module.md`

> **Superseded:** §19 replaces the signing design described throughout this document. Uploads are now
> **unsigned** (public upload preset); the only backend call left is `deleteCloudinaryAsset`. Read §19
> before §5–§13.

## 0. Review outcome

Reviewed before implementation. One decision changed (autoplay default), two were raised and then
confirmed as they were (signing and deletion stay), and eleven defects were found and fixed.

| Decision | Outcome | Why |
| --- | --- | --- |
| Video upload signing | **Kept**, then **removed** during device testing — see §19 | "Skip signing" was considered, then withdrawn: deleting a Cloudinary asset needs the API secret, so the backend and the secret exist either way. Two callables on one already-required surface beat a permanent orphaned-asset problem. **Superseded:** the signed upload failed on device with `Invalid Signature`, so the upload moved to an unsigned preset and deletion moved to Cloudinary's `delete_token` (10 min) with the Admin-API callable as fallback. |
| Deletion | **Keep one minimal `deleteCloudinaryAsset` callable** | Without it a deleted post leaves the video on Cloudinary forever, and `deleteTrendImage` is already broken in that exact way. |
| Autoplay default | **Flip `autoPlayVideos` to on**, with a one-time migration | The setting defaults to `false` and is persisted by `SettingsBloc` (a `HydratedBloc`), so a default flip alone would never reach existing installs. |

Defects found while reviewing this plan:

1. `VideoCropRect` collided with `native_video_editor`'s own `VideoCropRect` — renamed `VideoCrop`.
2. `thumbnail()` returning `Uint8List` would hold N frames in memory for a filmstrip — now returns a temp file path.
3. No fast path: a clip that is already ≤30 s with no crop and no mute still paid for a full re-encode.
4. Camera audio was assumed present; a denied microphone now records video-only (`enableAudio: false`).
5. The upload preset was implicitly the hardcoded `'ml_default'`; project convention is Remote Config.
6. Delete ordering was unspecified; asset-first-then-document is now required, so a failed asset delete leaves a retryable post rather than an orphan.
7. Autoplay-on-by-default raises cellular data questions that the plan did not address.

Second pass (signing + deletion confirmed):

8. **`public_id` vs `folder` was conflated.** When both are sent, Cloudinary's asset id becomes
   `<folder>/<public_id>`; the response (not the request) carries the full id. The plan now signs and
   sends them separately and stores the **returned** asset id.
9. **A pre-existing publish bug sits on the exact path video will reuse.** `_saveTrend` does
   `uploadResult.fold((left) { …; return; }, …)` — that `return` exits the *closure*, so a failed
   upload still calls `AddTrendUsecase` and creates a **media-less trend post**.
10. **Cancel leaves an orphan by construction** unless the deterministic public id is destroyed.
11. Hive field ids, the Functions region, and the extra params Cloudinary refuses to sign were all
    unspecified — all execution blockers now resolved (§6.4, §6.5, §10).

> **No application code has been modified.** Every package check below was a `pub add --dry-run`
> against the current lockfile; the manifests are untouched.

---

## 1. Executive Summary

Trends today is an image-only posting flow (`add_trend_screen.dart` → Cloudinary image upload →
`trends` document → masonry feed). The **read** side already understands video: `FeaturedMediaModel`
carries `type`, `thumbnail_url` and `aspect_ratio`, and `TrendInfoCardWidget` already renders
`VideoPreviewWidget` (`cached_video_player_plus`) for `type == 'video'`, gated by the existing
`SettingsBloc.autoPlayVideos` toggle. There is simply **no way to create** such a post.

This feature adds the creation pipeline — capture, gallery, trim, crop, mute, export, signed Cloudinary
upload, publish — and upgrades feed playback from "tap to play" to **visibility-driven muted autoplay
with exactly one active decoder**. It reuses the existing `trends` collection and media model, so
image posts keep working unchanged.

Three findings from the codebase shape the design more than the spec does:

1. **The client-side upload secret problem.** Image uploads today go straight from Flutter to
   Cloudinary with `uploadPreset: 'ml_default'` (unsigned). Video does not repeat that: it uses a
   backend-signed upload, and deletion — which can never be unsigned — needs the same backend. That
   pairing is why the "skip signing" idea was dropped in review (§0); `cloud_functions` is still not a
   dependency and must be added.
2. **`native_video_editor` is the right engine but controls less than the spec assumes** — it does
   trim + normalized crop + resize + mute + thumbnail + progress + cancel in a **single** native pass
   (Media3 Transformer / AVFoundation), but it exposes **no codec, bitrate or frame-rate settings**
   and **no audio-track inspection**. Two spec rows therefore become "platform defaults".
3. **Autoplay-in-grid is the memory-critical path**, and it is the option the user chose. On Android a
   mid-range device typically allows one or two concurrent H.264 decoders, so the playback manager is
   not a nice-to-have; it is the feature.

---

## 2. Objectives

1. Record a ≤30 s video in-app, or pick one from the gallery and trim it to ≤30 s.
2. Trim, crop (original / 9:16 / 4:5 / 1:1), mute, export locally in **one** native processing pass.
3. Upload the exported file to Cloudinary **with a backend-generated signature**, reporting progress
   and supporting cancel/retry without creating duplicate posts.
4. Persist the video as a normal `trends` post with an extended media entry, so existing image posts
   and all engagement (likes, comments, counts) keep working untouched.
5. Play video posts in the masonry feed: muted autoplay when visible, **one at a time**, pause when
   out of view or backgrounded, with a mute toggle and graceful errors.
6. Keep the feed's existing pagination, Hive cache and rebuild behaviour intact.

---

## 3. Scope

### In scope

- Capture screen (camera), gallery picker, metadata inspection, trim/crop/mute editor, export.
- `VideoEngine` abstraction + `native_video_editor` implementation.
- Signed upload: new callable `createVideoUploadSignature`, new client upload path (`dio`), Hive
  upload-task persistence for retry-after-Firestore-failure, and a `deleteCloudinaryAsset` callable.
- Additive `FeaturedMediaModel` fields + Hive type ids + `build_runner` regeneration.
- Feed playback manager + inline video tile + per-card mute/play controls.
- Tests: unit (engine fake, trim/crop math, upload cubit, playback arbitration), widget (editor, upload
  states, video card), Functions (signature + deletion), and a device test matrix.

### Out of scope (documented, deliberate)

| Item | Why |
| --- | --- |
| Migrating **image** uploads to signed uploads | User decision. Recorded as debt in §14; the signature callable is written so images can adopt it later without a contract change. |
| Firestore draft documents / `processing_status` | User decision: upload-then-create. The `trends` collection never contains a half-published post, and the feed query needs no extra filter or index. |
| HLS / adaptive streaming | Requires a Cloudinary add-on; progressive MP4 with `q_auto` is the default delivery. |
| Text/filters/watermarks, multi-video carousels, duets | Not in the spec; `features/` stays additive later. |
| Background upload across app termination | No WorkManager/BGTask integration; the spec forbids promising it. Uploads resume while the app is alive and are persisted for retry on next open. |
| Fixing the stale `deleteTrendImage` (Firebase Storage) path | Pre-existing bug on image deletion; see §14 debt. |

---

## 4. Assumptions

- A post is **either** images **or** one video — mixed carousels are rejected in the editor/publisher.
- 30 s is the hard cap; minimum trim length is **1 s** (configurable constant).
- Target output: short edge ≤ 720 px, even dimensions, never upscaled beyond source.
- Users are signed in (Trends already requires auth) and have network for upload.
- Cloudinary account has video upload enabled; the deploy step in §13 is run before release.

---

## 5. Open Questions

1. **Bitrate/frame-rate target** — the engine cannot enforce 30 fps or a bitrate ceiling. Accept
   platform defaults (recommended), or gate the feature on a second engine? *(Recommendation: accept,
   and cap resolution instead, which is what actually drives file size.)*
2. **`has_audio` accuracy** — no track inspection available. Accept `has_audio = !muted` (approximate),
   or add a ~40-line platform channel using `MediaMetadataRetriever` / `AVAssetTrack`? *(Recommendation:
   approximate now; the field is display-only.)*
3. **Gallery video length cap** — allow any length and cut in the editor (recommended), or pre-reject
   files over, say, 10 minutes to avoid pulling huge files into memory/disk?
   *(Recommendation: reject >10 min with a clear message; the file still has to be copied locally.)*
4. **Data usage** — warn on cellular before a >20 MB upload, or always upload? *(Recommendation: no
   gating in v1; `connectivity_plus` is already a dependency if we want it later.)*

---

## 6. Architecture Impact

### 6.1 Layers (matches the existing clean-architecture split)

```
presentation/  video_capture_screen · video_editor_screen · inline video tile · playback manager
     │           (VideoCaptureCubit · VideoEditorCubit · VideoUploadCubit)
     ▼
domain/        VideoEngine (interface) · models · usecases
     │           (RequestVideoUploadSignature · UploadTrendVideo · PublishTrendVideo)
     ▼
data/          NativeVideoEditorEngine · VideoMetadataReader · FirebaseVideoUploadService
                · HiveUploadTaskService · FirebaseTrendsService (video delete)
     ▼
backend        createVideoUploadSignature (onCall) · deleteCloudinaryAsset (onCall)
                Cloudinary (video + image assets) · Firestore (trends)
```

### 6.2 VideoEngine contract

```dart
abstract class VideoEngine {
  Future<VideoMetadata> inspect(String path);          // duration, size, orientation, audio?

  /// `VideoCrop` (not `VideoCropRect`) so it never collides with the plugin's
  /// own class of that name.
  Future<ProcessedVideo> process({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
    required VideoCrop crop,           // normalized 0..1, single pass
    required bool muteAudio,
    required VideoOutputSettings settings,
    void Function(double progress)? onProgress,
  });

  /// Writes a frame to a temp file and returns its **path**; the filmstrip
  /// needs 6–8 of these and must not keep the bytes in memory.
  Future<String> thumbnail(String path, {required Duration at});

  Future<void> cancel(String outputPath);
  Future<void> dispose();
}
```

`NativeVideoEditorEngine` maps this onto `NativeVideoEditor.processVideo(VideoEditRequest…)` /
`cancelProcessVideo(outputPath)`; `inspect()` uses a short-lived `VideoPlayerController.file` for
duration and dimensions. The interface is what makes the engine replaceable (open question 1, or a
future FFmpeg/platform-channel engine) without touching any UI.

**Fast path:** when the clip is already ≤30 s, the trim covers its full duration, the crop is
`VideoCrop.original`, and audio is kept, `process()` returns the source path unchanged instead of
re-encoding — no quality loss, seconds saved on every short gallery clip. The `ProcessedVideo` result
carries `wasReencoded` so the temp-file cleanup knows which file it may delete.

**Filmstrip cost:** generating 8 thumbnails decodes the source 8 times natively. They are written to
`<temp>/trends_video/thumbs/<hash>/` and reused for the same file + position, so opening the editor
twice does not pay twice; the directory is pruned with the rest of the temp workspace.

### 6.3 Firestore / model changes (additive only)

`FeaturedMediaModel` gains nullable fields; `type: 'video'` entries populate them, image entries leave
them null. New document shape for a video post (inside the existing `trends` collection):

```json
{
  "created_by": "<uid>",
  "created_at": 1730000000000,
  "description": "…",
  "tags": "…",
  "author": { "uid": "…", "name": "…", "avatar": "…" },
  "featured_media": [{
    "uid": "fashionista/trends/videos/<uid>/<trendId>",
    "type": "video",
    "url": "https://res.cloudinary.com/<cloud>/video/upload/q_auto/v…/<publicId>.mp4",
    "thumbnail_url": "https://res.cloudinary.com/<cloud>/video/upload/so_0,w_720,q_auto/<publicId>.jpg",
    "aspect_ratio": 0.5625,
    "duration": 28.5,
    "width": 720,
    "height": 1280,
    "has_audio": false,
    "format": "mp4",
    "file_size": 4250000
  }]
}
```

- **No new collection, no new index.** The feed query stays `orderBy created_at desc`.
- **Hive**: new `@HiveField` ids in `featured_media_model_hive_type.dart`; `build_runner` regenerates
  the adapter. Old cached trends still deserialize (new fields nullable).
- **`processing_status` is not written** (decision: upload-then-create). Client-side states cover
  `processing → uploading → saving → completed|failed`.

### 6.4 Backend

| Callable | Auth | Contract |
| --- | --- | --- |
| `createVideoUploadSignature` | required | in: `{trendId}`; out: `{cloudName, apiKey, timestamp, signature, folder, publicId}`, where **`folder = <base>/trends/videos/<uid>`** and **`publicId = <trendId>`** (kept separate: Cloudinary refuses a `public_id` that repeats the folder). The folder is derived server-side, so a client cannot sign into another user's folder. |
| `deleteCloudinaryAsset` | required | in: `{assetId, trendId}` where `assetId` is the **full** public id returned by the upload; validates `trendId` ownership (`created_by == uid`) **and** `assetId.startsWith('<base>/trends/videos/<uid>/')` before `POST /video/destroy` (Basic auth, `invalidate=true`). |

**Signature rules that must not drift** (Cloudinary signs every parameter *except* `file`,
`api_key`, `resource_type`, `cloud_name`):

- sign the alphabetically sorted `folder`, `public_id`, `timestamp` exactly as returned;
- the client re-sends **only** those three plus `api_key`, `signature`, and `file` — an extra
  parameter such as `tags` or `context` invalidates the signature and surfaces as a bare `401`;
- `timestamp` is generated server-side per request (never cached), so an expired signature can only
  come from a slow retry, which the client handles by refetching once (§6.5).

**Region:** `functions/src/index.ts` sets `setGlobalOptions({ region: 'us-central1' })`, which is the
`FirebaseFunctions.instance` default — do not change one without the other.

- Signing: Node `crypto` HMAC-SHA1 over alphabetically sorted params — **no** Cloudinary SDK, no new
  npm dependency. Deletion uses the Admin REST API with Basic auth over `fetch` (Node 22 global).
- Secrets via `defineSecret('CLOUDINARY_API_SECRET')` + params for key/cloud; deployed with
  `firebase functions:secrets:set`. Nothing secret enters Dart or Remote Config.

### 6.5 Upload reliability

```
trendId (uuid, generated once) ──► publicId ──► signature ──► dio PUT/POST ──► validate ──► publish
        ▲                                                                                    │
        └────────── Hive upload task (idempotent retry, same publicId + overwrite:true) ◄─────┘
```

- **Duplicate prevention**: the public id is derived from the post id, so a retry overwrites the same
  asset instead of creating a second one; Firestore `set(merge:true)` on the same `trendId` is also
  idempotent.
- **Preset/config**: the Cloudinary upload preset comes from Remote Config
  (`cloudinary_video_upload_preset`), not a literal — `add_trend_screen.dart` currently hardcodes
  `'ml_default'` for images, and that is exactly the pattern the project forbids. The preset also
  sets `max_file_size`, which is the only file-size limit enforced when the upload is signed but the
  asset is not otherwise inspected.
- **Camera audio**: if the microphone permission is denied the recorder runs with
  `enableAudio: false` (video-only) instead of failing; `has_audio` is then `false` regardless of the
  mute toggle.
- **Expired signature**: a 401/400 naming signature → refetch signature and retry once.
- **Firestore failure after upload**: persist `{trendId, assetId, cloudinary response, media json}` in
  a Hive `pending_publish` box; the upload screen offers "Finish publishing" and only the Firestore
  write is retried.
- **Cancel cleanup**: because the asset id is deterministic (`<folder>/<trendId>`), cancelling calls
  `deleteCloudinaryAsset` best-effort. If the upload never reached Cloudinary the destroy 404s, which
  is logged and ignored; if it did, the orphan is removed. Without this, "cancel" is a promise the app
  cannot keep.
- **Delete while uploading**: the publish screen owns the upload future; deleting the post cancels the
  upload first, then destroys the asset, then removes the document.

### 6.6 Playback architecture (the critical path)

- One `VideoPlaybackManager` created above the feed (`MultiBlocProvider`/`RepositoryProvider`):
  `register(key, url)`, `reportVisibility(key, fraction)`, `takeActive()`.
- **Exactly one** `VideoPlayerController` exists at a time. The active candidate is the highest
  `fraction ≥ 0.6`, re-evaluated on a 250 ms debounce; the previous controller is disposed before the
  next is created (`cached_video_player_plus` keeps the *file* cached, the *decoder* is ours).
- Thumbnail (`thumbnail_url`) is the poster and stays visible until the first frame renders — no video
  bytes are fetched for off-screen cards.
- `AppLifecycleListener` pauses on background; resume only if the card is still visible.
- Audio focus: one unmuted player at a time, and unmuting mutes every other card. The player keeps
  `mixWithOthers: true` (existing behaviour) so it does not hijack the user's music at autoplay, but
  `allowBackgroundPlayback` stays `false`.
- `MyPostFeedCardWidget` (For You → My Posts) already renders video through `VideoPreviewWidget` and
  keeps its current tap-to-play behaviour; it is **not** moved onto the manager in this scope, so the
  two surfaces behave differently by design (grid autoplays, own-posts requires a tap).
- `autoPlayVideos` now **defaults to on** so the feature is actually visible, and it still disables
  autoplay entirely when a user switches it off (poster + play button). Because `SettingsBloc` is a
  `HydratedBloc`, the persisted `false` written by the old default is upgraded once — see §9 T20.
- Default-on autoplay costs data, so feed playback uses a delivery profile capped at 720 px with
  `q_auto:eco`; the poster stays until the first frame decodes, and only the active clip is fetched.
- Manual pause sets `userPaused`, which survives minor scroll changes and clears when the card leaves
  the viewport.

---

## 7. Dependency compatibility assessment

All four candidates were resolved with `flutter pub add <pkg> --dry-run` against
`Flutter 3.47.9 / Dart 3.8.1` (pubspec `sdk: ^3.8.1`). Manifests unchanged.

| Package | Latest | Resolves? | Platform floor | Verdict |
| --- | --- | --- | --- | --- |
| `camera` | 0.12.2 (2026‑10‑27) | **Yes** (5 deps change) | needs Flutter ≥3.44 ✔ | **Add** |
| `native_video_editor` | 0.4.0 (2026‑08‑10) | **Yes** (1 dep) | Android minSdk 23 ✔ (Flutter default 24), iOS 13 ✔ (project 15) | **Add** |
| `visibility_detector` | 0.4.0+2 (2023) | **Yes** | pure Dart | **Add** (see risk R5) |
| `video_player` | 2.14.1 | already satisfied by `^2.10.0` | — | **No change** |
| `image_picker` | 1.2.4 | already `^1.2.0` | — | **No change** |
| `dio` | 5.11.1 | not tested → expected ✔ (SDK `>=2.18 <4`) | pure Dart | **Add** (progress + cancel + retry) |
| `cloud_functions` | 7.0.1 | **Yes** (3 deps change) | Flutter ≥3.27 ✔ | **Add** (first callable in the app) |
| `ffmpeg_kit_flutter` | retired upstream | — | — | **Rejected**: size (+~30–60 MB), retired project, licensing; not needed given `native_video_editor`. |

**Already present and reused:** `video_player`, `cached_video_player_plus` (file cache + player),
`image_picker` (`pickVideo`), `path_provider`, `connectivity_plus`, `permission_handler`, `uuid`,
`intl`, `hive`, `cloudinary_flutter`/`cloudinary_api` (images), `crypto` (backend).

**Native config:** iOS `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
`NSPhotoLibraryUsageDescription` already present; Android manifest already declares the camera feature
as optional. `RECORD_AUDIO` is contributed by the camera plugin — verify after `pub get`.

---

## 8. Implementation Plan

### Milestone 1 — Architecture & dependencies (this document)

Architecture, contracts, schema, dependency verdict, file list, risk register. **Deliverable: this plan.**

### Milestone 2 — Capture & gallery

1. `pubspec` additions + `service_locator` registrations.
2. `VideoMetadataReader` + `VideoEngine.inspect` (duration/size/orientation, >10 min rejection).
3. `VideoCaptureCubit` + capture screen: preview, front/rear switch, 30 s auto-stop (plugin
   `maxVideoDuration` **and** an independent timer), discard/retake/continue, lifecycle-safe disposal.
4. Gallery entry via `image_picker.pickVideo` → inspect → route to editor (long videos allowed through).
5. Entry point in `add_trend_screen.dart` ("Record video" / "Choose video"), images untouched.

### Milestone 3 — Editor

6. `VideoEditorCubit` (metadata, trim range, crop rect, mute, export progress) + editor screen:
   preview, filmstrip timeline (thumbnails via `VideoEngine.thumbnail`, cached), start/end handles,
   playhead, duration readout, reset.
7. Crop overlay with 4 aspect presets → normalized `VideoCrop`; live preview must match export.
8. Audio toggle (mute removes the track on export).
9. Export via `NativeVideoEditorEngine.process` with progress + cancel; temp output in
   `getTemporaryDirectory()/trends_video/`.

### Milestone 4 — Signed upload & publish

10. Functions: `cloudinary/signature.ts`, `cloudinary/client.ts`, `video/upload-signature.ts`,
    `video/delete-asset.ts`, exports, jest tests; secrets wired.
11. `FirebaseVideoUploadService` (callable → `dio` multipart → response validation) +
    `HiveUploadTaskService` for pending publishes.
12. `VideoUploadCubit` states: `authorizing → uploading(progress) → saving → completed | failed`, with
    cancel, retry, and "finish publishing" when only the Firestore write failed.
13. Publish through the existing `AddTrendUsecase` path so Hive cache + `TrendFeedBloc` update exactly
    as they do for images.

### Milestone 5 — Feed playback

14. `VideoPlaybackManager` + `AppLifecycleListener` wiring.
15. Inline video tile inside `TrendFeedSliver`: poster until visible, single active decoder, play/pause,
    mute toggle, buffering/error states, stable `ValueKey(media.uid)`.
16. Delete flow: for **video** media call `deleteCloudinaryAsset` **first**, then remove the Firestore
    document. If the asset delete fails the post stays and the error surfaces, so the user can retry
    instead of leaving an orphan. The image path keeps its existing (broken) Firebase-Storage call.

### Milestone 6 — Reliability & performance

17. Airplane-mode upload, cancel mid-upload, expired signature, Firestore-failure retry, duplicate-check.
18. Device matrix (mid-range Android + iPhone): 60 fps scroll, memory, decoder count, first-frame time.
19. Regression pass on image posts, pagination, Hive cache, notifications.

---

## 9. Task Breakdown

| # | Task | Files | Depends | Size |
| --- | --- | --- | --- | --- |
| T1 | Add 5 packages, resolve, update manifests if needed | `pubspec.yaml`, lock | — | S |
| T2 | Video models + `VideoEngine` interface | `data/models/video/*`, `domain/video/video_engine.dart` | — | S |
| T3 | `NativeVideoEditorEngine` + `VideoMetadataReader` | `data/services/video/*` | T1, T2 | M |
| T4 | `VideoCaptureCubit` + capture screen | `bloc/video_capture_*`, `trends/video/video_capture_screen.dart` | T3 | L |
| T5 | Gallery pick + inspect + routing | `video_capture_*`, `add_trend_screen.dart` | T3 | M |
| T6 | `VideoEditorCubit` + editor screen | `bloc/video_editor_*`, `trends/video/video_editor_screen.dart` | T3 | L |
| T7 | Trim timeline + filmstrip + crop overlay widgets | `trends/video/widgets/*` | T6 | L |
| T8 | Export (progress/cancel/temp files) | `video_editor_cubit`, engine | T6 | M |
| T9 | Backend signature + delete callables + tests | `functions/src/cloudinary/*`, `functions/src/video/*`, `functions/test/*` | — | L |
| T10 | `FirebaseVideoUploadService` (`dio`) + response validation | `data/services/firebase/firebase_video_upload_service.dart` | T1, T9 | M |
| T11 | `VideoUploadCubit` + progress UI + retry/cancel | `bloc/video_upload_*`, `trends/video/widgets/export_progress_sheet.dart` | T10 | L |
| T12 | Hive pending-publish persistence | `data/services/hive/hive_upload_task_service.dart`, `hive_service.dart` | T11 | M |
| T13 | Extend `FeaturedMediaModel` + Hive ids + `build_runner` | model, `.g.dart`, hive type file | — | S |
| T14 | Publish video post via `AddTrendUsecase` | `add_trend_screen.dart`, `video_upload_cubit` | T11, T13 | M |
| T15 | `VideoPlaybackManager` + lifecycle | `presentation/widgets/video/video_playback_manager.dart` | T13 | L |
| T16 | Inline video tile in feed + mute/play controls | `trends/widgets/trend_feed_sliver.dart`, `widgets/video/inline_video_tile.dart`, `trend_info_card_widget.dart` | T15 | L |
| T17 | Video delete via callable | `firebase_trends_service.dart`, delete UI path | T9 | S |
| T18 | Unit + widget tests | `test/video/*`, `test/trends/*` | T3–T16 | L |
| T19 | Device matrix + perf + regression (§12) | — | all | L |
| T20 | Flip `autoPlayVideos` default to `true` + one-time migration of the persisted value | `data/models/settings/models/settings_model.dart`, `data/models/settings/bloc/settings_bloc.dart` | T16 | S |
| T21 | Fix the upload-failure bug in `_saveTrend` (failed upload currently still creates a media-less post) and route both media types through one guarded publish method | `add_trend_screen.dart` | T14 | S |

**Large tasks and why:** T4 (camera lifecycle + permissions + timer is where races live), T6/T7 (trim &
crop math must match export exactly), T9 (new backend surface + secrets + tests), T11 (state machine
with cancel/retry/idempotency), T15/T16 (single-decoder arbitration), T18 (breadth), T19 (device work).

**Sequencing:** T1→T2→T3, then two parallel tracks — capture/editor (T4–T8) and backend/upload
(T9–T12) — converging at T13→T14, then feed work (T15–T17), T20 with the feed, then T18/T19.

**T20 detail:** `Settings.empty()` flips to `autoPlayVideos: true` and gains a persisted
`settings_version` (2). `SettingsBloc.fromJson` upgrades a stored payload whose version is missing or
`< 2` **and** whose value is still the old default `false` — that is the only reliable way to reach
existing installs, because `HydratedBloc` already restored the old default as if it were a choice.
After the upgrade, an explicit "off" sticks.

---

## 10. Files to create / modify

### Create — Flutter

```
lib/data/models/video/video_metadata.dart            VideoMetadata, VideoCrop, VideoOutputSettings, ProcessedVideo
lib/data/models/video/video_upload_task.dart         pending-publish record
lib/data/models/trends/bloc/video_capture_cubit.dart / _state.dart
lib/data/models/trends/bloc/video_editor_cubit.dart  / _state.dart
lib/data/models/trends/bloc/video_upload_cubit.dart  / _state.dart
lib/domain/video/video_engine.dart
lib/domain/usecases/video/request_video_upload_signature_usecase.dart
lib/domain/usecases/video/upload_trend_video_usecase.dart
lib/domain/usecases/video/delete_trend_video_usecase.dart
lib/data/services/video/native_video_editor_engine.dart
lib/data/services/video/video_metadata_reader.dart
lib/data/services/firebase/firebase_video_upload_service.dart
lib/data/services/hive/hive_upload_task_service.dart
lib/presentation/screens/trends/video/video_capture_screen.dart
lib/presentation/screens/trends/video/video_editor_screen.dart
lib/presentation/screens/trends/video/widgets/trim_timeline.dart
lib/presentation/screens/trends/video/widgets/crop_overlay.dart
lib/presentation/screens/trends/video/widgets/aspect_selector.dart
lib/presentation/screens/trends/video/widgets/export_progress_sheet.dart
lib/presentation/widgets/video/video_playback_manager.dart
lib/presentation/widgets/video/inline_video_tile.dart
```

### Create — Functions

```
functions/src/cloudinary/signature.ts                HMAC-SHA1 param signing (pure)
functions/src/cloudinary/client.ts                   Admin destroy via REST
functions/src/video/upload-signature.ts              callable handler
functions/src/video/delete-asset.ts                  callable handler + ownership
functions/test/video-signature.test.ts
functions/test/video-delete.test.ts
```

### Modify — Flutter

```
pubspec.yaml                                         + camera, native_video_editor, visibility_detector, dio, cloud_functions
pubspec.lock                                         (generated)
lib/core/service_locator/service_locator.dart        register engine, upload service, Hive task store, usecases
lib/main.dart                                        app-level VideoPlaybackManager; capture/editor/upload cubits are screen-scoped
lib/core/service_locator/hive_service.dart           + upload_tasks box
lib/data/models/featured_media/featured_media_model.dart  (+ .g.dart via build_runner): duration, width, height, hasAudio, format, fileSize
lib/core/models/hive/featured_media_model_hive_type.dart  new field ids: duration=5, width=6,
                                                          height=7, hasAudio=8, format=9, fileSize=10
                                                          (0–4 are taken)
lib/presentation/screens/trends/add_trend_screen.dart     video entry points; image path untouched
lib/presentation/screens/trends/widgets/trend_feed_sliver.dart  use the inline video tile for video media
lib/presentation/screens/trends/widgets/trend_info_card_widget.dart  delegate video → tile (keep image branch)
lib/data/services/firebase/firebase_trends_service.dart   video deletion through the callable
lib/data/models/settings/models/settings_model.dart     autoPlayVideos default + settings_version
lib/data/models/settings/bloc/settings_bloc.dart        one-time upgrade of the persisted default
```

### Modify — Backend/config

```
functions/src/index.ts                               export both callables
firebase.json / functions runtime                    unchanged (nodejs22)
Remote Config (console)                              + cloudinary_trend_video_folder,
                                                      + cloudinary_video_upload_preset
```

### Create — Docs

```
.agents/plans/trends-video.md                        this plan (+ implementation record at the end)
```

---

## 11. Risks

| # | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | `native_video_editor` is young (v0.4.0, Aug 2026, 211 downloads) and could regress on a device/codec | High | Medium | `VideoEngine` isolates it; T19 tests on real devices incl. a 4K/HEVC source; fallback engine can be added without UI changes. Pin the exact version (no `^` caret) until proven. |
| R2 | In-grid autoplay exhausts hardware decoders on mid-range Android | High | High | Single controller enforced in one place; dispose before create; 250 ms debounce; poster-only until visible; measure with `dumpsys media.player` in T19. |
| R3 | Signed upload mismatch (param order/extra fields) → `401 Invalid Signature` | Medium | Medium | Signature computed server-side from the **same** param map returned to the client; jest test asserts the HMAC against a known vector; client sends exactly those params. |
| R4 | Large source video + crop/trim export on a low-end device takes minutes or fails | High | Medium | 10-minute source cap, 720p output cap, progress + cancel, export on a background isolate (the plugin already runs natively), clear failure copy. |
| R5 | `visibility_detector` last published 2023 | Medium | Low | Pure-Dart, small surface; if it breaks, replace with a `NotificationListener` + `RenderBox` computation behind the same manager API (already the plan's boundary). |
| R6 | Upload interrupted after Cloudinary success but before Firestore write | Medium | Medium | Hive `pending_publish` record + "Finish publishing"; public id derived from `trendId` so no duplicate asset/post. |
| R7 | Secrets leak into the client | Critical | Low | Signature only from the callable; `defineSecret`; the app never receives the API secret; agen check in review: no `api_secret` in Dart/RC. |
| R8 | Deleting a video leaves an orphaned Cloudinary asset (or deletes someone else's) | High | Low | Callable validates `created_by` **and** the uid folder prefix before destroy; failure surfaces instead of silently succeeding. |
| R9 | Feed regressions (pagination/Hive) from the media model change | Medium | Low | Fields are nullable and additive; existing 24 trend tests must stay green; `build_runner` output reviewed. |
| R10 | Autoplay-on-by-default burns cellular data and battery; users notice before they find the setting | Medium | High | 720 px `q_auto:eco` playback profile, poster-first, one active clip, `wifi`-free requirement deferred to §5 Q4; expose the toggle in the video card's overflow menu so it is discoverable where the behaviour is seen. |
| R11 | The upload preset is a hardcoded literal somewhere in the new path (the image path already does this) | Medium | Medium | Read `cloudinary_video_upload_preset` from Remote Config in one helper, and add a unit test asserting no Dart file contains a literal preset name. |
| R12 | A cancelled or timed-out upload leaves an asset Cloudinary still bills for | Medium | Medium | Deterministic asset id + best-effort destroy on cancel; the "orphaned assets" check in T19 counts assets in the folder against `trends` documents. |
| R13 | Callable region mismatch (`us-central1` in functions vs the client's default in a future change) surfaces as `not-found` and looks like a code bug | Medium | Low | Region is documented in §6.4 and asserted in T19 by invoking the callable from a release build. |

---

## 12. Testing

**Unit (Dart)** — trim-range validation (start<end, ≤30 s, ≥1 s), crop math for the 4 presets,
metadata (de)serialization incl. old posts without the new fields, `VideoUploadCubit` transitions,
signature/response parsing (reject a response whose `public_id` does not match the signed one), retry +
duplicate-prevention (same asset id), cancel → destroy called, playback arbitration (highest visible
wins, one controller, user-pause not overridden), and the `SettingsBloc` migration (old payload with
`autoPlayVideos:false` upgrades once; an explicit off after the upgrade survives a relaunch).

**Widget** — capture screen states (permission denied, init failure, recording, 30 s auto-stop),
editor controls (handles, aspect, mute, reset, progress), upload progress/failure/retry, inline video
tile (poster → first frame, pause/play, mute, error).

**Functions (jest)** — signature vector, folder derivation cannot escape the caller's uid, auth
required, delete rejects foreign `trendId`/`publicId`, delete idempotency.

**Device (T19)** — the spec's 16-case matrix, plus: 4K/HEVC source, 60 s gallery video, airplane mode
mid-upload, force-close mid-export, 20 video posts scrolled rapidly (one autoplay), background/foreground,
image posts unchanged, pagination still loads page 2.

---

## 13. Cloudinary & deployment requirements

**Remote Config keys** (console, not code): existing `cloudinary_url` (must include the API key for
signed uploads), `cloudinary_base_folder`, new `cloudinary_trend_video_folder`
(`fashionista/trends/videos`) and `cloudinary_video_upload_preset` (a **signed** video preset with
`max_file_size` set, e.g. 60 MB — the preset is still required because Cloudinary validates the
upload against it even when the request is signed).

**Functions secrets/params**:

```bash
firebase functions:secrets:set CLOUDINARY_API_SECRET        # never in source
# params read from env/config: CLOUDINARY_API_KEY, CLOUDINARY_CLOUD_NAME
firebase deploy --only functions:createVideoUploadSignature,functions:deleteCloudinaryAsset
```

**Account**: video upload + transformations enabled; **adaptive streaming (HLS) is an add-on** — not
used in v1. Confirm the account's video transformation quota before enabling autoplay at scale, since
each distinct `w_720,q_auto` variant is a derived resource.

**Release**: no Firestore index or rules change is required (`createsAsSelf()` already permits the new
media fields); review that decision in T19 because rules do not validate media payloads.

---

## 14. Known debt this plan records

1. Image uploads remain **unsigned** (`ml_default`) — the same callable is designed to serve them later.
2. `deleteTrendImage` still targets Firebase Storage and cannot delete modern Cloudinary images; the
   new callable is written so the image path can adopt it, but that migration is not in this scope.
3. `MyPostFeedCardWidget` keeps its own tap-to-play video rendering instead of the feed manager, so
   "My Posts" and the Trends grid behave differently for the same post.
4. `has_audio` is approximated; `processing_status` is not persisted by design.
5. Codec/bitrate/frame-rate are platform defaults, not enforced values.

---

## 15. Acceptance Criteria

- Record 30 s; the recorder stops at 30 s even if the countdown UI drifts.
- A 60 s gallery video opens the editor and cannot be exported beyond 30 s.
- Trim, crop (9:16 pixel-accurate vs preview), and mute all appear in the exported file.
- Export reports progress and can be cancelled, leaving no stray temp files.
- Upload shows progress, can be cancelled and retried, and never creates two posts or two assets.
- **A failed upload never creates a post** (the current image path does exactly that — T21).
- Cancelling an upload leaves no asset behind, or the cleanup attempt is logged.
- A failed Firestore write can be retried without re-uploading.
- Video posts appear in Trends alongside images; like/comment/count behaviour is unchanged.
- In the feed, at most one video plays; it starts muted; leaving the viewport or backgrounding pauses it.
- Autoplay is on for a fresh install **and** for an install that predates this release (migration),
  and switching it off in Settings is respected immediately and after relaunch.
- Deleting a video removes the document and the Cloudinary asset and fails loudly otherwise.
- Existing image posting, pagination, Hive cache and the 24 trend tests are unaffected.
- `flutter analyze` shows no new issues; Android and iOS release builds succeed.

---

## 16. Definition of Done

All six milestones complete; T18/T19 green; this document updated with an implementation record
(files, packages added with versions, upload architecture, backend surface, schema, security review,
test results, limitations, deployment steps) mirroring `trends-pagination.md` §15.

---

## 17. Recommendations

1. **Fix T21 before wiring video into publish.** The existing bug means an upload failure silently
   creates an empty post; adding a second media type to that path would make it slower to find, not
   just harder to fix.
2. **Ship the capture + editor + publish path before the feed autoplay** (M2–M4). It is independently
   valuable, and autoplay is where device-specific failures live — don't let it block "users can post video".
3. **Write the `VideoPlaybackManager` first in M5, before the tile widget.** If the manager is not the
   only thing creating controllers, R2 becomes unenforceable later.
4. **Pin `native_video_editor: 0.4.0` exactly** until T19 signs off; a caret range on a 3-month-old
   plugin is how a silent encoder change reaches production.
5. **Flip the default once, then never again.** T20 upgrades the value persisted by the old default;
   after that the setting belongs to the user. Re-flipping it later would silently override a deliberate
   "off" and is the kind of regression that gets a release rolled back.
6. **Put the autoplay toggle where the behaviour is.** A card overflow menu ("Turn off autoplay") beside
   the mute button means a user annoyed by data use can fix it in place instead of hunting Settings.
7. **Ship the delete callable in the same release as creation.** A create-only launch trains users that
   deleting is fine while quietly filling the Cloudinary account with orphans.
8. **Consider a Wi-Fi hint** (not a gate) for uploads over ~20 MB once the feature is live and real file
   sizes are known.

---

## 18. Implementation record

Status: **Milestones 2–5 implemented, Milestone 6 partially** (device matrix not runnable in this
environment). `flutter analyze lib test` shows no new issues, `flutter test` is green apart from the
pre-existing boilerplate test, and Functions build + 168 jest tests pass.

### 18.1 Packages actually installed

| Package | Resolved | Note |
| --- | --- | --- |
| `camera` | 0.12.2 | |
| `native_video_editor` | 0.4.0 | **pinned exactly**, per recommendation 4 |
| `visibility_detector` | 0.4.0+2 | |
| `dio` | 5.11.1 | progress + cancel + timeout |
| `cloud_functions` | **6.5.1**, not 7.0.1 | v7 requires a newer `firebase_core` than the app's 4.1.1; pub picked 6.5.1 and the callables work unchanged |
| `video_player` | 2.14.1 | already satisfied |

### 18.2 Files created / modified

Created: `data/models/video/{video_metadata,video_upload_models,edited_video,pending_publish_task}.dart`,
`domain/video/video_engine.dart`, `data/services/video/{native_video_editor_engine,video_metadata_reader}.dart`,
`data/services/firebase/firebase_video_upload_service.dart`,
`data/services/hive/hive_upload_task_service.dart`,
`data/models/trends/bloc/{video_capture_cubit,video_capture_state,video_editor_cubit,video_editor_state,video_upload_cubit,video_upload_state}.dart`,
`presentation/screens/trends/video/{video_capture_screen,video_editor_screen}.dart`,
`presentation/screens/trends/video/widgets/{trim_timeline,video_upload_progress}.dart`,
`presentation/widgets/video/{video_playback_manager,video_playback_scope,inline_video_tile}.dart`,
`functions/src/cloudinary/signature.ts`, `functions/src/video/{upload-signature,delete-asset,callables}.ts`,
tests under `test/video/`, `functions/test/video-{signature,delete}.test.ts`.

Modified: `pubspec.yaml/lock`, `hive_service.dart` (upload tasks box), `service_locator.dart`,
`main.dart` (playback scope above the Navigator, temp sweep), `featured_media_model.dart` + `.g.dart` +
hive type ids 5–10, `settings_model.dart` + `settings_bloc.dart` (autoplay default + migration),
`add_trend_screen.dart` (video entry, upload dialog, T21 fix), `trend_info_card_widget.dart`
(video → `InlineVideoTile`), `trend_bloc.dart` (asset-first video deletion), `firestore` untouched.

### 18.3 Deviations from the plan

| Planned | Actual | Why |
| --- | --- | --- |
| `export_progress_sheet.dart` | `video_upload_progress.dart` | It is an `AlertDialog`, not a sheet; name matches the widget |
| `cloud_functions ^7.0.1` | 6.5.1 | Version conflict with `firebase_core 4.1.1`; no API difference used |
| Numeric separators in tests | Removed in 3 test files | build_runner's bundled analyzer cannot parse `10_000`, and it blocks **all** codegen |
| `native_video_editor` metadata | `video_player` controller used for inspect | The plugin exposes no duration/size API |

### 18.4 Behaviour notes discovered during implementation

- `Provider<T>` throws for a `ChangeNotifier`, so the scope uses `ChangeNotifierProvider`; the tile
  subscribes to the manager directly, which is what lets it stop when another card becomes active.
- The scope must wrap `MaterialApp.builder`, not `home:` — pushed routes (interest details, trend
  details) render feed cards too and would otherwise have no manager in scope.
- `camera` has no max-duration option: the 30 s cap is enforced by the cubit's timer, which stops the
  recording independently of the countdown widget.
- Cancel is only honest because the asset id is deterministic: the cubit asks the backend to destroy
  `<folder>/<trendId>` after cancelling the transfer.

### 18.5 Tests executed

| Command | Result |
| --- | --- |
| `flutter test test/video/` | **42 passed** (geometry/crop math, upload cubit, playback arbitration, settings migration, tile widget) |
| `flutter test` | 271 passed, 1 pre-existing failure (`widget_test.dart` counter) |
| `flutter analyze lib test` | 64 issues, all pre-existing |
| `cd functions && npm run build && npm test` | build clean, **168 passed** (19 new) |

### 18.6 Not done / limitations

- **Milestone 6 device matrix was not run**: camera, native export, real signed uploads and decoder
  counts need physical devices. T19 remains open.
- No `firebase.json`/rules change was needed (uploads are server-signed, documents unchanged).
- `has_audio` is derived from the mute toggle + mic permission, never inspected (§14 debt 4).
- Export relies on platform codec defaults (§14 debt 5).
- Deployment still requires `firebase functions:secrets:set CLOUDINARY_API_SECRET` and the
  `cloudinary_video_upload_preset` / `cloudinary_trend_video_folder` Remote Config keys (§13).
- **Pending-publish retry is in-place, not global**: a Firestore failure keeps the video attached and
  the failure dialog offers Retry, which reuses the uploaded asset. If the user closes the dialog and
  abandons the post, the `upload_tasks` record stays until the post is retried or the app data is
  cleared — there is no "resume pending uploads" list yet (the record is what makes one possible).

### 18.7 Post-implementation fixes

- **Startup crash fixed.** `initialiseDependencies()` runs *before* `Firebase.initializeApp()`, and
  `FirebaseVideoUploadService` resolved `FirebaseFunctions.instance` in its constructor, so the app
  died with `[core/no-app]` on the first frame. The client is now resolved lazily on first use
  (`_providedFunctions ?? FirebaseFunctions.instance`), which matches how the other Firebase services
  in this repo behave. Regression test: `test/video/video_upload_service_lazy_test.dart`.
- **Playback scope moved** to `MaterialApp.builder` (pushed routes render feed cards too).
- **`ChangeNotifierProvider`** instead of `Provider` for the manager, and the `autoPlayVideos` sync
  moved from a `BlocBuilder` to a `BlocListener` so the manager never notifies during build.
- **Upload dialog** closes from `build` as well as from the listener, for uploads that finish before
  the dialog mounts.

### 18.8 Camera viewfinder sizing (device report)

Symptom: the capture screen's preview appeared as a small letterboxed rectangle.

Cause: `CameraPreview` already wraps itself in an `AspectRatio`, and it uses **`1 / value.aspectRatio` in
portrait**. The capture screen wrapped it in a *second* `AspectRatio` using the un-inverted value, so in
portrait the inner preview was asked to fit a 9:16 box while it wanted 16:9 — hence the small rectangle
with black bands.

Fix: the preview is now laid out at its native ratio and scaled with `BoxFit.cover` inside a
`ClipRect`, mirroring the plugin's own orientation rule (`deviceOrientation` landscape → `aspectRatio`,
portrait → `1 / aspectRatio`). A viewfinder should fill and crop, not contain.

Also fixed in the same screen: the whole `Stack` used to be wrapped in `SafeArea`, which inset the
preview by the notch/status bar. The preview is now edge-to-edge and only the top/bottom control bars
respect the safe area.

## 19. Unsigned uploads (supersedes the signing design)

Device report: a signed video upload was rejected by Cloudinary with

```
Invalid Signature 4697848f… . String to sign - 'folder=fashionista/trends/videos/ m5oGg4…&public_id=…&timestamp=…'
```

The signature was computed over exactly those three sorted params, so the mismatch is a parameter or
formatting drift between signer and sender (a stray space in `folder`, or any extra field reaching
Cloudinary — it signs every parameter it receives except `file`, `api_key`, `resource_type` and
`cloud_name`). Rather than chase that, the user asked to drop signing entirely.

### 19.1 What changed

| Before | After |
| --- | --- |
| `createVideoUploadSignature` callable, HMAC-SHA1 over `folder`/`public_id`/`timestamp` | **Removed.** `functions/src/video/upload-signature.ts` and its jest suite are deleted; `functions/src/cloudinary/signature.ts` became `folder.ts` and keeps only the folder helpers. |
| Client sent `api_key`, `timestamp`, `signature`, `folder`, `public_id` | Client sends `upload_preset`, `folder`, `public_id`, `file` and nothing else. |
| `public_id = trendId`, `overwrite` implicit | `public_id = uuid v4` per attempt: **unsigned uploads never overwrite**, so a repeated id would collide with an earlier attempt. |
| Signature retry-once on a 401 | No retry: a rejected preset is a configuration problem, not a race. |
| Deletion: `deleteCloudinaryAsset` callable only | Deletion: `delete_token` first (client-side), callable as the fallback. |

`VideoUploadSignature` is gone from the client; `VideoUploadConfig` (`cloudName`, `uploadPreset`,
`baseFolder`) replaces it, and `CloudinaryVideoAsset` carries the optional `deleteToken`.

### 19.2 Configuration

| Source | Key | Used for |
| --- | --- | --- |
| Remote Config | `cloudinary_url` | cloud name only (`Uri.host`); the credentials in it are never read |
| Remote Config | `cloudinary_video_upload_preset` | unsigned preset name; falls back to `ml_default` |
| Remote Config | `cloudinary_base_folder` | base folder, **already used by image uploads**; falls back to `fashionista` |

The upload folder is `<base>/trends/videos/<uid>`, computed by `VideoUploadConfig.folderFor()` and
mirrored by `trendVideoFolder()` in `functions/src/cloudinary/folder.ts`. Both must agree or the delete
callable's ownership check rejects the asset. No new RC key was needed for the folder — the existing
base folder key is reused.

The preset itself must be **unsigned** and should enable **`Return delete token`** in the Cloudinary
console; that is the only way an unsigned upload can return a `delete_token` (the request parameter of
the same name is ignored for unsigned uploads).

### 19.3 Deletion, and the 10-minute window

Cloudinary's client-side delete token is valid for **10 minutes** after the upload:

- `POST https://api.cloudinary.com/v1_1/<cloud>/delete_by_token` with `token` only (verified against
  the Cloudinary JS SDK's `delete_by_token`, which sends nothing else).
- After 10 minutes only the Destroy/Admin API can delete the asset — that needs the API secret, so
  `deleteCloudinaryAsset` stays as the backend fallback.

Tokens live in a dedicated Hive box (`video_delete_tokens`, keyed by full public id) and are **never**
written to Firestore: the token is a deletion credential. `HiveVideoDeleteTokenService` prunes expired
entries on write and on read, so the box cannot grow without bound.

Deletion order is unchanged (asset first, then the document), and the asset delete now tries the token
before the callable:

```
TrendBloc._deleteTrend
  └─ _deleteVideoAsset(assetId, trendId)
       ├─ token in Hive?  ──► POST /delete_by_token ──► success? done
       └─ otherwise       ──► deleteCloudinaryAsset callable ──► success? done
                                   └─ failure ──► keep the post, show a retryable error
```

`VideoUploadCubit.cancel()` uses the same order through `_discardAsset()`. Cancelling is only offered
while bytes are moving (`VideoUploadState.isCancellable`): once the save starts the video is already in
Cloudinary, and a "cancel" there would either orphan it or hide a post that exists.

### 19.4 Trade-offs

- **The preset is public.** Anyone who extracts it can upload to the account. This is the same posture
  the app already has for image uploads (`ml_default`), and Cloudinary's mitigations are preset-side
  (allowed formats, max file size, and a preset-level folder). The uid subfolder is advisory, not an
  access control boundary, because an unsigned uploader chooses its own `folder`.
- **Orphans are possible.** If the app dies between upload and the Firestore write, the video stays in
  Cloudinary with no post and no local token (the token is stored right after the response, so this
  window is one write). The pending-publish record (§18.6) covers the Firestore-failure case only.
- **Deleting a post older than 10 minutes depends on the backend.** If the callable is undeployed or
  the secret is missing, the post is kept and the user is asked to retry — no silent orphan.

### 19.5 Deployment delta

- Remove the `createVideoUploadSignature` function (it is no longer exported; redeploy deletes it).
- `CLOUDINARY_API_SECRET` is still required — for `deleteCloudinaryAsset` only.
- Set `cloudinary_video_upload_preset` in Remote Config and tick **Return delete token** on that preset.

### 19.6 Capture → editor is one flow (device feedback)

The recorder used to stop on a confirm step — *Retake* / *Edit 12s clip* — and only popped the path
after that second tap, with the composer then pushing the editor. Two taps and a route bounce for
something every social recorder does in one.

Now the recorder opens the editor itself as soon as a take ends:

```
record (or stop at the 30 s cap)
  └─ VideoCaptureState.stage == recorded
       └─ _VideoCaptureViewState._onState  (post-frame)
            └─ VideoEditorScreen.open(path)
                 ├─ exported   ──► pop capture with EditedVideo ──► composer
                 └─ back        ──► back to the recorder, Retake / Edit still shown
```

Details that matter:

- **`VideoCaptureScreen.open()` returns `EditedVideo?`**, not a path, and the gallery button uses the
  same `_openEditor` helper, so both sources end in the editor. `add_trend_screen._pickVideo()` is now
  a single call.
- **Cancelling the edit keeps the take.** The recorder is still behind the editor in the `recorded`
  stage, so Retake/Edit are available without re-recording. `_openedFor` remembers the clip the editor
  was opened for, so the cancelled edit does not reopen on the next rebuild, while a new recording
  (new path) opens the editor again.
- **`_editorOpen`** stops a second push while one editor is on top; **`_closing`** stops the editor
  from opening behind a recorder the user is dismissing (the X button stops the recording on the way
  out, which would otherwise emit `recorded` during the pop).
- **The camera stays open while the editor is up.** Releasing it would mean re-initializing on return
  (and a preview-less "review" state), for a screen that is usually up for a few seconds. This is the
  one behaviour change from the old flow, which disposed the camera when the recorder popped.
- Tests: `test/video/video_capture_flow_test.dart` (auto-open, cancel keeps the take, no double push,
  new take re-opens). The screen takes an optional `cubit` for these tests — the real one owns its
  camera and never settles in a widget test.

## 20. Video on the trend detail screen

The detail screen rendered every post through `FeaturedMediaWidget`, an image carousel that asks
Cloudinary for `publicId: <media.uid>` — for a video post that is a folder path, so a video showed a
broken image.

### 20.1 What renders now

```
trend.featuredMedia.length == 1 && media.first.isVideo
  ├─ yes ──► TrendVideoHero   (new, lib/presentation/widgets/video/trend_video_hero.dart)
  └─ no  ──► FeaturedMediaWidget (unchanged behaviour)
```

`TrendVideoHero` is a screen-level player, not the feed tile:

- poster (`thumbnail_url`) immediately, decoder created only when it may play, disposed as soon as it
  may not — the same rule as the feed;
- tap anywhere to play/pause, a centred play button when paused, a shared mute control (hidden for a
  silent clip), a scrubbable progress bar, and the post caption over the same bottom gradient;
- sized by the media's own aspect ratio, clamped to `[9:16, 16:9]`, letterboxed in black rather than
  cropped — a vertical clip keeps its full frame.

### 20.2 Playback ownership (the part that was actually broken)

A feed card keeps reporting itself visible when a route covers it: `VisibilityDetector` measures
geometry, not route occlusion. So a video playing in the feed would keep decoding and leaking audio
behind the detail screen.

The hero therefore takes the manager's active key while it is on top:

- mount → `manager.playManually(heroKey)` (or `pause()` when autoplay is off, so a manually started
  feed clip still stops);
- while mounted and not user-paused, it re-claims the key if anything else wins a recompute (an
  app-resume re-arms the visible feed card otherwise);
- dispose → `manager.releaseFocus(heroKey)`.

`releaseFocus` is new: unlike `remove()`, which waits for the next visibility event, it re-decides
immediately — nothing scrolls when a route pops, so without it the feed would stay stopped until the
user scrolled.

### 20.3 Shared caption

The gradient caption moved out of `FeaturedMediaWidget` into `FeaturedMediaCaption`
(`lib/presentation/widgets/featured_media_caption.dart`) so the image carousel and the video hero
cannot drift apart.

The carousel also gained a poster branch for `media.isVideo`: single-video posts never reach it, but a
legacy mixed post now shows a real frame instead of a broken-image icon.

### 20.4 Known gap

An **image** post's detail screen still lets a feed video play behind it (same occlusion problem, no
hero to claim playback). Fixing that means pausing on mount for every detail route and restoring on
pop; left out to keep this change to the video path.

### 20.5 Tests

- `test/video/trend_video_hero_test.dart` — poster/caption/controls, silent clip hides mute, autoplay
  off does not steal playback, autoplay on takes it, tap-to-play claims it, mute is shared, closing
  hands playback back to the feed.
- `test/video/video_playback_manager_test.dart` — `releaseFocus` returns the key to the visible card
  and is a no-op when it does not own it.

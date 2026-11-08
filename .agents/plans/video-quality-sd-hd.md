# Plan — Progressive SD/HD video delivery in Trends (Milestone 1: assessment)

Status: **implemented (M2–M6 code + tests; device matrix open)** · Feature: SD-first playback with opt-in HD · Companion plans:
`trends-video.md` (the pipeline that created these posts), `trends-pagination.md` (the feed).

## 1. Executive summary

Trends videos are stored once in Cloudinary and played from the **original** `secure_url`, i.e. the
720p file the editor exported. There is no rendition concept anywhere: the URL is whatever the upload
returned, and the only Cloudinary transformation in the app is the inline poster string in
`CloudinaryVideoAsset.fromResponse`.

The change is therefore narrow: **derive two delivery URLs from the same public id** (SD 854 box, HD
1280 box, both `c_limit` + `q_auto` + `f_mp4`), play SD by default, and let the user opt into HD on
the card they are watching. No schema change is required — `FeaturedMediaModel.uid` already holds the
Cloudinary public id for every video post, so renditions can be built for existing documents.

## 2. What exists today (assessment)

### 2.1 Model and storage

`FeaturedMediaModel` (`lib/data/models/featured_media/featured_media_model.dart`):

| Field | Video content |
| --- | --- |
| `uid` | **Cloudinary public id, folder included** (`fashionista/trends/videos/<uid>/<uuid>`) |
| `url` | `secure_url` from the upload response — the original file |
| `thumbnailUrl` | `…/video/upload/so_0,w_720,q_auto/<public_id>.jpg` |
| `width`/`height`/`aspectRatio`/`duration`/`fileSize`/`hasAudio`/`format` | from the upload response |

The editor exports at `VideoOutputSettings.maxShortEdge = 720` (`lib/data/models/video/video_metadata.dart`),
so **the stored original is already ≈HD**. HD delivery is close to a pass-through; SD is where the
bandwidth win is.

### 2.2 Upload and Cloudinary integration

- `FirebaseVideoUploadService` uploads **unsigned** (`upload_preset` from Remote Config) with
  `resource_type: video`, `folder`, random `public_id`, and captures `delete_token`.
- Unsigned uploads accept a restricted parameter set: `eager` **cannot** be sent from the client.
- `deleteCloudinaryAsset` callable already holds the API key/secret (`CLOUDINARY_API_KEY`,
  `CLOUDINARY_API_SECRET`), so a server-side step is available if needed.
- Cloud name is resolvable client-side without the secret: `Uri.parse(appConfig.get('cloudinary_url')).host`
  (already done in `firebase_video_upload_service.dart` and the poster builder).
- **No shared URL builder.** The only transformation string in the app is the poster, inline in
  `lib/data/models/video/video_upload_models.dart:82`.

### 2.3 Playback surfaces

1. **Feed card** — `lib/presentation/widgets/video/inline_video_tile.dart`
   - plain `video_player` (`VideoPlayerController.networkUrl(media.url)`);
   - controller created only while the card is the manager's active key, disposed when it is not;
   - `VisibilityDetector` → `VideoPlaybackManager.updateVisibility`;
   - poster from `thumbnailUrl`, controls = play/pause + mute, `_failed` overlay on error;
   - spinner only while a decoder is opening (idle cards show the poster).
2. **Post detail** — `lib/presentation/widgets/video/trend_video_hero.dart`
   - same controller pattern, plus it claims/releases the manager while on top.
3. **Legacy** — `lib/presentation/widgets/video_preview_widget.dart` (`cached_video_player_plus`,
   plays `media.url`, no manager) used only by `my_post_feed_card_widget.dart` ("My posts").

### 2.4 Arbitration and lifecycle

`VideoPlaybackManager` (ChangeNotifier, no controllers) owns: `activeKey`, mute, app-active, user
pause, visibility fractions with a 250 ms debounce, `minVisibleFraction = 0.6`, `releaseFocus()`.
**Exactly one decoder exists at a time** on the feed path. Notifications from `dispose()` are deferred
(`_emitAfterFrame`) because notifying during unmount throws "widget tree was locked".

### 2.5 Pagination, caching, errors, analytics

- Feed: `TrendFeedBloc`, page size 20, `DocumentSnapshot` cursor, Hive projection cache
  (`trends_feed_cache`) — unaffected by this feature.
- Caching: images use `CldImageWidget(cache: true)`; **videos are not cached on the feed path**
  (`cached_video_player_plus` is used only by the legacy widget). Delivery relies on the Cloudinary CDN.
- Errors: `_failed` overlay per tile; `VideoUploadException`; dartz `Either` in services/blocs.
- **No analytics SDK** (`firebase_analytics` is not a dependency).

## 3. Cloudinary delivery strategy

### 3.1 Renditions (same public id, no re-upload)

```
SD  https://res.cloudinary.com/<cloud>/video/upload/c_limit,w_854,h_854,q_auto,vc_h264,f_mp4/<public_id>.mp4
HD  https://res.cloudinary.com/<cloud>/video/upload/c_limit,w_1280,h_1280,q_auto,vc_h264,f_mp4/<public_id>.mp4
```

- `c_limit` — scales down to fit the box, **never upscales**, aspect preserved.
- `q_auto` — Cloudinary picks the quality/bitrate; `vc_h264` pins the codec, `f_mp4` pins a
  progressive MP4 container (do **not** use `f_auto`: it can deliver HLS/WebM, which
  `video_player` cannot play).
- The two URLs differ, so CDN cache keys and any future local cache stay separate.
- Posters keep using the existing `so_0,w_720,q_auto` string, moved into the same builder.

### 3.2 Eager generation of SD

`eager` cannot be attached to an unsigned upload. Two ways to have SD ready before the first viewer:

| Option | How | Cost |
| --- | --- | --- |
| **A (recommended)** | Configure the SD transformation in the **upload preset** (`eager` on the preset, `eager_async: false`). No app change, no deploy. | Console configuration must match the URL template exactly, or the first request regenerates. |
| **B** | New `warmVideoRenditions` callable that calls Cloudinary's `explicit` API with the SD eager transformation right after upload. | One Function + deploy + secret already present; gives logs and per-upload control. |

HD stays **on demand** (first HD request transcodes once; the CDN then serves it).

### 3.3 "Transformation not ready"

A derived asset can answer `423 Locked` (or time out) while Cloudinary transcodes. Handling:

- SD init: one retry after ~1.5 s, then fall back to the original `media.url` (playback always works).
- HD request: retry once, then surface a non-blocking error and stay on SD.
- Never gate playback on a rendition being ready.

## 4. Quality model

```dart
// lib/core/media/cloudinary_video_urls.dart
enum VideoQuality { sd, hd }

class VideoRendition {
  final VideoQuality quality;
  final Uri url;
  final int box;          // 854 | 1280
}

class CloudinaryVideoUrls {
  static const int sdBox = 854;
  static const int hdBox = 1280;
  static String cloudName();                       // from cloudinary_url, cached
  static Uri poster(String publicId);
  static Uri rendition(String publicId, VideoQuality quality);
  static List<VideoRendition> renditions(String publicId);
  static String? publicIdOf(FeaturedMediaModel media); // uid, falling back to url
}
```

Quality is **per tile state**, not manager state: the spec requires that scrolling to another video
starts in SD again, so nothing is persisted or keyed in `VideoPlaybackManager`.

## 5. File changes

### New

| File | Purpose |
| --- | --- |
| `lib/core/media/cloudinary_video_urls.dart` | `VideoQuality`, `VideoRendition`, URL builder, cloud-name resolution, poster URL |
| `lib/presentation/widgets/video/video_quality_selector.dart` | Compact SD/HD pill: current quality, loading, disabled-while-switching, error affordance |
| `test/video/cloudinary_video_urls_test.dart` | URL templates, no-upscale boxes, public-id extraction, fallback |
| `test/video/inline_video_tile_quality_test.dart` | SD default, no HD request, switch, position/mute/pause preservation, failure, rapid switching |

### Modified

| File | Change |
| --- | --- |
| `lib/presentation/widgets/video/inline_video_tile.dart` | SD-by-default init, `_quality` state, `_switchQuality()` (seamless swap), selector in `_Controls`, HD failure handling, generation guard for stale initializations |
| `lib/data/models/video/video_upload_models.dart` | Poster URL via the shared builder (delete the inline transformation string); keep `url` = original |
| `lib/presentation/widgets/video/trend_video_hero.dart` | Play the **SD** rendition by default (selector optional, see open questions) |
| `lib/presentation/screens/trends/widgets/my_post_feed_card_widget.dart` | One-line: hand the legacy preview the SD URL instead of the original |
| `test/video/inline_video_tile_test.dart` | Update for the SD default |

Not touched: `VideoPlaybackManager`, `TrendFeedBloc`, Hive services, the upload pipeline, pagination.

## 6. Seamless switching (the critical path)

```
_switchQuality(HD)
  ├─ if (_switching || _quality == HD) return          // disable repeats
  ├─ _switching = true; setState                        // selector shows a spinner
  ├─ snapshot: position, wasPlaying, muted, generation++
  ├─ new = VideoPlayerController.networkUrl(HD url)
  ├─ await new.initialize()  ── fail ──► dispose new, keep SD, show error, allow retry
  ├─ await new.setLooping(true); await new.setVolume(muted ? 0 : 1)
  ├─ await new.seekTo(position)
  ├─ if (generation changed || !mounted) { dispose new; return }   // scrolled away / newer request
  ├─ old = _controller; _controller = new; _quality = HD; setState
  ├─ if (wasPlaying) await new.play()
  └─ await old.dispose()
```

Rules: never two playing controllers; the old one is disposed immediately after the swap; the poster
stays under the new controller until its first frame, so there is no black flash; stale
initializations are dropped by the generation counter.

## 7. Compatibility issues and risks

| # | Issue | Impact | Mitigation |
| --- | --- | --- | --- |
| 1 | Unsigned upload cannot set `eager` | SD may transcode on first view | Preset eager (A) or `explicit` callable (B) |
| 2 | `f_auto` can deliver HLS/WebM | `video_player` fails to initialize | Pin `f_mp4` + `vc_h264` |
| 3 | First-view transcode latency / 423 | SD init error | One retry, then original `media.url` |
| 4 | Two controllers during a switch | Memory spike, double audio | Swap then dispose immediately; never `play()` before swap |
| 5 | Quality must reset per video | User loses HD when scrolling | Accepted (spec); SD is re-initialized |
| 6 | Legacy `VideoPreviewWidget` bypasses the manager | "My posts" plays the original | Point it at the SD URL (one line); full migration is a follow-up |
| 7 | No analytics SDK | §11 cannot be implemented as specified | No-op `VideoQualityAnalytics` + `debugPrint`; add Firebase Analytics separately |
| 8 | Existing documents | None — `uid` is the public id | Fall back to `url` when `uid` is missing |
| 9 | HD URL is public | Cannot be hidden from a determined client | Not a security boundary; accepted |
| 10 | `video_player` platform view on iOS | Swap may flash for one frame | Poster remains under the player until first frame |

## 8. Milestones

| # | Scope | Estimate |
| --- | --- | --- |
| M1 | This assessment | done |
| M2 | `cloudinary_video_urls.dart` + unit tests; verify SD/HD URLs resolve in a browser and that SD is eager | S |
| M3 | `InlineVideoTile` plays SD by default; generation guard; fallback to original on failure | M |
| M4 | `VideoQualitySelector` in `_Controls` (current quality, loading, disabled, error) | S |
| M5 | `_switchQuality` with position/mute/pause preservation and stale-request handling | M |
| M6 | Tests (unit + widget) and the device matrix: iOS/Android, Wi-Fi/cellular, background during switch | M |

## 9. Acceptance criteria

- Every feed video initializes with the SD URL; the HD URL is not requested until the user taps HD
  (asserted by recording requested URLs in a fake).
- Only one rendition plays at a time; only one controller is alive outside a switch.
- Position, mute and play/pause survive an SD→HD switch.
- HD failure leaves SD playing and offers a retry.
- Scrolling away mid-switch disposes the in-flight HD controller and never activates it.
- Image posts, the composer, the detail screen and pagination behave exactly as before.
- `flutter analyze` stays at the current baseline; the full test suite stays green apart from the
  pre-existing boilerplate `widget_test.dart`.

## 10. Decisions (answered before implementation)

1. **Eager: preset (A).** The SD transformation is configured on the unsigned upload preset in the
   Cloudinary console; no `explicit` callable and no upload change. The URL template in §3.1 must match
   the preset's eager transformation exactly.
2. **Detail screen gets the selector too** (`TrendVideoHero`, top-left).
3. **Always start SD** — no persisted quality, no session memory.
4. **No-op analytics interface now** (`VideoQualityAnalytics`, debug-only sink); a real SDK can be
   swapped in later without touching the widgets.
5. **SD box 854 confirmed** (480×854 for a 9:16 clip).

## 11. Implementation record

Delivered:

| File | What |
| --- | --- |
| `lib/core/media/cloudinary_video_urls.dart` | `VideoQuality`, `VideoRendition`, SD/HD/poster URL builder, public-id resolution (uid, then URL parsing) |
| `lib/core/media/video_quality_analytics.dart` | Event enum + `VideoQualityAnalytics` seam with a debug-only sink (no URLs, no ids) |
| `lib/presentation/widgets/video/video_quality_selector.dart` | SD/HD pill: current quality, spinner while switching, tap disabled during a switch, hidden when no public id |
| `lib/presentation/widgets/video/video_rendition_loader.dart` | Opens a rendition, restores volume/position/loop, disposes on failure |
| `lib/presentation/widgets/video/inline_video_tile.dart` | SD default, generation guard, initial retry + original fallback, seamless switch, pill beside play/pause |
| `lib/presentation/widgets/video/trend_video_hero.dart` | Same behaviour on the detail screen, pill top-left |
| `lib/data/models/video/video_upload_models.dart` | Poster URL now comes from the builder (inline transformation string deleted) |
| `lib/presentation/screens/trends/widgets/my_post_feed_card_widget.dart` | Legacy profile preview plays the SD rendition |

Tests: `cloudinary_video_urls_test.dart` (12), `video_quality_selector_test.dart` (5),
`inline_video_tile_test.dart` (+2 SD-default cases), plus the existing 92 video tests.

Deviations from the spec:

- **`startupDelay` is defined but never logged.** It only fires for slow starts, and the tile has no
  reliable hook for "first frame" on `video_player`. `sdPlaybackStarted` carries the measured
  `durationMs` instead.
- **No "buffering" event.** `video_player` exposes `isBuffering`, but sampling it would add a timer to
  every active card for a metric nothing consumes yet.
- **Quality resets on `_stop()`** (scroll away, autoplay off, background) — the spec's rule, not a bug.

Still open:

- **Device matrix**: iOS/Android, Wi-Fi vs cellular, background during a switch, and a real Cloudinary
  account where SD is eager. Not run here.
- **Preset configuration** must be done in the console before SD is truly eager; until then the first
  viewer pays the transcode (handled by the retry + original fallback).

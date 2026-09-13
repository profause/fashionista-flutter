# AGENTS.md

Flutter app "Fashionista" (smart fashion management: designers/clients, measurements, outfits, closet, work orders, trends feed). No CI, no meaningful tests — verify changes with `flutter analyze` and manual runs.

## Commands

- `flutter pub get` — install deps
- `flutter analyze` — the main verification step (flutter_lints the only gate)
- `dart run build_runner build --delete-conflicting-outputs` — REQUIRED after editing any model annotated `@JsonSerializable` or `@HiveType` (regenerates `*.g.dart`). Check in the generated files.
- `flutter test` — only boilerplate `test/widget_test.dart` exists; do not rely on it for correctness
- `flutter run` — default launch config

## Architecture

- Clean architecture, 4 layers: `lib/core` (theme, routes, auth, DI, widgets, models), `lib/data` (model+bloc per area, repository impls, `services/firebase/*`, `services/hive/*`), `lib/domain` (entity + repository interfaces + usecases), `lib/presentation` (screens, widgets).
- Each feature area follows the same pattern: `domain/repository/{area}.dart` interface → `data/repository/{area}_repository_impl.dart` → `data/models/{area}/bloc/` (bloc/event/state) + firebase & hive services.
- DI: get_it singletons, all registered in `lib/core/service_locator/service_locator.dart` (`sl`, `initialiseDependencies()`). Add new repos/usecases/services here.
- State: flutter_bloc + hydrated_bloc. All BlocProviders are registered in `lib/main.dart` (MultiBlocProvider) — add new blocs there too.
- Navigation: global `appRouter` (go_router) in `lib/core/routes/app_router.dart`; main tabs = StatefulShellRoute.indexedStack (Home, Clients/Designers, Closet, Profile).
- Theme: manual Material 3 themes in `lib/core/theme/app.theme.dart`; brand accent is `AppTheme.appIconColor` (0xFFF55B02 orange).
- Auth: phone SMS OTP via Firebase; routing decided in `splash_screen.dart` (onboarding → sign-in → create-profile → home).

## Config & secrets — do NOT hardcode

- Runtime config (cloudinary_url, ad unit ids, recaptcha keys) comes from Firebase Remote Config (`appConfig`, `lib/core/service_locator/app_config.dart`), keyed by `environments` JSON. Values live in the firebase console, not code. Never inline new secrets in source; add RC keys instead.
- Env selection: `--dart-define ENV`, defaults to `dev` in debug, `prod` in release.
- Image/media storage uses Cloudinary (migrated from Firebase Storage Nov–Dec 2025). Display via `CldImageWidget`; upload calls in services/screens — if you touch upload logic, reuse the existing per-service helpers rather than adding a new pattern.

## Conventions

- Git: work on `dev` (not master), direct commits, lowercase terse messages ("added designer homepage", "bug fixes"). No PRs/feature branches/hooks.
- Repos are pure interfaces; impls delegate to `sl<...>()` services (dartz `Either` for results/errors).
- Models use `@JsonSerializable(explicitToJson: true)` + `@HiveType(typeId: …)`; types registered in `lib/core/models/hive/hive_type.dart`.

## Gotchas

- Blocs are created at app level (`main.dart`), not screen-local — expect screen code to `context.read` an existing bloc.
- There is known dead/duplicated code (e.g. `signInWithPhoneNumber` vs `signInWithPhoneNumber2`, commented deep-links in `main.dart`); don't assume commented-out code is safe to re-enable.
- `firebase.json` configures the `fashionista-2025` Firebase project for Android/iOS — keep native config (`google-services.json`, `GoogleService-Info.plist`) in sync if adding Firebase features.
# Draculin-Front

BitsXLaMarató 2023 finalist: Flutter frontend for Draculin, a sexual and reproductive health app combining a chatbot with a computer-vision tool that estimates blood volume on sanitary products from photos.

## Architecture
- Flutter app (Dart, SDK `>=3.2.3 <4.0.0`) under [dracu_app/](dracu_app/); entry point [dracu_app/lib/main.dart](dracu_app/lib/main.dart).
- Cross-platform targets: `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`.
- Key dependencies (see [dracu_app/pubspec.yaml](dracu_app/pubspec.yaml)): `camera`, `http`, `path_provider`, `url_launcher`, `cupertino_icons`.
- Backend URL injected at build time via `--dart-define=API_URL=...` (default `http://localhost:8889`, see [Dockerfile](Dockerfile)).

## Build and Test
From `dracu_app/`:
- `flutter pub get` — install dependencies.
- `flutter run` — run on a connected device/emulator.
- `flutter build web --release --dart-define=API_URL=<backend-url>` — build web bundle.
- `flutter test` — run widget/unit tests in `test/`.

From repo root, [Dockerfile](Dockerfile) builds the web target with Flutter 3.19.6 and serves it via nginx on port 80.

## Pitfalls
- Hackathon code — treat as frozen; avoid refactors beyond the user's request.
- Fork of `BITS2023/Draculin-Front`; upstream is the original hackathon repo.
- Pairs with `Draculin-Backend` (expected at `API_URL`, default port 8889).
- Only `lib/main.dart` exists — no module split yet; the app is a single-file Flutter project.

See [README.md](README.md) (Spanish) for project background and motivation.

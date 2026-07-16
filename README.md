# sudare

macOS app for covering a secondary monitor with a dim, solid overlay.

## MVP

- Go-based implementation
- macOS only
- Small control window
- Target monitor selection
- Opacity control in 10% steps
- Solid dark gray overlay

## Build App

```bash
./scripts/build_app.sh
open dist/sudare.app
```

The build script creates `dist/sudare.app` with the bundled app icon from `assets/AppIcon.png`.

## Controls

- `簾を下ろす / 簾を上げる`
- `透明度`
- `対象モニター`

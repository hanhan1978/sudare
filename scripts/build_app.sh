#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_dir="$root_dir/dist/sudare.app"
contents_dir="$bundle_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
iconset_dir="$root_dir/dist/AppIcon.iconset"

rm -rf "$bundle_dir"
rm -rf "$iconset_dir"
mkdir -p "$macos_dir" "$resources_dir"

cd "$root_dir"

cp "$root_dir/Info.plist" "$contents_dir/Info.plist"

mkdir -p "$iconset_dir"
sips -z 16 16     "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_16x16.png" >/dev/null
sips -z 32 32     "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_32x32.png" >/dev/null
sips -z 64 64     "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_128x128.png" >/dev/null
sips -z 256 256   "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_256x256.png" >/dev/null
sips -z 512 512   "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$root_dir/assets/AppIcon.png" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null
GOCACHE="${GOCACHE:-/private/tmp/go-cache}" \
GOMODCACHE="${GOMODCACHE:-/private/tmp/go-mod-cache}" \
go run ./scripts/make_icns.go "$iconset_dir" "$resources_dir/AppIcon.icns"

GOCACHE="${GOCACHE:-/private/tmp/go-cache}" \
GOMODCACHE="${GOMODCACHE:-/private/tmp/go-mod-cache}" \
go build -o "$macos_dir/sudare" .

chmod +x "$macos_dir/sudare"

echo "Built $bundle_dir"

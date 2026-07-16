#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle_dir="$root_dir/dist/sudare.app"
contents_dir="$bundle_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"

rm -rf "$bundle_dir"
mkdir -p "$macos_dir" "$resources_dir"

cp "$root_dir/Info.plist" "$contents_dir/Info.plist"

cd "$root_dir"

GOCACHE="${GOCACHE:-/private/tmp/go-cache}" \
GOMODCACHE="${GOMODCACHE:-/private/tmp/go-mod-cache}" \
go build -o "$macos_dir/sudare" .

chmod +x "$macos_dir/sudare"

echo "Built $bundle_dir"

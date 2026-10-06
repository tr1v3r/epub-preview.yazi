#!/bin/sh
# Build a throwaway demo environment: an isolated YAZI_CONFIG_HOME holding only
# this plugin, plus a few generated (copyright-free) EPUBs.
#
# Usage:  sh docs/demo-env.sh [target-dir]     # default: /tmp/epub-preview-demo
#
# Then, in a graphics-capable terminal:
#   YAZI_CONFIG_HOME=<target>/config yazi <target>/books
#
# `docs/demo.tape` calls this too, so the recording and manual demo stay in sync.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
demo_root=${1:-$(cd /tmp && pwd -P)/epub-preview-demo}

rm -rf "$demo_root"
mkdir -p "$demo_root/config/plugins/epub-preview.yazi"

cp "$repo_root/main.lua" "$demo_root/config/plugins/epub-preview.yazi/main.lua"
cp -R "$repo_root/assets" "$demo_root/config/plugins/epub-preview.yazi/assets"

printf '%s\n' \
	'[mgr]' \
	'ratio = [1, 2, 4]' \
	'' \
	'[[plugin.prepend_previewers]]' \
	'mime = "application/epub+zip"' \
	'run = "epub-preview"' > "$demo_root/config/yazi.toml"

# Reuse the recorder's own theme when it exists, so a demo looks like their setup.
real="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
if [ -f "$real/theme.toml" ] && [ -d "$real/flavors" ]; then
	cp "$real/theme.toml" "$demo_root/config/"
	cp -R "$real/flavors" "$demo_root/config/"
fi

sh "$repo_root/docs/make-demo-epub.sh" "$demo_root/books"

echo "demo environment ready: $demo_root"
echo "  run: YAZI_CONFIG_HOME=$demo_root/config yazi $demo_root/books"

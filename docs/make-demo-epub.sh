#!/bin/sh
# Build small, copyright-free EPUB fixtures for the demo recording and tests.
#
# Usage: make-demo-epub.sh <out-dir>
#
# The covers are generated, so nothing here is anyone's copyrighted book, and
# the fixtures are safe to commit, record and ship.
set -eu

out=${1:?usage: make-demo-epub.sh <out-dir>}
mkdir -p "$out"
out=$(cd "$out" && pwd)

# ImageMagick here has no font config (`magick -list font` is empty), so an
# explicit font path is mandatory rather than optional.
find_font() {
	for f in "$@"; do
		if [ -f "$f" ]; then
			printf '%s' "$f"
			return 0
		fi
	done
	return 1
}

serif=$(find_font \
	"/System/Library/Fonts/Supplemental/Georgia.ttf" \
	/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf \
	/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf) \
	|| { echo "make-demo-epub: no usable serif font found; extend the font list" >&2; exit 1; }
serif_bold=$(find_font \
	"/System/Library/Fonts/Supplemental/Georgia Bold.ttf" \
	/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf \
	/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf) || serif_bold=$serif

build() {
	title=$1
	subtitle=$2
	from=$3
	to=$4

	work=$(mktemp -d)
	mkdir -p "$work/META-INF" "$work/OPS"

	magick -size 1200x1800 "gradient:${from}-${to}" \
		-fill none -stroke '#c0caf5' -strokewidth 2 \
		-draw "rectangle 90,90 1110,1710" \
		-stroke none -font "$serif_bold" -pointsize 76 -fill '#e6e9f5' \
		-gravity north -annotate +0+380 "$title" \
		-font "$serif" -pointsize 34 -fill '#9db4e8' \
		-gravity north -annotate +0+600 "$subtitle" \
		-pointsize 24 -fill '#6b7394' \
		-gravity south -annotate +0+150 "generated fixture" \
		"$work/OPS/cover.png"

	# EPUB requires `mimetype` first, stored uncompressed.
	printf 'application/epub+zip' > "$work/mimetype"

	cat > "$work/META-INF/container.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
XML

	cat > "$work/OPS/content.opf" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">urn:uuid:demo-${title}</dc:identifier>
    <dc:title>${title}</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="cover-image" href="cover.png" media-type="image/png" properties="cover-image"/>
  </manifest>
  <spine>
    <itemref idref="cover"/>
  </spine>
</package>
XML

	cat > "$work/OPS/cover.xhtml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Cover</title></head>
  <body><div><img src="cover.png" alt="cover"/></div></body>
</html>
XML

	(cd "$work" && zip -X0q "${out}/${title}.epub" mimetype \
		&& zip -Xr9q "${out}/${title}.epub" META-INF OPS)
	rm -rf "$work"
}

build "The Terminal Handbook" "a field guide"        '#1a1b26' '#3d59a1'
build "Pixels and Pages"      "on reflowable text"   '#241b3d' '#bb9af7'
build "A Study in Reflow"     "typesetting, loosely" '#12261f' '#9ece6a'

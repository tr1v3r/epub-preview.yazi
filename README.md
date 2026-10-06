# epub-preview.yazi

Preview EPUB covers in [Yazi](https://yazi-rs.github.io/).

Yazi ships no EPUB previewer, and `application/epub+zip` matches none of the
built-in rules: the archive rule `application/{,g}zip` expands to exactly
`application/zip` and `application/gzip`, never `application/epub+zip`. An EPUB
therefore falls through to the `file` preset, whose entire output is:

```
----- File Type Classification -----

EPUB document
```

This plugin fills that gap. It renders the book's first page — normally the
cover — and hands the pixels to Yazi's image pipeline, the same way the built-in
`pdf` previewer does.

## Requirements

- Yazi 26.x
- A Python interpreter that can `import pymupdf` ([PyMuPDF](https://pymupdf.readthedocs.io/), the MuPDF bindings)

```sh
python3 -m pip install pymupdf
```

MuPDF reflows the EPUB itself, so there is no OPF parsing here and no dependency
on `epub-thumbnailer` / `gnome-epub-thumbnailer` (both Linux-only).

## Install

```sh
ya pkg add tr1v3r/epub-preview
```

Register the previewer in `~/.config/yazi/yazi.toml`:

```toml
[[plugin.prepend_previewers]]
mime = "application/epub+zip"
run = "epub-preview"
```

Restart Yazi, then hover an `.epub`.

## Configuration

Optional, in `~/.config/yazi/init.lua`:

```lua
require("epub-preview"):setup({
	-- Default: <config>/plugins/epub-preview.yazi/render.sh
	renderer = "/path/to/render.sh",
	-- Long edge of the rendered page, in pixels. Default: the preview pane's
	-- own pixel budget (min of preview.max_width / preview.max_height).
	size = 1800,
})
```

If PyMuPDF lives in an interpreter that is not `python3`/`python` on `PATH`,
point `EPUB_PREVIEW_PYTHON` at it instead of using `setup`.

## How it works

```
hover book.epub
  └─ preload   render.sh → render.py → PyMuPDF → PNG
  │              └─ ya.image_precache(png, ya.file_cache(job))
  └─ peek      ya.image_show(cache, job.area)
```

The page is cached per file by Yazi, so only the first hover pays for it
(measured on an M-series Mac: 0.38 s cold, 0.01 s warm; a 3949-page book 1.4 s
cold).

`render.sh` probes candidate interpreters with `import pymupdf` instead of
assuming, and `main.lua` invokes it as `sh render.sh` — `ya pkg` seals installed
files read-only, so a shebang and an executable bit would not survive.

## Troubleshooting

- **No preview at all** — confirm libmagic reports the expected type:
  `file --mime-type book.epub` should print `application/epub+zip`. Yazi derives
  `job.mime` from `file`, so a book reported as something else needs its own
  rule.
- **`no Python with PyMuPDF found`** — the renderer's stderr is shown in the
  preview pane, along with everything it tried.
- **Blank pane for a specific book** — only page 1 is rendered, and some books
  open on a blank or near-empty page.
- **Wrong mime wins** — another previewer registered earlier for `application/*zip`
  can shadow this one; check the order of `prepend_previewers` in `yazi.toml`.

## Credits

Inspired by [kirasok/epub-preview.yazi](https://github.com/kirasok/epub-preview.yazi),
which renders through `epub-thumbnailer`/`gnome-epub-thumbnailer`; this one uses
PyMuPDF so it also works on macOS.

## License

MIT

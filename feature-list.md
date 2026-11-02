# MD-Viewer — Feature List

A native Markdown editor and viewer for Ubuntu Linux, written in Rust with
egui/eframe (wgpu → Vulkan), winit and pulldown-cmark.

## Markdown

- **CommonMark + GFM** — headings, emphasis, strikethrough, inline code,
  ordered/unordered/task lists, tables, block quotes, fenced and indented code,
  links, images, footnotes and horizontal rules.
- **Extended dialects** — Obsidian callouts, wiki-links and `![[…]]` embeds,
  tags, block ids, comments and properties; Pandoc/Quarto fenced divs, inline
  notes, citations, heading attributes, grid tables and `[TOC]`; MkDocs
  admonitions and abbreviations; YAML, TOML and JSON front matter.
- **Math** — inline and display LaTeX (`$…$`, `$$…$$`, `\(…\)`, `\[…\]`),
  including matrices, `aligned`, `cases`, sums/products and multi-line formulas.
- **Diagrams** — Mermaid flowcharts, sequence, pie, class, state, Gantt and ER
  diagrams; inline and block SVG rasterized safely.
- **Safe HTML** — `<details>`, HTML tables with `colspan`/`rowspan`, images,
  `<div>`/`<section>` containers and inline formatting. Scripts, styles and
  comments never execute; video/audio/iframe become labelled cards.
- **Code blocks** — language-aware syntax highlighting and a language label.

## Editor & preview

- Rendered preview by default; **Edit** (Ctrl+Shift+P) opens a resizable split
  view with the source editor and live preview.
- Click any preview block to jump to the matching source line; switching views
  keeps the section you were reading or editing.
- **Find & replace** (Ctrl+F, Ctrl+G/Ctrl+Shift+G) with match counter,
  next/previous and replace one/all.
- **Outline sidebar** (Ctrl+Shift+O) listing headings; click one to jump to
  that section.
- Multiple tabs with per-tab edits, scroll position and unsaved markers.
- Zoom (Ctrl+/Ctrl−, Ctrl+0), picture viewer with pan/zoom, drag & drop.
- Large documents are virtualized (visible window plus overscan) above 250
  top-level blocks.
- UTF-8/UTF-16/BOM/Windows-1252 input; a save writes the file back in the same
  encoding (UTF-8 with a warning if a character cannot be represented);
  CJK, Arabic, Hebrew and other scripts via system fonts (Noto/DejaVu), with
  run-level bidi ordering for mixed-direction text.
- Relative `.md` links, wiki-links and wiki embeds open in tabs; `![[Note]]`
  transclusion is cycle-safe. Local files open with the system handler.
- Remote images are fetched with `curl` (HTTP/HTTPS only, no loopback or
  link-local hosts, redirects restricted)
  and capped at 25 MB / 40 megapixels.

## Files

- Native open, save and save-as dialogs; drag & drop; file-manager "Open
  With".
- Close confirmation with **Save / Don't Save / Cancel**; closing the window
  saves all dirty tabs.
- `start-up.md` is loaded at launch (`$XDG_DATA_HOME/md-viewer/start-up.md`,
  default `~/.local/share/md-viewer/`, or the working directory for
  `cargo run`) as an untitled document; relative images resolve against its
  folder. Deleting it starts an empty document.

## PDF export

- One-click **Export PDF** (Ctrl+E) with a native save dialog; **Print**
  (Ctrl+P) exports a temporary PDF and opens it with the desktop PDF viewer
  (`xdg-open`). The export runs in the background, so the window stays
  responsive.
- A4 pagination, running footer, selectable text, clickable links, embedded
  images, styled code/tables/callouts, typeset math and Mermaid diagrams.
- Uses the mandatory **WeasyPrint** CLI (`sudo apt install weasyprint` or
  `pip install weasyprint`) — no fallback writer. When it is missing, the
  button is greyed out and an onboarding dialog offers the install command and
  a re-check.
- PDF output follows GFM; preview-only extensions are printed as source.

## User interface

- Permanent **dark** slate/charcoal theme plus a warm **Paper** light theme.
- Ubuntu Sans for UI and Markdown (variable weights), Ubuntu Sans Mono for
  code; Noto/DejaVu fallbacks; no font picker.
- Window icon (hicolor theme icon via the `.desktop` entry), status toasts.
- Keyboard shortcuts: Ctrl+O, Ctrl+S, Ctrl+Shift+S, Ctrl+E, Ctrl+P, Ctrl+W,
  Ctrl+F, Ctrl+G/Ctrl+Shift+G, Ctrl+Shift+O, Ctrl+Shift+P, Ctrl+/−/0,
  Ctrl+X/C/V, Ctrl+A.

## Technical

- Rust 2024 · eframe/egui 0.37 · wgpu (Vulkan) · winit 0.30 ·
  pulldown-cmark 0.13 · Linux x86_64 (built against Ubuntu 26.04; runs on any
  desktop Linux with X11/Wayland and Vulkan).
- 182 unit/integration tests plus an ignored deep render pass; zero build,
  clippy and rustfmt warnings.
- User-local desktop integration via `build.sh --install`
  (`~/.local/bin/md-viewer`, `.desktop` entry with MIME registration,
  hicolor icons) and a zipped x86_64 release archive with SHA-256 checksum
  (`build.sh --package`).

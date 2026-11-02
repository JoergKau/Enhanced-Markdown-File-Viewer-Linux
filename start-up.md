# 🚀 MD-Viewer

---
> A native Markdown editor and viewer for **Ubuntu Linux**, written in Rust with **egui/eframe** (**wgpu** → Vulkan), **winit** and **pulldown-cmark**.

## Markdown

| Feature | Details |
| --- | --- |
| **CommonMark + GFM** | headings, emphasis, strikethrough, inline code, ordered/unordered/task lists, tables, block quotes, fenced and indented code, links, images, footnotes and horizontal rules. |
| **Extended dialects** | Obsidian callouts, wiki-links and `![[…]]` embeds, tags, block ids, comments and properties; Pandoc/Quarto fenced divs, inline notes, citations, heading attributes, grid tables and `[TOC]`; MkDocs admonitions and abbreviations; YAML, TOML and JSON front matter. |
| **Math** | inline and display LaTeX (`$…$`, `$$…$$`, `\(…\)`, `\[…\]`), including matrices, `aligned`, `cases`, sums/products and multi-line formulas. |
| **Diagrams** | Mermaid flowcharts, sequence, pie, class, state, Gantt and ER diagrams; inline and block SVG rasterized safely. |
| **Safe HTML** | `<details>`, HTML tables with `colspan`/`rowspan`, images, `<div>`/`<section>` containers and inline formatting. Scripts, styles and comments never execute; video/audio/iframe become labelled cards. |
| **Code blocks** | language-aware syntax highlighting and a language label. |

> [!NOTE] Editor & preview
> - Rendered preview by default; **Edit** (Ctrl+Shift+P) opens a resizable split view with
>   the source editor and live preview.
> - Click any preview block to jump to the matching source line; switching views
>   keeps the section you were reading or editing.
> - Multiple tabs with per-tab edits, scroll position and unsaved markers.
> - Zoom (Ctrl+/Ctrl−, Ctrl+0), picture viewer with pan/zoom, drag & drop.
> - Large documents are virtualized (visible window plus overscan) above 250
>   top-level blocks.
> - UTF-8/UTF-16/BOM/Windows-1252 input; CJK, Arabic and Hebrew via system fonts
>   (Noto/DejaVu), with run-level bidi ordering for mixed-direction text.
> - Relative `.md` links, wiki-links and wiki embeds open in tabs; `![[Note]]`
>   transclusion is cycle-safe.

> [!TIP] Files
> - Native open, save and save-as dialogs; drag & drop; "Open with MD-Viewer"
>   in the file manager.
> - Close confirmation with **Save / Don't Save / Cancel**; closing the window
>   saves all dirty tabs.
> - `start-up.md` is loaded at launch as an untitled document; its relative
>   images resolve against its folder. Deleting it starts an empty
>   document.

> [!IMPORTANT] PDF export
> - One-click **Export PDF** (Ctrl+E) with a native save dialog.
> - A4 pagination, running footer, selectable text, clickable links, embedded
>   images, styled code/tables/callouts, typeset math and Mermaid diagrams.
> - Uses the mandatory **WeasyPrint** CLI (`sudo apt install weasyprint`) — no
>   fallback writer. When it is missing, the button is greyed out and an
>   onboarding dialog offers the install command and a re-check.
> - **Print** (Ctrl+P) exports a temporary PDF and opens it with the desktop
>   PDF viewer.
> - PDF output follows GFM; preview-only extensions are printed as source.

> [!WARNING] User interface
> - Permanent **dark** slate/charcoal theme plus a warm **Paper** light theme.
> - Ubuntu Sans for UI and Markdown, Ubuntu Sans Mono for code; no font picker.
> - Window icon and desktop launcher entry, status toasts.
> - Keyboard shortcuts: <kbd>Ctrl+O</kbd>, <kbd>Ctrl+S</kbd>, <kbd>Ctrl+Shift+S</kbd>, <kbd>Ctrl+E</kbd>, <kbd>Ctrl+W</kbd>, <kbd>Ctrl+P</kbd>, <kbd>Ctrl+/−/0</kbd>, <kbd>Ctrl+X/C/V</kbd>, <kbd>Ctrl+A</kbd>.

> [!NOTE] Technical
> - Rust 2024 · eframe/egui 0.37 · wgpu (Vulkan) · winit 0.30 ·
>   pulldown-cmark 0.13 · Linux x86_64.
> - 182 unit/integration tests plus an ignored deep render pass; zero build,
>   clippy and rustfmt warnings.
> - User-local desktop integration through `build.sh --install`
>   (`~/.local/bin`, `.desktop` entry, hicolor icons) and a zipped x86_64
>   release archive with SHA-256 checksum (`build.sh --package`).

# MD-Viewer

A native Markdown editor and viewer for Ubuntu Linux — written in Rust with
**egui/eframe** (wgpu → Vulkan), **winit** and **pulldown-cmark**.

Edit Markdown on the left, see a live preview on the right, and export the
document as a PDF. The editor and preview are self-contained — no Node, no
browser engine, no webview. PDF export uses the `weasyprint` CLI as its single,
mandatory conversion step (no fallback writer), so it has to be installed once;
the app shows an onboarding dialog with the exact command.

![Rust](https://img.shields.io/badge/Rust-2024-000?logo=rust)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20x86_64-lightgrey)
![PDF export](https://img.shields.io/badge/PDF%20export-WeasyPrint-orange)

---

## Installation (release archive)

The published archive is `md-viewer-<version>-x86_64.tar.gz`. It is a
portable, user-local install (no `sudo` needed).

1. Unpack:
   `tar -xzf md-viewer-<version>-x86_64.tar.gz`
2. Run the installer:
   `./md-viewer-<version>/install.sh` — installs the binary, a `.desktop`
   entry and theme icons into `~/.local`.
3. Log out/in once (or run `update-desktop-database`) so the menu picks up the
   new entry; afterwards *MD-Viewer* appears in the application menu and opens
   `.md` files from the file manager.
4. PDF export only: install WeasyPrint once with
   `sudo apt install weasyprint`.
   MD-Viewer shows an onboarding dialog at launch with the same command and a
   **Check again** button. The editor and preview work without WeasyPrint.

Verify the download against the published checksum:

```bash
sha256sum -c md-viewer-<version>-x86_64.tar.gz.sha256
```

See `build.sh` for an uninstall target (`./build.sh --uninstall`).

---

## Highlights

- **Complete Markdown** — CommonMark + GFM, tables, task lists, footnotes, callouts, code highlighting and typeset LaTeX math.
- **Obsidian & Pandoc** — wiki-links, `![[…]]` embeds, front matter, fenced divs, admonitions and `[TOC]`.
- **Live preview & split editor** — click any preview block to jump to its source line; find & replace and an outline sidebar keep long documents navigable.
- **Print-quality PDF** — A4, running footer, clickable links, images, math and Mermaid via WeasyPrint.
- **Native Ubuntu UI** — dark and Paper themes, Ubuntu Sans/Ubuntu Sans Mono, tabs, drag & drop, file-manager integration.
- **Fast & self-contained** — Vulkan-accelerated rendering, virtualized large documents, no browser engine.
- AI assisted by **GLM**.

See [feature-list.md](feature-list.md) for a concise feature overview and the
technical characteristics.

---

## Requirements

| Requirement | Notes |
| --- | --- |
| Ubuntu 22.04 or newer (or any Linux with Vulkan/X11/Wayland) | Built and tested on Ubuntu 26.04 x86_64. |
| Rust toolchain (stable) | Install via [rustup](https://rustup.rs). `cargo` and `rustc` must be on `PATH`. |
| Build tools | `sudo apt install build-essential pkg-config`. |
| WeasyPrint *(required for PDF export only)* | `sudo apt install weasyprint` — the single PDF conversion step (A4 pagination, font fallback, link annotations). Missing or failing WeasyPrint is reported as an export error; there is no fallback writer. MD-Viewer shows an onboarding dialog with the install command when it is missing. |
| `xdg-utils` | For the **Print** action (`xdg-open`) and the "Open With" registration. Preinstalled on every Ubuntu desktop. |

No extra packages are needed for the editor and preview. All Rust dependencies
are pure-Rust crates fetched by Cargo. Remote images are downloaded with
`curl` (already installed on every Ubuntu system). The Vulkan runtime
(`mesa-vulkan-drivers`, installed by default on Ubuntu desktops) serves as the
wgpu backend; the window runs on X11 or Wayland, whichever the session uses.

Verify your toolchain:

```bash
rustc --version
cargo --version
```

---

## Quick Start

```bash
git clone https://github.com/JoergKau/Enhanced-Markdown-File-Viewer-Linux.git MD-Viewer
cd MD-Viewer
cargo run --release
```

The first build compiles the full wgpu/egui stack and can take a few minutes.
Subsequent builds are incremental.

For development (faster compile, debug assertions):

```bash
cargo run
```

---

## Startup document

MD-Viewer opens `start-up.md` when it launches. The file is loaded at runtime,
not compiled into the binary. Candidates, in order:

- **Installed app:** `$XDG_DATA_HOME/md-viewer/start-up.md`
  (default `~/.local/share/md-viewer/start-up.md`)
- **`cargo run`:** `start-up.md` in the current working directory

It is opened as an untitled document, so edits require **Save As…** and never
modify the shipped file. Relative images and links resolve against the file's
own folder. If the file is missing or unreadable, the app starts with an empty
document — deleting `start-up.md` is always safe.

---

## Building

### Debug build

```bash
cargo build
```

Binary: `target/debug/md_viewer`

### Release build (recommended)

```bash
cargo build --release
```

Binary: `target/release/md_viewer` (the installed name is `md-viewer`)

The release build runs with thin LTO and stripped symbols
(`[profile.release]` in `Cargo.toml`).

### Desktop packaging

`build.sh` builds the release binary and installs it as a desktop application
for the current user (no `sudo`):

```bash
./build.sh                 # build target/release/md_viewer
./build.sh --install       # + ~/.local/bin/md-viewer, .desktop entry, icons,
                           #   ~/.local/share/md-viewer/start-up.md,
                           #   registers the Markdown MIME handler
./build.sh --package       # + dist/md-viewer-<version>-x86_64.tar.gz (+ .sha256)
./build.sh --uninstall     # remove everything --install placed in ~/.local
```

The `.desktop` entry registers `md-viewer` for `text/markdown` /
`text/x-markdown` via `xdg-mime`, sets `StartupWMClass=md-viewer` and shares
that id with the app (`ViewportBuilder::with_app_id("md-viewer")` in
`main.rs`, matching the X11 `WM_CLASS` derived from the binary name), so the
window manager can associate the running window with the launcher icon.

### Tests and lints

```bash
cargo test
cargo clippy --all-targets
```

All tests must pass and there should be zero warnings. The 182 tests cover the
parser (including HTML block conversion and the extended compatibility
corpus), the print-HTML renderer (preprocessors, sanitizer, template,
math/Mermaid image embedding, escape/base64 helpers), the WeasyPrint runner
(missing/failing binary handling and a real end-to-end export when WeasyPrint
is installed), the dark/Paper palettes, the tab state machine, encoding
detection, bidi reordering, link resolution, preview virtualization,
Pandoc/MkDocs/Obsidian extension parsing, front matter formats, media/SVG
handling, picture-viewer logic and magnification.

Two regression guards keep feature coverage complete:

- **Variant coverage** — a compiled-in fixture must exercise every `Block` and
  `Inline` variant the parser can produce. Adding a new construct without a
  fixture fails the test and names what is missing.
- **Headless render smoke** — a gallery document containing every construct is
  laid out with egui in both themes at four widths; the test asserts that the
  content of each feature actually appears in the draw list (not just that
  rendering did not panic).

All fixtures live in `src/test_fixtures.rs`, so the suite needs no external
Markdown files. For a slower end-to-end pass:
`cargo test full_documents_render_headlessly -- --ignored`.

---

## App icon

<p align="center"><img src="assets/AppIcon-1024.png" width="180" alt="MD-Viewer app icon"></p>

The design is a dark-slate squircle (`#0C1015`–`#2B3644`) with the blue accent
(`#0A84FF`) and the motif of a Markdown page with a folded corner carrying the
Markdown `M↓` mark. The shipped files:

| File | Purpose |
| --- | --- |
| `assets/AppIcon-1024.png` | 1024×1024 master, embedded in the binary for the runtime window icon |
| `assets/md-viewer-512.png` / `assets/md-viewer-256.png` | hicolor theme icons, installed by `build.sh --install` |

The 1024 px master is embedded in the binary and passed to
`ViewportBuilder::with_icon` — otherwise the window would use the egui logo in
task switchers. The menu/launcher icon comes from the hicolor theme through the
`.desktop` entry's `Icon=md-viewer` line.

To regenerate the theme icon sizes after editing the master, resize the master
with any raster tool and overwrite the two `md-viewer-*.png` files.

---

## Usage

| Action | How |
| --- | --- |
| Open a file | Toolbar **Open**, Ctrl+O, drag & drop, or "Open with MD-Viewer" in the file manager — opens in a new tab |
| Switch tabs | Click a tab, or re-open a file to jump to its existing tab (the tab strip appears with 2+ documents) |
| Close tab | Tab **×** button, middle-click, or Ctrl+W (prompts to save when dirty; closing down to one tab hides the strip) |
| Follow a local link | Click `[text](other.md)` or `[[Note]]` — opens in a tab (fragments are not scrolled to yet) |
| Save | Toolbar **Save**, Ctrl+S |
| Save as | Ctrl+Shift+S |
| Export PDF | Toolbar **Export PDF**, Ctrl+E. Without WeasyPrint the button is greyed out and opens the setup dialog; the rest of the app works normally |
| Print | Toolbar **Print**, Ctrl+P — exports a temporary PDF and opens it with the desktop PDF viewer (`xdg-open`) for printing |
| Find & replace | Toolbar **Find**, Ctrl+F; Ctrl+G / Ctrl+Shift+G next/previous, Esc closes |
| Outline | Toolbar **Outline**, Ctrl+Shift+O — click a heading to jump to that section |
| Toggle dark / Paper theme | Toolbar sun/moon button at the right (sun = dark active, moon = Paper active) |
| Switch view | Toolbar **Preview / Edit**, Ctrl+Shift+P — Edit shows raw text left and live preview right |
| Zoom | Toolbar **A−/A+**, Ctrl+/Ctrl−; the percentage readout between them shows the current magnification and resets to 100% when clicked (also Ctrl+0) |
| Inspect an image | Click an image in the preview; scroll to zoom, drag to pan, **Esc** (or **Close**) returns to the document |
| Cut / copy / paste | Ctrl+X / Ctrl+C / Ctrl+V or right-click in the editor |
| Select all | Ctrl+A or right-click → **Select All** |

Supported file extensions: `.md`, `.markdown`, `.mdown`, `.txt`.

---

## Project Structure

```text
MD-Viewer/
├── Cargo.toml / Cargo.lock
├── build.sh                    # release build, ~/.local install, tar packaging
├── README.md
├── LICENSE                     # MIT
├── feature-list.md             # concise feature overview
├── start-up.md                 # document shown on launch (runtime-loaded)
├── assets/
│   ├── AppIcon-1024.png        # master, embedded for the runtime window icon
│   ├── md-viewer-512.png       # hicolor theme icon
│   └── md-viewer-256.png       # hicolor theme icon
└── src/
    ├── main.rs                 # entry point, window + wgpu setup
    ├── parser.rs               # Markdown → Document model
    ├── encoding.rs             # UTF-8/UTF-16/legacy file decoding
    ├── ui.rs                   # egui app: theme, panels, preview, highlighting
    ├── html_export.rs          # Markdown → sanitized print HTML
    ├── export.rs               # PDF export: mandatory WeasyPrint runner
    └── test_fixtures.rs        # compiled-in Markdown corpus for the tests
```

Test documents, reference checkouts and build artifacts are intentionally not
part of the published tree (see `.gitignore`).

---

## Architecture

```text
 ┌────────────┐   text    ┌────────────┐   Document   ┌───────────────────────┐
 │  ui::App   │ ────────► │ parser.rs  │ ───────────► │ ui.rs (preview)       │
 │ (editor)   │           │ pulldown-  │              └───────────────────────┘
 └────────────┘ ◄──────── │ cmark      │ ◄───────────
          ▲        doc      └────────────┘   re-parsed     ┌─► export.rs (PDF:
                                on every change           │   raw Markdown →
                                                          │   html_export.rs →
                                                          │   WeasyPrint CLI)
 ```

1. `App::text` is the single source of truth.
2. On every edit, `parser::parse` rebuilds `App::doc`.
3. The preview renders `App::doc`; the PDF export renders the raw Markdown
   through the `html_export.rs` pipeline, so both follow the same source.

The document model (`parser::Block` / `parser::Inline`) is deliberately
UI-independent. To add a new Markdown feature, see the extension guides in the
module docs of `parser.rs`.

### PDF export pipeline

```text
raw Markdown ──► html_export.rs ──► print-ready HTML ──► weasyprint CLI ──► PDF
                  (fence/inline-code protection,       (A4 @page rules,
                   math/emoji/wiki/callout              running footer,
                   preprocessors, image data URIs,      .markdown-body CSS)
                   pulldown-cmark, ammonia sanitize)
```

WeasyPrint is the only conversion step. The executable is detected at export
time (`PATH`, then `/usr/local/bin` and `/usr/bin`), so desktop-launched
instances find apt/pipx installations. A missing binary or a non-zero exit is
returned to the UI as an error message (including the CLI's stderr) — no PDF
is written and there is no fallback writer.

---

## Dependencies

| Crate | Version | Purpose |
| --- | --- | --- |
| `eframe` | 0.37 | App shell, winit integration, wgpu backend (x11 + wayland features) |
| `egui_extras` | 0.37 | Local image loaders (plus in-tree background downloader for remote images) |
| `image` | 0.25 | PNG/JPEG/GIF/WebP decoding |
| `resvg` | 0.45 | SVG rasterizer (images and Mermaid diagrams) |
| `latex-rust` | 3.0.1 | Pure-Rust LaTeX math typesetting (preview) |
| `mermaid-svg` | 0.7 | Pure-Rust Mermaid parser/layout (preview) |
| `pulldown-cmark` | 0.13 | CommonMark + GFM parser (preview and print HTML) |
| `encoding_rs` | 0.8 | UTF-16/Windows-1252 decoding for opened files |
| `unicode-bidi` | 0.3 | Bidi levels for mixed LTR/RTL preview text |
| `toml` | 0.8 | TOML front matter (`+++` blocks) |
| `serde_json` | 1 | JSON front matter |
| `tl` | 0.7 | Small HTML parser for converting safe raw HTML blocks |
| `ammonia` | 4 | HTML sanitizer for the print pipeline (same policy as the reference implementation) |
| `regex` | 1 | Print preprocessors (math, emoji, wiki-links, callouts) |
| `rfd` | 0.16 | Native file dialogs (GTK portal backend on Linux) |
| `winit` | 0.30 | Windowing/event loop |
| `env_logger`, `log` | 0.11 / 0.4 | Logging (`RUST_LOG=debug`) |

PDF export uses the WeasyPrint CLI as its single conversion step (an external
program, not a Rust dependency); `src/export.rs` and `src/html_export.rs`
implement the pipeline and add no other runtime requirements.

---

## Fonts

The UI uses the fonts installed on the system, read at runtime (nothing is
bundled):

- **Body text:** Ubuntu Sans (variable file, all weights), falling back to
  Noto Sans or DejaVu Sans; real bold/italic/bold-italic cuts.
- **Code:** Ubuntu Sans Mono, else DejaVu Sans Mono / Noto Sans Mono.
- **Script fallbacks:** Noto CJK (SimSun-style collection faces for
  JP/KR/SC/TC/HK), Noto Naskh Arabic, Noto Sans Hebrew, Devanagari, Thai, Lao,
  Tamil and Bengali fonts are added automatically when installed, so
  multi-script documents render in the preview and the editor.

The print HTML (PDF export) uses the same families through CSS
(`Ubuntu Sans`, `Ubuntu Sans Mono`, `Noto Sans`), which WeasyPrint resolves
via fontconfig.

---

## Troubleshooting

**PDF export fails with "WeasyPrint not found"**

WeasyPrint is mandatory for PDF export. Check that it is installed and
executable:

```bash
which weasyprint
weasyprint --version
```

If it is missing: `sudo apt install weasyprint`. The app checks `PATH` plus
`/usr/local/bin` and `/usr/bin` at export time.

**PDF export fails with a WeasyPrint error**

The status bar shows the CLI's exit status and stderr. Enable logging
(`RUST_LOG=info`, see below) for the full message. No PDF is written in that
case — by design there is no fallback writer, so a broken file can never be
produced silently.

**The window does not appear / GPU error**

Run with logging enabled:

```bash
RUST_LOG=info cargo run
```

wgpu selects the Vulkan backend automatically. On machines whose only Vulkan
driver is lavapipe (software rendering) the app still runs, just slower; the
packages `mesa-vulkan-drivers` (default) or a vendor driver provide hardware
acceleration. Check with `vulkaninfo --summary` (package `vulkan-tools`).

**Remote images do not load**

Remote images are fetched with `curl`, so they honour the system proxy/VPN
configuration. Make sure the image URL is reachable from a terminal:

```bash
curl -I "https://img.shields.io/badge/Rust-2024-000?logo=rust"
```

Failed images are shown with a framed placeholder explaining the likely cause.

**Build is slow the first time**

The wgpu/egui dependency tree is large. Use `cargo build --release` once and
afterwards incremental builds are fast.

**The app does not appear in the file manager's "Open With" list**

Re-register the handler (as run by `./build.sh --install`):

```bash
xdg-mime default md-viewer.desktop text/markdown
update-desktop-database ~/.local/share/applications
```

**Debugging when launched from the desktop menu**

Menu-launched apps have no visible stderr. Redirect the log to a file:

```bash
mkdir -p ~/.local/share/md-viewer
MD_VIEWER_LOG_FILE=/tmp/md-viewer.log RUST_LOG=info md-viewer /path/to/document.md
# inspect /tmp/md-viewer.log
```

Log into a running desktop session with journalctl: `journalctl --user -xe`.

---

## License

MIT — see [LICENSE](LICENSE).

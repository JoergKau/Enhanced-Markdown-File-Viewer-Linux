#!/usr/bin/env bash
#
# build.sh — builds MD-Viewer and installs it as a native desktop application
# for Ubuntu Linux.
#
# Usage:
#   ./build.sh                 # build the release binary (target/release/md-viewer)
#   ./build.sh --install       # build + install to ~/.local (binary, .desktop, icons),
#                              # register the Markdown MIME handler
#   ./build.sh --package       # build + dist/md-viewer-<version>-x86_64.tar.gz
#   ./build.sh --uninstall     # remove everything --install placed in ~/.local
#
# All three steps are idempotent; --install never touches system directories.

set -euo pipefail

APP_NAME="md-viewer"
DISPLAY_NAME="MD-Viewer"
CRATE_NAME="md_viewer"

INSTALL=0
UNINSTALL=0
PACKAGE=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --package) PACKAGE=1 ;;
    --help|-h)
      awk 'NR > 2 && !/^#/ { exit } NR > 2 { sub(/^# ?/, ""); print }' "$0"
      exit 0
      ;;
    *)
      echo "error: unknown argument '$arg' (use --install, --package, --uninstall or --help)" >&2
      exit 1
      ;;
  esac
done

cd "$(dirname "$0")"

# Single source of truth for the version.
VERSION="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' Cargo.toml | head -n 1)"
if [ -z "$VERSION" ]; then
  echo "error: cannot read the package version from Cargo.toml" >&2
  exit 1
fi

uninstall() {
  local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
  rm -f "$HOME/.local/bin/$APP_NAME"
  rm -f "$data_dir/applications/$APP_NAME.desktop"
  rm -f "$data_dir/icons/hicolor/"{16x16,32x32,128x128,256x256,512x512}"/apps/$APP_NAME.png"
  rm -f "$data_dir/$APP_NAME/start-up.md"
  rm -f "$HOME/.local/share/md-viewer-startup.md"
  update-desktop-database "$data_dir/applications" 2>/dev/null || true
  echo "Uninstalled $DISPLAY_NAME from $HOME/.local"
}

if [ "$UNINSTALL" = "1" ]; then
  uninstall
  exit 0
fi

if ! command -v cargo >/dev/null 2>&1; then
  # A rustup default install lives in ~/.cargo/bin.
  if [ -f "$HOME/.cargo/bin/cargo" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  else
    echo "error: cargo not found — install Rust via https://rustup.rs" >&2
    exit 1
  fi
fi

echo "==> Building release binary ($DISPLAY_NAME $VERSION, $(uname -m))..."
cargo build --release

BINARY="target/release/$CRATE_NAME"
if [ ! -f "$BINARY" ]; then
  echo "error: expected binary not found: $BINARY" >&2
  exit 1
fi

install_app() {
  local prefix="$HOME/.local"
  local data_dir="${XDG_DATA_HOME:-$prefix/share}"
  local bin_dir="$prefix/bin"
  local apps_dir="$data_dir/applications"
  local icons_dir="$data_dir/icons/hicolor"
  local app_data="$data_dir/$APP_NAME"

  mkdir -p "$bin_dir" "$apps_dir" "$app_data"
  for size in 16x16 32x32 128x128 256x256 512x512; do
    mkdir -p "$icons_dir/$size/apps"
  done

  cp "target/release/$CRATE_NAME" "$bin_dir/$APP_NAME"
  chmod +x "$bin_dir/$APP_NAME"

  # Icon theme entries. 512/256 come from assets/; regenerate them from
  # assets/AppIcon-1024.png (pure-Python resampler, see README) whenever
  # the artwork changes.
  cp "assets/md-viewer-512.png" "$icons_dir/512x512/apps/$APP_NAME.png"
  cp "assets/md-viewer-256.png" "$icons_dir/256x256/apps/$APP_NAME.png"
  for size_label in 128x128 32x32 16x16; do
    if [ -f "assets/md-viewer-${size_label%x*}.png" ]; then
      cp "assets/md-viewer-${size_label%x*}.png" "$icons_dir/$size_label/apps/$APP_NAME.png"
    fi
  done

  # Startup document, loaded as an untitled tab at launch (see ui.rs
  # `startup_candidates`). Delete it to always start with a blank document.
  if [ -f "start-up.md" ]; then
    cp "start-up.md" "$app_data/start-up.md"
  fi

  # Desktop entry. StartupWMClass must match the Wayland app_id and the
  # X11 WM_CLASS ("md-viewer", set in main.rs and derived from the binary
  # name respectively).
  cat > "$apps_dir/$APP_NAME.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=$DISPLAY_NAME
GenericName=Markdown Editor
Comment=Markdown viewer and editor with live preview and PDF export
Exec=$bin_dir/$APP_NAME %f
TryExec=$bin_dir/$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=Development;TextEditor;Utility;
MimeType=text/markdown;text/x-markdown;
StartupWMClass=$APP_NAME
StartupNotify=true
X-KDE-StartupNotify=true
DESKTOP

  # Register the file-manager "Open With" association.
  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "$APP_NAME.desktop" text/markdown >/dev/null 2>&1 || true
    xdg-mime default "$APP_NAME.desktop" text/x-markdown >/dev/null 2>&1 || true
  fi
  command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$apps_dir" 2>/dev/null || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 \
    && gtk-update-icon-cache -f -t "$icons_dir" 2>/dev/null || true

  echo
  echo "Installed:"
  echo "  $bin_dir/$APP_NAME"
  echo "  $apps_dir/$APP_NAME.desktop"
  echo "  $icons_dir/*/apps/$APP_NAME.png"
  echo "Start it from the application menu ('MD-Viewer'), the file manager"
  echo "(open a .md file with MD-Viewer), or directly with:"
  echo "  $bin_dir/$APP_NAME"
}

package_app() {
  mkdir -p dist
  local name="md-viewer-$VERSION-x86_64.tar.gz"
  local archive="dist/$name"
  rm -f "$archive" "$archive.sha256"

  local stage
  stage="$(mktemp -d "/tmp/md-viewer-pkg-XXXXXX")"
  local root="$stage/md-viewer-$VERSION"
  mkdir -p "$root/bin" "$root/share/applications" \
    "$root/share/icons/hicolor/512x512/apps" \
    "$root/share/icons/hicolor/256x256/apps" \
    "$root/share/md-viewer"

  cp "target/release/$CRATE_NAME" "$root/bin/$APP_NAME"
  cp "assets/md-viewer-512.png" "$root/share/icons/hicolor/512x512/apps/$APP_NAME.png"
  cp "assets/md-viewer-256.png" "$root/share/icons/hicolor/256x256/apps/$APP_NAME.png"
  cp README.md LICENSE "$root/"
  [ -f "start-up.md" ] && cp "start-up.md" "$root/share/md-viewer/"

  # .desktop with a PATH-relative Exec (install.sh copies the binary into
  # ~/.local/bin, which is on PATH in default Ubuntu sessions).
  cat > "$root/share/applications/$APP_NAME.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=$DISPLAY_NAME
GenericName=Markdown Editor
Comment=Markdown viewer and editor with live preview and PDF export
Exec=$APP_NAME %f
TryExec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=Development;TextEditor;Utility;
MimeType=text/markdown;text/x-markdown;
StartupWMClass=$APP_NAME
StartupNotify=true
X-KDE-StartupNotify=true
DESKTOP

  cat > "$root/install.sh" <<INSTALLER
#!/usr/bin/env bash
# Installs the unpacked tree into ~/.local (user install, no sudo).
set -euo pipefail
cd "\$(dirname "\$0")"
prefix="\$HOME/.local"
data_dir="\${XDG_DATA_HOME:-\$prefix/share}"
mkdir -p "\$prefix/bin" "\$data_dir/applications" "\$data_dir/md-viewer"
for size in 512x512 256x256; do
  mkdir -p "\$data_dir/icons/hicolor/\$size/apps"
  cp "share/icons/hicolor/\$size/apps/$APP_NAME.png" "\$data_dir/icons/hicolor/\$size/apps/"
done
cp bin/$APP_NAME "\$prefix/bin/"
cp share/applications/$APP_NAME.desktop "\$data_dir/applications/"
[ -f "share/md-viewer/start-up.md" ] && cp "share/md-viewer/start-up.md" "\$data_dir/md-viewer/"
command -v xdg-mime >/dev/null 2>&1 \
  && xdg-mime default $APP_NAME.desktop text/markdown || true
command -v xdg-mime >/dev/null 2>&1 \
  && xdg-mime default $APP_NAME.desktop text/x-markdown || true
command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "\$data_dir/applications" || true
echo "Installed to \$prefix — start MD-Viewer from the application menu."
INSTALLER
  chmod +x "$root/install.sh"

  tar -czf "$archive" -C "$stage" "md-viewer-$VERSION"
  rm -rf "$stage"

  (cd dist && sha256sum "$name" > "$name.sha256")

  echo
  echo "Package: $archive"
  echo "SHA-256: $(cut -d' ' -f1 "$archive.sha256")"
}

if [ "$INSTALL" = "1" ]; then
  install_app
fi

if [ "$PACKAGE" = "1" ]; then
  package_app
fi

if [ "$INSTALL" = "0" ] && [ "$PACKAGE" = "0" ]; then
  echo
  echo "Done: target/release/$CRATE_NAME"
  echo "Install to ~/.local with:"
  echo "  ./build.sh --install"
  echo "Create a distributable archive with:"
  echo "  ./build.sh --package"
fi

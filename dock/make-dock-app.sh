#!/bin/zsh
# make-dock-app.sh — build "Claude Workspace.app" and optionally add it to the Dock.
#
# Clicking it runs `cc`, which reattaches live sessions or restores from the
# saved map after a reboot. It logs to ~/.claude/cc-dock.log so a failed
# launch can be diagnosed instead of failing silently.
#
#   ./make-dock-app.sh            build into /Applications
#   ./make-dock-app.sh --dock     build and add to the Dock
set -e

# /Applications is where people look for apps and what Spotlight ranks first.
# It is writable without sudo on a normal single-user Mac; if it is not, fall
# back to ~/Applications rather than failing.
if [[ -w /Applications ]]; then
  APPS="${APPS:-/Applications}"
else
  APPS="${APPS:-$HOME/Applications}"
  print "  /Applications not writable — installing to $APPS"
fi
APP="$APPS/Claude Workspace.app"
SRC="${0:A:h}"

command -v cc >/dev/null 2>&1 || {
  print -u2 "cc is not on your PATH — run ../install.sh first."
  exit 1
}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Claude Workspace</string>
  <key>CFBundleDisplayName</key><string>Claude Workspace</string>
  <key>CFBundleIdentifier</key><string>com.github.claude-sessions.workspace</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>launch</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict>
PLIST
print '</plist>' >> "$APP/Contents/Info.plist"

cat > "$APP/Contents/MacOS/launch" <<'LAUNCH'
#!/bin/zsh
# Dock launcher. Logs so a failure is diagnosable rather than silent.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
LOG="$HOME/.claude/cc-dock.log"
mkdir -p "$(dirname "$LOG")"
{
  print "=== $(date '+%F %T') Dock launch ==="
  cc 2>&1
  print "=== done ==="
} >> "$LOG" 2>&1
LAUNCH
chmod +x "$APP/Contents/MacOS/launch"

if [[ -f "$SRC/icon.png" ]]; then
  tmp="$(mktemp -d)/icon.iconset"; mkdir -p "$tmp"
  for s in 16 32 64 128 256 512; do
    sips -z $s $s "$SRC/icon.png" --out "$tmp/icon_${s}x${s}.png" >/dev/null 2>&1
    sips -z $((s*2)) $((s*2)) "$SRC/icon.png" --out "$tmp/icon_${s}x${s}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$tmp" -o "$APP/Contents/Resources/icon.icns" 2>/dev/null \
    && print "  icon installed"
fi

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" 2>/dev/null || true
print "built: $APP"

if [[ "$1" == "--dock" ]]; then
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://$APP/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
  killall Dock
  print "added to the Dock"
else
  print "to add it to the Dock: $0 --dock   (or drag it from $APPS)"
fi

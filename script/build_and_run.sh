#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/toolchain.sh"
cd "$TASKFIRE_ROOT"
MODE="${1:-run}"
APP_NAME=TaskFire
APP_BUNDLE="$TASKFIRE_ROOT/dist/TaskFire.app"
case "$MODE" in run|--build-only|--verify|--logs|--telemetry|--debug) ;; *) echo "Usage: $0 [--build-only|--verify|--logs|--telemetry|--debug]" >&2; exit 2 ;; esac
if [[ "$MODE" != --build-only ]]; then pkill -x TaskFire >/dev/null 2>&1 || true; fi
build_core
swiftc "${TASKFIRE_FLAGS[@]}" -parse-as-library -I "$TASKFIRE_BUILD" -L "$TASKFIRE_BUILD" -lTaskFireCore -Xlinker -rpath -Xlinker @executable_path/../Frameworks "$TASKFIRE_ROOT"/Sources/TaskFire/*.swift "$TASKFIRE_ROOT"/Sources/TaskFire/Views/*.swift "$TASKFIRE_ROOT"/Sources/TaskFire/Stores/*.swift "$TASKFIRE_ROOT"/Sources/TaskFire/Services/*.swift -o "$TASKFIRE_BUILD/TaskFire"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Frameworks" "$APP_BUNDLE/Contents/Resources"
cp "$TASKFIRE_BUILD/TaskFire" "$APP_BUNDLE/Contents/MacOS/TaskFire"
cp "$TASKFIRE_BUILD/libTaskFireCore.dylib" "$APP_BUNDLE/Contents/Frameworks/"
cp "$TASKFIRE_ROOT/assets/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>TaskFire</string>
<key>CFBundleIdentifier</key><string>com.taskfire.desktop</string>
<key>CFBundleName</key><string>TaskFire</string>
<key>CFBundleDisplayName</key><string>TaskFire</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_BUNDLE/Contents/Frameworks/libTaskFireCore.dylib"
codesign --force --sign - "$APP_BUNDLE"
case "$MODE" in
  --build-only) echo "Built: $APP_BUNDLE" ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/TaskFire" ;;
  --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "TaskFire"' ;;
  --telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.taskfire.desktop"' ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 2; pgrep -x TaskFire; echo 'TaskFire is running' ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac

#!/usr/bin/env bash
# Shared, project-local toolchain selection; does not change xcode-select.
TASKFIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKFIRE_SDK="${TASKFIRE_SDK:-}"
if [[ -z "$TASKFIRE_SDK" ]]; then
  if [[ -d /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ]]; then
    TASKFIRE_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
  else
    TASKFIRE_SDK="$(xcrun --sdk macosx --show-sdk-path)"
  fi
fi
TASKFIRE_ARCH="$(uname -m)"
TASKFIRE_BUILD="$TASKFIRE_ROOT/.build/manual"
mkdir -p "$TASKFIRE_BUILD/cache"
TASKFIRE_FLAGS=(-swift-version 6 -sdk "$TASKFIRE_SDK" -target "$TASKFIRE_ARCH-apple-macos14.0" -module-cache-path "$TASKFIRE_BUILD/cache")
build_core() {
  swiftc "${TASKFIRE_FLAGS[@]}" -parse-as-library -emit-library -emit-module -enable-testing -module-name TaskFireCore "$TASKFIRE_ROOT"/Sources/TaskFireCore/*.swift -emit-module-path "$TASKFIRE_BUILD/TaskFireCore.swiftmodule" -Xlinker -install_name -Xlinker @rpath/libTaskFireCore.dylib -o "$TASKFIRE_BUILD/libTaskFireCore.dylib"
}

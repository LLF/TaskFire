#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/toolchain.sh"
build_core
swiftc "${TASKFIRE_FLAGS[@]}" -I "$TASKFIRE_BUILD" -L "$TASKFIRE_BUILD" -lTaskFireCore -Xlinker -rpath -Xlinker "$TASKFIRE_BUILD" "$TASKFIRE_ROOT/Tests/CoreChecks/main.swift" -o "$TASKFIRE_BUILD/core-checks"
"$TASKFIRE_BUILD/core-checks"

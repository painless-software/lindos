#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_TYPE=${1:-debug}

case "$BUILD_TYPE" in
  debug|Debug)
    CARGO_CONFIG=""
    XCODE_CONFIG="Debug"
    ;;
  release|Release)
    CARGO_CONFIG="--release"
    XCODE_CONFIG="Release"
    ;;
  *)
    echo "Unknown build type: $BUILD_TYPE" >&2
    echo "Usage: $0 [debug|release]" >&2
    exit 1
    ;;
 esac

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo is required to build the Rust core" >&2
  exit 1
fi

# Build Rust core first so the static library exists for Xcode linking.
cargo build $CARGO_CONFIG --manifest-path "$REPO_ROOT/rust-core/Cargo.toml"

# Then build the macOS target. The Xcode project also runs cargo, but
# doing it here ensures developers see toolchain issues earlier.
xcodebuild \
  -project "$REPO_ROOT/macos/LindosTrayApp/LindosTrayApp.xcodeproj" \
  -scheme LindosTrayApp \
  -configuration "$XCODE_CONFIG"

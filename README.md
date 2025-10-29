# Lindos Tray App

Your friendly desktop assistent. A tray icon for tedious chores and lovely conversations.

## Quick Start

### Prerequisites

- macOS with Xcode (including the command-line tools) for the tray app build.
- Rust toolchain with `cargo` (install via [rustup](https://rustup.rs/)).

```bash
# build Rust + macOS app
scripts/build_macos.sh debug
```

Or open `macos/LindosTrayApp/LindosTrayApp.xcodeproj` and hit Run in Xcode.

## Run Rust Tests

```bash
# from the repo root
cd rust-core
cargo test
```

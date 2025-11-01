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

## Code Coverage

Generate test coverage reports locally using [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov):

```bash
# Install cargo-llvm-cov (one-time setup)
cargo install cargo-llvm-cov

# Generate coverage report in terminal
cd rust-core
cargo llvm-cov

# Generate HTML coverage report (opens in browser)
cargo llvm-cov --open

# Generate LCOV format for integration with other tools
cargo llvm-cov --lcov --output-path lcov.info
```

Coverage is automatically measured in CI and reported to Codecov on pull requests.

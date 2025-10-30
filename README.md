# Lindos Tray App

Your friendly desktop assistant. A tray icon for tedious chores and lovely conversations.

## Quick Start

This project uses [Just][just] for common development tasks. Install it first:

```bash
# macOS
brew install just

# Linux (Cargo)
cargo install just

# or with uv
uv tool install rust-just
```

Then see all available commands:

```bash
just
```

[just]: https://just.systems/man/en/

## Development

This code is hosted on GitHub. Code changes will trigger a GHA pipeline, which
runs linting, tests and code coverage.

### Prerequisites

- macOS with Xcode (including the command-line tools) for the tray app build
- Rust toolchain with `cargo` (install via [rustup](https://rustup.rs/))

### Build and Run

```bash
# Build Rust + macOS app
./scripts/build_macos.sh debug
```

Or open `macos/LindosTrayApp/LindosTrayApp.xcodeproj` and hit Run in Xcode.

## Development

For detailed development instructions, testing, and contributing guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

### Quick Links

- [Development Setup](CONTRIBUTING.md#development-setup)
- [Running Tests](CONTRIBUTING.md#running-tests)
- [Code Linting](CONTRIBUTING.md#code-quality-and-linting)
- [Submitting Changes](CONTRIBUTING.md#submitting-changes)

# Lindos Tray App

Your friendly desktop assistant. A tray icon for tedious chores and lovely conversations.

## Development

This project is hosted on GitHub. Code changes will trigger a GHA pipeline,
which runs linting, tests and code coverage.

### Quick Start

We use [Just][just] for common development tasks. Install it first:

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

### Prerequisites

- Just (see above for installation)
- Rust toolchain with `cargo` - _run `just setup-rust`_
- Python's `uv` for running just commands for GNOME - _run `just setup-python`_
- macOS: Xcode (including command-line tools) - _run `just setup-swift`_
- Linux: A distro with a modern GNOME desktop - _run `just setup-gnome`_

### Swift Tests - First Time Setup

If you're setting up Swift tests for the first time, you'll need to add the test target to Xcode.
See [macos/XCODE_TEST_SETUP.md](macos/XCODE_TEST_SETUP.md) for detailed instructions.

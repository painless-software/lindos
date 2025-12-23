# Lindos Development Tasks
# Run 'just' or 'just --list' to see all available commands
#
# Note: The GitHub Actions workflow (.github/workflows/rust-tests.yml) runs
# similar commands but does NOT use this justfile. This is intentional:
# - The workflow uses a matrix strategy for parallel execution across OS/checks
# - It leverages GHA-specific features (caching, codecov upload, conditional steps)
# - Keeping them separate maintains clarity and avoids unnecessary overhead
# - The justfile is optimized for local development convenience

# Show this usage screen (default)
@help:
    just --list

# ============================================================================
# Setup & Installation
# ============================================================================

# Install Rust toolchain and components (macOS and Linux)
[group('setup')]
setup-rust:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v cargo >/dev/null && command -v rustc >/dev/null; then
        echo "Rust already installed (cargo, rustc found) ✓"
    else
        if ! command -v rustup >/dev/null; then
            echo "Installing Rust via rustup..."
            # Note: Using official rustup installation method as documented at https://rustup.rs/
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        rustup toolchain install stable --profile minimal
    fi
    rustup default stable
    rustup component add clippy rustfmt llvm-tools-preview
    hash -r

# Install Swift development prerequisites (macOS only)
[group('setup')]
setup-swift:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "Error: This command is only for macOS" >&2
        exit 1
    fi
    if ! command -v xcodebuild >/dev/null 2>&1; then
        echo "Please install Xcode and command-line tools:"
        echo "  xcode-select --install"
        exit 1
    fi
    if ! command -v swiftlint >/dev/null 2>&1; then
        echo "Installing SwiftLint..."
        brew install swiftlint
    fi
    echo "Xcode tools are installed ✓"
    echo "SwiftLint is installed ✓"

# Setup GNOME development environment (NixOS only)
[group('setup')]
[working-directory: 'gnome']
setup-gnome:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v nix >/dev/null 2>&1; then
        echo "Error: Nix is not installed. This command is for NixOS only." >&2
        exit 1
    fi
    echo "Setting up GNOME development environment..."
    nix develop -c ${SHELL}

# Install Python development tools (uv)
[group('setup')]
setup-python:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v uv >/dev/null 2>&1; then
        echo "Installing uv..."
        # Note: Using official uv installation method as documented at https://astral.sh/uv
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    echo "uv is installed ✓"

# ============================================================================
# Rust - Build, Testing, Code Coverage, Quality Assurance
# ============================================================================

# Build the Rust project (use --release to strip debug symbols)
[group('rust')]
[working-directory: 'rust-core']
build *args:
    cargo build {{args}}

# Run Rust tests with optional arguments (use -v for verbose)
[group('rust')]
[working-directory: 'rust-core']
test *args:
    cargo test {{args}}

# Generate and display code coverage summary (requires cargo-llvm-cov)
[group('rust')]
[working-directory: 'rust-core']
coverage:
    cargo llvm-cov

# Generate and open HTML coverage report in browser
[group('rust')]
[working-directory: 'rust-core']
coverage-html:
    cargo llvm-cov --open

# Generate LCOV coverage report
[group('rust')]
[working-directory: 'rust-core']
coverage-lcov:
    cargo llvm-cov --lcov --output-path lcov.info

# Run clippy linter on Rust code
[group('rust')]
[working-directory: 'rust-core']
clippy:
    cargo clippy --all-targets --all-features -- -D warnings

# Check Rust code formatting
[group('rust')]
[working-directory: 'rust-core']
fmt-check:
    cargo fmt --check

# Format Rust code
[group('rust')]
[working-directory: 'rust-core']
fmt:
    cargo fmt

# ============================================================================
# Python/GNOME - Testing, Coverage, Quality Assurance
# ============================================================================

# Run pytest with optional arguments (use -v for verbose, -s to debug)
[group('gnome')]
[working-directory: 'gnome']
pytest *args:
    uvx --with tox-uv tox -- {{args}}

# Run ruff linter on Python code (use --fix to apply changes)
[group('gnome')]
[working-directory: 'gnome']
ruff-lint *args:
    uvx ruff check {{args}}

# Check Python code formatting (use --diff to show changes)
[group('gnome')]
[working-directory: 'gnome']
ruff-format *args:
    uvx ruff format --check {{args}}

# Apply Python code formatting changes with ruff
[group('gnome')]
[working-directory: 'gnome']
ruff-reformat:
    uvx ruff format

# Build Rust library and run the GNOME application
[group('gnome')]
[working-directory: 'gnome']
run-gnome: (build "--release")
    python -m lindos

# ============================================================================
# macOS - Build, Testing, Quality Assurance
# ============================================================================

# Build Rust library and macOS app with debug symbols
[group('macos')]
@build-macos: build xcodebuild

# Build Rust library and macOS app w/o debug symbols
[group('macos')]
@release-macos: (build "--release") (xcodebuild "Release")

# Build macOS app with Xcode (use 'Release' for release config)
[group('macos')]
xcodebuild config='Debug':
    xcodebuild \
      -project macos/LindosTrayApp/LindosTrayApp.xcodeproj \
      -scheme LindosTrayApp \
      -configuration {{config}}

# Run Swift tests with code coverage
[group('macos')]
test-swift:
    xcodebuild test \
      -project macos/LindosTrayApp/LindosTrayApp.xcodeproj \
      -scheme LindosTrayApp \
      -destination 'platform=macOS' \
      -derivedDataPath build/DerivedData \
      -enableCodeCoverage YES

# Check Swift code quality (use --strict for warnings, --fix to auto-fix)
[group('macos')]
swiftlint *args:
    swiftlint lint {{args}}

# ============================================================================
# All-in-One Commands
# ============================================================================

# Run all Rust checks (clippy, fmt-check, test)
[group('all')]
check-rust: clippy fmt-check test

# Run all Python checks (ruff check, format check, pytest)
[group('all')]
check-python: ruff-lint ruff-format pytest

# Run all Swift checks (swiftlint, test)
[group('all')]
check-swift: (swiftlint "--strict") test-swift

# Run all checks (Rust + Python + Swift)
[group('all')]
check-all: check-rust check-python check-swift

# ============================================================================
# Lifecycle & Utilities
# ============================================================================

# Clean build artifacts and reports (use -v for verbose, -n for dry-run)
[group('lifecycle')]
clean *args:
    cargo clean --manifest-path rust-core/Cargo.toml {{args}}
    -uvx pyclean gnome --debris all --erase '**/.venv/**' '**/.venv' --yes {{args}}
    git clean -i -x

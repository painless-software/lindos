# Contributing to Lindos Tray App

Thank you for your interest in contributing to Lindos! This document provides guidelines and instructions for developing and testing the project.

## Table of Contents

- [Development Setup](#development-setup)
- [Building the Project](#building-the-project)
- [Running Tests](#running-tests)
- [Code Quality and Linting](#code-quality-and-linting)
- [Project Structure](#project-structure)
- [Submitting Changes](#submitting-changes)

## Development Setup

### Prerequisites

#### For macOS Development
- macOS with Xcode (including command-line tools)
- Rust toolchain with `cargo` ([install via rustup](https://rustup.rs/))

#### For Rust Core Development
- Rust toolchain with `cargo` ([install via rustup](https://rustup.rs/))

### Installing Dependencies

1. **Install Rust:**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Install Xcode Command Line Tools:**
   ```bash
   xcode-select --install
   ```

3. **Install SwiftLint (optional but recommended):**
   ```bash
   brew install swiftlint
   ```

## Building the Project

### Quick Build

Use the provided build script to build both the Rust core and macOS app:

```bash
# Debug build
./scripts/build_macos.sh debug

# Release build
./scripts/build_macos.sh release
```

### Manual Build Process

#### 1. Build Rust Core

```bash
cd rust-core
cargo build          # Debug build
cargo build --release # Release build
```

#### 2. Build macOS App

**Option A: Using Xcode**
1. Open `macos/LindosTrayApp/LindosTrayApp.xcodeproj` in Xcode
2. Select the LindosTrayApp scheme
3. Press ⌘R to build and run, or ⌘B to build only

**Option B: Using xcodebuild**
```bash
xcodebuild \
  -project macos/LindosTrayApp/LindosTrayApp.xcodeproj \
  -scheme LindosTrayApp \
  -configuration Debug
```

## Running Tests

### Rust Tests

Run Rust core tests from the repository root:

```bash
cd rust-core
cargo test
```

For verbose output:
```bash
cargo test -- --nocapture
```

### Swift Tests

#### Setting Up Tests in Xcode

If you're setting up the project for the first time, you'll need to add the test target to Xcode. See [macos/XCODE_TEST_SETUP.md](macos/XCODE_TEST_SETUP.md) for detailed instructions.

#### Option A: Using Xcode

1. Open `macos/LindosTrayApp/LindosTrayApp.xcodeproj` in Xcode
2. Press ⌘U to run all tests
3. Or use the Test Navigator (⌘6) to run specific tests

#### Option B: Using xcodebuild

Run all tests:
```bash
xcodebuild test \
  -project macos/LindosTrayApp/LindosTrayApp.xcodeproj \
  -scheme LindosTrayApp \
  -destination 'platform=macOS'
```

Run with code coverage:
```bash
xcodebuild test \
  -project macos/LindosTrayApp/LindosTrayApp.xcodeproj \
  -scheme LindosTrayApp \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

### Test Structure

Swift tests are located in:
- `macos/Tests/LindosTrayAppTests/`

Test files include:
- `RustCoreTests.swift` - Tests for the Rust FFI wrapper
- `ChatViewModelTests.swift` - Tests for the chat view model logic
- `TrayChatViewTests.swift` - Tests for the SwiftUI view
- `AppDelegateTests.swift` - Tests for the app delegate

## Code Quality and Linting

### Swift Linting with SwiftLint

SwiftLint is configured via `.swiftlint.yml` in the repository root.

#### Run SwiftLint

```bash
# Lint all Swift files
swiftlint lint

# Lint with strict mode (warnings treated as errors)
swiftlint lint --strict

# Auto-fix issues where possible
swiftlint --fix
```

#### SwiftLint in Xcode

SwiftLint automatically runs as part of the Xcode build process if installed. You'll see warnings and errors in the Xcode issue navigator.

#### Pre-commit Hook (Optional)

You can add a Git pre-commit hook to automatically lint before commits:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if which swiftlint >/dev/null; then
  swiftlint lint --strict
  if [ $? -ne 0 ]; then
    echo "SwiftLint failed. Please fix the issues before committing."
    exit 1
  fi
fi
EOF
chmod +x .git/hooks/pre-commit
```

### Rust Linting

```bash
cd rust-core

# Check formatting
cargo fmt -- --check

# Run clippy for linting
cargo clippy -- -D warnings
```

## Project Structure

```
lindos/
├── .github/
│   └── workflows/        # GitHub Actions CI/CD workflows
├── macos/
│   ├── LindosTrayApp/
│   │   ├── LindosTrayApp/       # Swift source code
│   │   │   ├── AppDelegate.swift
│   │   │   ├── ChatViewModel.swift
│   │   │   ├── RustCore.swift
│   │   │   ├── TrayChatView.swift
│   │   │   └── LindosTrayAppMain.swift
│   │   └── LindosTrayApp.xcodeproj/
│   └── Tests/
│       └── LindosTrayAppTests/  # Swift unit tests
├── rust-core/            # Rust FFI library
│   ├── src/
│   ├── include/          # C header files for FFI
│   └── Cargo.toml
├── scripts/
│   └── build_macos.sh    # Build automation script
├── .swiftlint.yml        # SwiftLint configuration
├── CONTRIBUTING.md       # This file
└── README.md             # Project overview
```

## Submitting Changes

### Before Submitting

1. **Run all tests:**
   ```bash
   cd rust-core && cargo test
   ```
   
2. **Lint your code:**
   ```bash
   swiftlint lint --strict
   cd rust-core && cargo clippy -- -D warnings
   ```

3. **Format your code:**
   ```bash
   cd rust-core && cargo fmt
   ```

4. **Verify the build:**
   ```bash
   ./scripts/build_macos.sh debug
   ```

### Pull Request Guidelines

1. Create a feature branch from `main`
2. Make your changes with clear, descriptive commit messages
3. Ensure all tests pass
4. Ensure code passes linting
5. Update documentation if needed
6. Submit a pull request with a clear description of changes

### Commit Message Format

Follow conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(chat): add message validation before sending

- Validate message length and content
- Show user-friendly error messages
- Add unit tests for validation logic
```

## Getting Help

If you encounter issues or have questions:

1. Check existing [GitHub Issues](https://github.com/painless-software/lindos/issues)
2. Create a new issue with detailed information about your problem
3. Include your environment details (macOS version, Xcode version, etc.)

## Code of Conduct

Please be respectful and constructive in all interactions. We're building a welcoming community!

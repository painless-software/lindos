# Adding Tests to Xcode Project

The Swift test files are located in `macos/Tests/LindosTrayAppTests/`. To integrate them into the Xcode project, follow these steps:

## Option 1: Using Xcode GUI (Recommended)

1. Open `macos/LindosTrayApp/LindosTrayApp.xcodeproj` in Xcode

2. Create a new test target:
   - File → New → Target
   - Select "macOS" → "Unit Testing Bundle"
   - Product Name: `LindosTrayAppTests`
   - Team: (select your team)
   - Click Finish

3. Delete the automatically created test file that Xcode generates

4. Add existing test files:
   - Right-click on the project navigator
   - Select "Add Files to LindosTrayApp..."
   - Navigate to `macos/Tests/LindosTrayAppTests/`
   - Select all `.swift` files
   - Ensure "LindosTrayAppTests" target is checked
   - Click Add

5. Configure test target dependencies:
   - Select the project in the navigator
   - Select the `LindosTrayAppTests` target
   - Go to "Build Phases"
   - Expand "Dependencies"
   - Click "+" and add "LindosTrayApp" as a dependency

6. Configure test target to access app code:
   - Select the `LindosTrayApp` target
   - Go to "Build Settings"
   - Search for "Defines Module"
   - Set "Defines Module" to "Yes"

7. Build and run tests (⌘U)

## Option 2: Manual .pbxproj Editing (Advanced)

If you're comfortable editing the project file directly, you can add the test target by modifying `macos/LindosTrayApp/LindosTrayApp.xcodeproj/project.pbxproj`. However, this is error-prone and not recommended unless you're very familiar with the Xcode project format.

## Verifying the Setup

After adding the tests, verify by:

1. Opening the Test Navigator (⌘6)
2. You should see all test classes and methods
3. Run tests with ⌘U
4. All tests should execute (some may fail initially if Rust core isn't built)

## Troubleshooting

**Issue: Tests can't find LindosTrayApp module**
- Solution: Make sure "Defines Module" is set to "Yes" in LindosTrayApp target build settings
- Solution: Import using `@testable import LindosTrayApp` in test files

**Issue: Tests fail with Rust FFI errors**
- Solution: Build the Rust core first: `cd rust-core && cargo build`
- Solution: Ensure the Rust library is properly linked in Xcode build settings

**Issue: Test target not appearing in scheme**
- Solution: Product → Scheme → Manage Schemes → Check "Show" for LindosTrayAppTests

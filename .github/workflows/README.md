# GitHub Actions Workflows

## Swift Tests Workflow

The `swift-tests.yml` workflow runs Swift tests, linting, and builds for the macOS app.

### Important Setup Note

**The Swift test workflow will initially fail** because the test target needs to be manually added to the Xcode project. 

To enable the workflow:

1. Follow the instructions in [macos/XCODE_TEST_SETUP.md](../../macos/XCODE_TEST_SETUP.md) to add the test target to Xcode
2. Commit the updated `.xcodeproj` file
3. The workflow will then run successfully on subsequent pushes

### Workflow Components

The workflow includes three jobs:

1. **lint**: Runs SwiftLint to check code quality
2. **test**: Runs the Swift unit tests
3. **build**: Verifies the app builds successfully

### Manual Workflow Trigger

You can manually trigger the workflow from the GitHub Actions tab:
1. Go to the "Actions" tab in the repository
2. Select "Swift Tests" workflow
3. Click "Run workflow"

### Troubleshooting

- **Test job fails with "scheme not found"**: The test target hasn't been added to Xcode yet
- **Lint job fails**: Fix SwiftLint warnings in the Swift code
- **Build job fails**: Check Rust core builds successfully first

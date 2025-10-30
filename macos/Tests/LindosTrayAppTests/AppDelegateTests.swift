import XCTest
import Cocoa
@testable import LindosTrayApp

/// Tests for AppDelegate initialization and configuration
final class AppDelegateTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    
    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()
    }
    
    override func tearDown() {
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAppDelegateInitialization() {
        XCTAssertNotNil(appDelegate, "AppDelegate should initialize")
    }
    
    // MARK: - Configuration Tests
    
    func testApplicationDidFinishLaunching() {
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        
        // This will configure the status item and popover
        appDelegate.applicationDidFinishLaunching(notification)
        
        // Verify that the app delegate completes configuration without crashing
        // Detailed assertions would require access to private properties or
        // refactoring to make them testable
        XCTAssertTrue(true, "Configuration should complete without errors")
    }
    
    // Note: Testing UI components like NSStatusItem and NSPopover require
    // a running application context. These tests verify basic initialization.
    // More comprehensive tests would be done through UI testing or by
    // refactoring to inject dependencies.
}

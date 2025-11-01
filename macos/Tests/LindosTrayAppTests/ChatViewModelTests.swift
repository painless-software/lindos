import XCTest
import Combine
@testable import LindosTrayApp

/// Tests for ChatViewModel logic and state management
final class ChatViewModelTests: XCTestCase {
    private var viewModel = ChatViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        viewModel = ChatViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.currentMessage, "", "Initial message should be empty")
        XCTAssertEqual(viewModel.reply, "Ask anything…", "Initial reply should be the prompt")
        XCTAssertFalse(viewModel.isThinking, "Should not be thinking initially")
        XCTAssertFalse(viewModel.hasError, "Should not have error initially")
        XCTAssertEqual(viewModel.errorMessage, "", "Error message should be empty initially")
    }

    // MARK: - Message Validation Tests

    func testIsCurrentMessageValidWithEmptyMessage() {
        viewModel.currentMessage = ""
        XCTAssertTrue(viewModel.isCurrentMessageValid, "Empty message should be considered valid (neutral)")
    }

    func testIsCurrentMessageValidWithValidMessage() {
        viewModel.currentMessage = "Hello, world!"
        XCTAssertTrue(viewModel.isCurrentMessageValid, "Valid message should be valid")
    }

    func testIsCurrentMessageValidWithWhitespace() {
        viewModel.currentMessage = "   "
        XCTAssertTrue(viewModel.isCurrentMessageValid, "Whitespace should be valid (trimmed to empty)")
    }

    // MARK: - Character Count Tests

    func testCharacterCount() {
        viewModel.currentMessage = ""
        XCTAssertEqual(viewModel.characterCount, 0)

        viewModel.currentMessage = "Hello"
        XCTAssertEqual(viewModel.characterCount, 5)

        viewModel.currentMessage = "Hello, world! 👋"
        XCTAssertTrue(viewModel.characterCount > 0)
    }

    // MARK: - Can Send Tests

    func testCanSendWithEmptyMessage() {
        viewModel.currentMessage = ""
        XCTAssertFalse(viewModel.canSend, "Should not be able to send empty message")
    }

    func testCanSendWithValidMessage() {
        viewModel.currentMessage = "Hello"
        XCTAssertTrue(viewModel.canSend, "Should be able to send valid message")
    }

    func testCanSendWhileThinking() {
        viewModel.currentMessage = "Hello"
        viewModel.isThinking = true
        XCTAssertFalse(viewModel.canSend, "Should not be able to send while thinking")
    }

    func testCanSendWithWhitespaceOnly() {
        viewModel.currentMessage = "   "
        XCTAssertFalse(viewModel.canSend, "Should not be able to send whitespace-only message")
    }

    // MARK: - Clear Message Tests

    func testClearMessage() {
        viewModel.currentMessage = "Test message"
        viewModel.clearMessage()

        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared")
    }

    func testClearMessageClearsError() {
        viewModel.currentMessage = "Test"
        viewModel.hasError = true
        viewModel.errorMessage = "Test error"

        viewModel.clearMessage()

        XCTAssertFalse(viewModel.hasError, "Error should be cleared")
        XCTAssertEqual(viewModel.errorMessage, "", "Error message should be cleared")
    }

    // MARK: - Reset Tests

    func testReset() {
        viewModel.currentMessage = "Test message"
        viewModel.reply = "Some reply"
        viewModel.hasError = true
        viewModel.errorMessage = "Test error"

        viewModel.reset()

        XCTAssertEqual(viewModel.currentMessage, "", "Message should be reset")
        XCTAssertEqual(viewModel.reply, "Ask anything…", "Reply should be reset")
        XCTAssertFalse(viewModel.hasError, "Error should be cleared")
        XCTAssertEqual(viewModel.errorMessage, "", "Error message should be cleared")
    }

    // MARK: - Error Handling Tests

    func testHandleNullPointerError() {
        viewModel.handleError(.nullPointer)

        XCTAssertTrue(viewModel.hasError, "Should have error")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Should have error message")
        XCTAssertTrue(viewModel.errorMessage.contains("message") || viewModel.errorMessage.contains("enter"),
                     "Error message should be user-friendly")
    }

    func testHandleInvalidUtf8Error() {
        viewModel.handleError(.invalidUtf8)

        XCTAssertTrue(viewModel.hasError, "Should have error")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Should have error message")
    }

    func testHandleEmptyMessageError() {
        viewModel.handleError(.emptyMessage)

        XCTAssertTrue(viewModel.hasError, "Should have error")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Should have error message")
    }

    func testHandleProcessingFailureError() {
        viewModel.handleError(.processingFailure)

        XCTAssertTrue(viewModel.hasError, "Should have error")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Should have error message")
    }

    func testHandleUnknownError() {
        viewModel.handleError(.unknown(42))

        XCTAssertTrue(viewModel.hasError, "Should have error")
        XCTAssertTrue(viewModel.errorMessage.contains("42"), "Error message should contain error code")
    }

    // MARK: - Send Message Tests

    func testSendEmptyMessage() {
        let expectation = expectation(description: "Send completes")

        viewModel.$reply
            .dropFirst() // Skip initial value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.send()

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared after send")
    }

    func testSendValidMessage() async {
        viewModel.currentMessage = "Hello"

        // Create expectation for isThinking changes
        let thinkingExpectation = expectation(description: "Thinking state changes")
        thinkingExpectation.expectedFulfillmentCount = 2 // Will be set to true then false

        viewModel.$isThinking
            .dropFirst() // Skip initial value
            .sink { _ in
                thinkingExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.send()

        await fulfillment(of: [thinkingExpectation], timeout: 5.0)

        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared after send")
        XCTAssertFalse(viewModel.isThinking, "Should not be thinking after completion")
    }

    func testSendWhitespaceMessage() {
        viewModel.currentMessage = "   "
        let expectation = expectation(description: "Send completes")

        viewModel.$reply
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.send()

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared")
    }

    // MARK: - Sync Send Tests

    func testSendSyncEmptyMessage() {
        let expectation = expectation(description: "Sync send completes")

        viewModel.$isThinking
            .dropFirst()
            .filter { !$0 } // Wait for isThinking to become false
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.sendSync()

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared")
        XCTAssertFalse(viewModel.isThinking, "Should not be thinking after completion")
    }

    func testSendSyncValidMessage() {
        viewModel.currentMessage = "Test message"
        let expectation = expectation(description: "Sync send completes")

        viewModel.$isThinking
            .dropFirst()
            .filter { !$0 } // Wait for isThinking to become false
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.sendSync()

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(viewModel.currentMessage, "", "Message should be cleared")
        XCTAssertFalse(viewModel.isThinking, "Should not be thinking after completion")
    }

    // MARK: - Error Auto-Hide Tests

    func testErrorAutoHides() {
        let expectation = expectation(description: "Error auto-hides")

        viewModel.handleError(.emptyMessage)
        XCTAssertTrue(viewModel.hasError, "Error should be present initially")

        // Wait for auto-hide (5 seconds + margin)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            XCTAssertFalse(self.viewModel.hasError, "Error should auto-hide")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 6.0)
    }
}

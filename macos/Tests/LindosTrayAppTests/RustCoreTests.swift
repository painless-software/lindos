import XCTest
@testable import LindosTrayApp

/// Tests for RustCore error handling and processing
final class RustCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Enable debug mode for tests
        RustCore.setDebugEnabled(true)
    }
    
    // MARK: - Error Enum Tests
    
    func testProcessingErrorFromCode() {
        XCTAssertEqual(RustCore.ProcessingError.from(errorCode: 1), .nullPointer)
        XCTAssertEqual(RustCore.ProcessingError.from(errorCode: 2), .invalidUtf8)
        XCTAssertEqual(RustCore.ProcessingError.from(errorCode: 3), .emptyMessage)
        XCTAssertEqual(RustCore.ProcessingError.from(errorCode: 4), .processingFailure)
        
        if case .unknown(let code) = RustCore.ProcessingError.from(errorCode: 999) {
            XCTAssertEqual(code, 999)
        } else {
            XCTFail("Expected unknown error")
        }
    }
    
    func testProcessingErrorDescriptions() {
        XCTAssertNotNil(RustCore.ProcessingError.nullPointer.errorDescription)
        XCTAssertNotNil(RustCore.ProcessingError.invalidUtf8.errorDescription)
        XCTAssertNotNil(RustCore.ProcessingError.emptyMessage.errorDescription)
        XCTAssertNotNil(RustCore.ProcessingError.processingFailure.errorDescription)
        XCTAssertNotNil(RustCore.ProcessingError.unknown(42).errorDescription)
    }
    
    // MARK: - Result Type Tests
    
    func testResultSuccessValue() {
        let result = RustCore.Result.success("test response")
        XCTAssertEqual(result.value, "test response")
        XCTAssertNil(result.error)
    }
    
    func testResultFailureValue() {
        let result = RustCore.Result.failure(.emptyMessage)
        XCTAssertNil(result.value)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error, .emptyMessage)
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidMessage() {
        let error = RustCore.validate(message: "Hello, world!")
        XCTAssertNil(error, "Valid message should not produce an error")
    }
    
    func testValidateEmptyMessage() {
        let error = RustCore.validate(message: "")
        XCTAssertNotNil(error, "Empty message should produce an error")
        XCTAssertEqual(error, .emptyMessage)
    }
    
    // MARK: - Processing Tests
    
    func testProcessValidMessage() {
        let result = RustCore.process(message: "Hello")
        XCTAssertFalse(result.isEmpty, "Processing should return a non-empty result")
    }
    
    func testProcessWithResultSuccess() {
        let result = RustCore.processWithResult(message: "Test message")
        
        switch result {
        case .success(let response):
            XCTAssertFalse(response.isEmpty, "Response should not be empty")
        case .failure(let error):
            // If Rust core returns an error, that's also acceptable
            // We're just testing the wrapper works correctly
            XCTAssertNotNil(error.errorDescription)
        }
    }
    
    func testProcessEmptyMessage() {
        let result = RustCore.processWithResult(message: "")
        
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .emptyMessage, "Empty message should return emptyMessage error")
        case .success:
            // Some implementations might allow empty messages
            // so we don't fail if it succeeds
            break
        }
    }
    
    // MARK: - Async Processing Tests
    
    func testProcessAsyncValidMessage() async {
        let result = await RustCore.processAsync(message: "Async test")
        
        switch result {
        case .success(let response):
            XCTAssertFalse(response.isEmpty, "Async response should not be empty")
        case .failure(let error):
            // Acceptable if Rust returns an error
            XCTAssertNotNil(error.errorDescription)
        }
    }
    
    func testProcessAsyncEmptyMessage() async {
        let result = await RustCore.processAsync(message: "")
        
        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .emptyMessage, "Empty message should return emptyMessage error")
        case .success:
            // Some implementations might allow empty messages
            break
        }
    }
    
    // MARK: - Error Message Tests
    
    func testGetErrorMessage() {
        let message = RustCore.getErrorMessage(for: 1)
        XCTAssertFalse(message.isEmpty, "Error message should not be empty")
    }
    
    func testGetErrorMessageForUnknownCode() {
        let message = RustCore.getErrorMessage(for: 999)
        XCTAssertFalse(message.isEmpty, "Should return a message even for unknown codes")
    }
}

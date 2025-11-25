import Foundation
import os.log

/// Swift wrapper for Rust core functionality with enhanced error handling
enum RustCore {

    /// Errors that can occur during Rust processing
    enum ProcessingError: Error, LocalizedError, Equatable {
        case nullPointer
        case invalidUtf8
        case emptyMessage
        case processingFailure
        case unknown(Int32)

        var errorDescription: String? {
            switch self {
            case .nullPointer:
                return "No message provided"
            case .invalidUtf8:
                return "Message contains invalid characters"
            case .emptyMessage:
                return "Message cannot be empty"
            case .processingFailure:
                return "Failed to process message"
            case .unknown(let code):
                return "Unknown error (code: \(code))"
            }
        }

        static func from(errorCode: Int32) -> ProcessingError {
            switch errorCode {
            case 1: return .nullPointer
            case 2: return .invalidUtf8
            case 3: return .emptyMessage
            case 4: return .processingFailure
            default: return .unknown(errorCode)
            }
        }
    }

    /// Result type for operations that can fail
    enum Result {
        case success(String)
        case failure(ProcessingError)

        var value: String? {
            switch self {
            case .success(let string): string
            case .failure: nil
            }
        }

        var error: ProcessingError? {
            switch self {
            case .success: nil
            case .failure(let error): error
            }
        }
    }

    /// Logger for debug information
    private static let logger = Logger(subsystem: "com.example.lindos", category: "RustCore")

    /// Enable or disable debug logging in Rust
    static func setDebugEnabled(_ enabled: Bool) {
        lindos_set_debug(enabled)
    }

    /// Validate a message without processing it
    static func validate(message: String) -> ProcessingError? {
        // Short-circuit empty/whitespace input to avoid calling into Rust for a known condition
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyMessage
        }

        guard let cString = message.cString(using: .utf8) else {
            return .invalidUtf8
        }

        let errorCode = lindos_validate_message(cString)
        return errorCode == 0 ? nil : ProcessingError.from(errorCode: errorCode)
    }

    /// Process a message using the legacy interface (backwards compatible)
    static func process(message: String) -> String {
        switch processWithResult(message: message) {
        case .success(let result):
            return result
        case .failure(let error):
            logger.error("Processing failed: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }

    /// Process a message with full error handling
    static func processWithResult(message: String) -> Result {
        logger.debug("Processing message: \(message.count) characters")

        guard let cString = message.cString(using: .utf8) else {
            logger.error("Failed to convert message to UTF-8")
            return .failure(.invalidUtf8)
        }

        let rustResult = lindos_process_message_safe(cString)
        defer { lindos_result_free(rustResult) }

        if rustResult.success {
            guard let dataPointer = rustResult.data else {
                logger.error("Rust returned success but null data pointer")
                return .failure(.unknown(-1))
            }

            let resultString = String(cString: dataPointer)
            logger.debug("Successfully processed message, result: \(resultString.count) characters")
            return .success(resultString)
        } else {
            let error = ProcessingError.from(errorCode: rustResult.error_code)
            logger.error("Rust processing failed with error code: \(rustResult.error_code)")

            // Get the error message from Rust if available
            if let dataPointer = rustResult.data {
                let errorMessage = String(cString: dataPointer)
                logger.error("Rust error message: \(errorMessage)")
            }

            return .failure(error)
        }
    }

    /// Async version of process for better UI responsiveness
    static func processAsync(message: String) async -> Result {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = processWithResult(message: message)
                continuation.resume(returning: result)
            }
        }
    }

    /// Get a human-readable error message for an error code
    static func getErrorMessage(for errorCode: Int32) -> String {
        let messagePointer = lindos_error_message(errorCode)
        defer { lindos_string_free(messagePointer) }

        guard let pointer = messagePointer else {
            return "Unknown error"
        }

        return String(cString: pointer)
    }
}

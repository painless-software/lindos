import Combine
import Foundation
import os.log

final class ChatViewModel: ObservableObject {
    @Published var currentMessage: String = ""
    @Published var reply: String = "Ask anything…"
    @Published var isThinking: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""

    private let logger = Logger(subsystem: "com.example.lindos", category: "ChatViewModel")
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Enable debug logging in development builds
        #if DEBUG
        RustCore.setDebugEnabled(true)
        #endif

        setupMessageValidation()
    }

    /// Set up real-time message validation as user types
    private func setupMessageValidation() {
        $currentMessage
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] message in
                self?.validateCurrentMessage(message)
            }
            .store(in: &cancellables)
    }

    /// Validate the current message and show warnings if needed
    private func validateCurrentMessage(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearError()
            return
        }

        if let error = RustCore.validate(message: message) {
            showError(error.localizedDescription)
        } else {
            clearError()
        }
    }

    /// Send the current message for processing
    func send() {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        currentMessage = ""
        clearError()

        logger.info("Sending message: \(message.count) characters")

        // Handle empty message case
        guard !message.isEmpty else {
            reply = RustCore.process(message: "")
            return
        }

        // Pre-validate message before processing
        if let validationError = RustCore.validate(message: message) {
            showError("Invalid message: \(validationError.localizedDescription)")
            return
        }

        isThinking = true

        Task {
            let result = await RustCore.processAsync(message: message)

            await MainActor.run {
                self.isThinking = false

                switch result {
                case .success(let response):
                    self.reply = response
                    self.logger.info("Successfully processed message")

                case .failure(let error):
                    self.logger.error("Failed to process message: \(error.localizedDescription)")
                    self.showError("Processing failed: \(error.localizedDescription)")
                    self.reply = "Sorry, I encountered an error while processing your message."
                }
            }
        }
    }

    /// Send a message using the synchronous API (fallback)
    func sendSync() {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        currentMessage = ""
        clearError()

        guard !message.isEmpty else {
            reply = RustCore.process(message: "")
            return
        }

        isThinking = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let result = RustCore.processWithResult(message: message)

            DispatchQueue.main.async {
                self.isThinking = false

                switch result {
                case .success(let response):
                    self.reply = response

                case .failure(let error):
                    self.showError("Error: \(error.localizedDescription)")
                    self.reply = "Sorry, I encountered an error while processing your message."
                }
            }
        }
    }

    /// Clear the current message
    func clearMessage() {
        currentMessage = ""
        clearError()
    }

    /// Reset the conversation
    func reset() {
        currentMessage = ""
        reply = "Ask anything…"
        clearError()
        logger.info("Conversation reset")
    }

    /// Show an error message to the user
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true

        // Auto-hide error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.clearError()
        }
    }

    /// Clear any current error state
    private func clearError() {
        hasError = false
        errorMessage = ""
    }

    /// Get current validation status
    var isCurrentMessageValid: Bool {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return true }

        return RustCore.validate(message: message) == nil
    }

    /// Get current message character count
    var characterCount: Int {
        return currentMessage.count
    }

    /// Check if we can send the current message
    var canSend: Bool {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return !message.isEmpty && isCurrentMessageValid && !isThinking
    }
}

// MARK: - Error handling extensions
extension ChatViewModel {
    /// Handle specific error types with appropriate user feedback
    func handleError(_ error: RustCore.ProcessingError) {
        let userFriendlyMessage: String

        switch error {
        case .nullPointer:
            userFriendlyMessage = "Please enter a message"
        case .invalidUtf8:
            userFriendlyMessage = "Your message contains unsupported characters"
        case .emptyMessage:
            userFriendlyMessage = "Message cannot be empty"
        case .processingFailure:
            userFriendlyMessage = "Unable to process your message right now"
        case .unknown(let code):
            userFriendlyMessage = "An unexpected error occurred (code: \(code))"
        }

        showError(userFriendlyMessage)
    }
}

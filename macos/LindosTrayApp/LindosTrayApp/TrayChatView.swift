import SwiftUI

struct TrayChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var inputFocused: Bool

    init(viewModel: ChatViewModel = ChatViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header section with title and status
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Lindos")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Status indicator
                    if viewModel.isThinking {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6) 
                            Text("Thinking")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.hasError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                // Response text
                Text(viewModel.isThinking ? "Thinking…" : viewModel.reply)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Error message display
            if viewModel.hasError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)

                    Text(viewModel.errorMessage)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.red.opacity(0.1))
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }

            // Input section
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Text field with validation styling
                    TextField("Ask something thoughtful", text: $viewModel.currentMessage, onCommit: submit)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(inputBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(inputBorderColor, lineWidth: 1)
                                )
                        )
                        .focused($inputFocused)

                    // Send button
                    Button(action: submit) {
                        Image(systemName: sendButtonIcon)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(sendButtonForegroundColor)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(sendButtonBackgroundColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canSend)
                    .opacity(viewModel.canSend ? 1.0 : 0.6)
                }

                // Character count and validation status
                HStack {
                    if viewModel.characterCount > 0 {
                        Text("\(viewModel.characterCount) characters")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !viewModel.isCurrentMessageValid && viewModel.characterCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Message too long")
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.characterCount)
            }

            // Action buttons
            HStack(spacing: 8) {
                // Clear button
                Button("Clear") {
                    viewModel.clearMessage()
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .disabled(viewModel.currentMessage.isEmpty)

                Spacer()

                // Reset button
                Button("Reset") {
                    viewModel.reset()
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .padding(20)
        .frame(width: 340)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                inputFocused = true
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasError)
    }

    // MARK: - Computed Properties

    private var sendButtonIcon: String {
        if viewModel.isThinking {
            return "ellipsis"
        } else if !viewModel.isCurrentMessageValid {
            return "exclamationmark.triangle"
        } else {
            return "paperplane.fill"
        }
    }

    private var sendButtonForegroundColor: Color {
        if viewModel.canSend {
            return .accentColor
        } else if !viewModel.isCurrentMessageValid && viewModel.characterCount > 0 {
            return .orange
        } else {
            return .secondary
        }
    }

    private var sendButtonBackgroundColor: Color {
        if viewModel.canSend {
            return Color(nsColor: .controlAccentColor).opacity(0.15)
        } else if !viewModel.isCurrentMessageValid && viewModel.characterCount > 0 {
            return .orange.opacity(0.15)
        } else {
            return Color(nsColor: .controlAccentColor).opacity(0.05)
        }
    }

    private var inputBackgroundColor: Color {
        if viewModel.hasError {
            return .red.opacity(0.05)
        } else if !viewModel.isCurrentMessageValid && viewModel.characterCount > 0 {
            return .orange.opacity(0.05)
        } else {
            return Color(nsColor: .controlAccentColor).opacity(0.08)
        }
    }

    private var inputBorderColor: Color {
        if viewModel.hasError {
            return .red.opacity(0.3)
        } else if !viewModel.isCurrentMessageValid && viewModel.characterCount > 0 {
            return .orange.opacity(0.3)
        } else {
            return .clear
        }
    }

    // MARK: - Actions

    private func submit() {
        guard viewModel.canSend else { return }

        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )

        viewModel.send()

        DispatchQueue.main.async {
            inputFocused = true
        }
    }
}

// MARK: - Previews

struct TrayChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            TrayChatView()
                .previewDisplayName("Normal")

            // With error state
            TrayChatView()
                .onAppear {
                    // This would be set up differently in a real preview
                }
                .previewDisplayName("With Error")
        }
        .frame(width: 340)
    }
}

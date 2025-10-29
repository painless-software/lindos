import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let chatViewModel = ChatViewModel()
    private lazy var statusIcon: NSImage = {
        if #available(macOS 11.0, *) {
            let configuration = NSImage.SymbolConfiguration(scale: .medium)
            if let symbol = NSImage(systemSymbolName: "bubble.left.and.bubble.right.fill",
                                    accessibilityDescription: "Lindos")?
                .withSymbolConfiguration(configuration) {
                symbol.isTemplate = true
                return symbol
            }
        }

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.size = size
        image.lockFocus()
        let bubbleRect = NSRect(x: 1, y: 3, width: 16, height: 12)
        let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: 5, yRadius: 5)
        NSColor.labelColor.setStroke()
        bubblePath.lineWidth = 1.6
        bubblePath.stroke()

        let tailPath = NSBezierPath()
        tailPath.move(to: NSPoint(x: bubbleRect.midX, y: bubbleRect.minY - 1))
        tailPath.line(to: NSPoint(x: bubbleRect.midX + 4, y: bubbleRect.minY - 5))
        tailPath.line(to: NSPoint(x: bubbleRect.midX + 1, y: bubbleRect.minY - 1))
        tailPath.close()
        NSColor.labelColor.setStroke()
        tailPath.lineWidth = 1.6
        tailPath.stroke()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }()
    private let popover = NSPopover()
    private lazy var hostingController = NSHostingController(rootView: TrayChatView(viewModel: chatViewModel))

    func applicationDidFinishLaunching(_ notification: Notification) {
        fputs("LindosTrayApp: applicationDidFinishLaunching\n", stderr)
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let button = item.button

        if let button = button {
            #if DEBUG
            button.image = nil
            button.title = "Lindos"
            #else
            button.image = statusIcon
            button.imageScaling = .scaleProportionallyDown
            if #available(macOS 11.0, *) {
                button.contentTintColor = NSColor.labelColor
            }
            button.title = ""
            #endif
            button.toolTip = "Open Lindos"
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            let imageDescription = button.image?.name() ?? "nil"
            fputs("LindosTrayApp: Status item configured with image=\(imageDescription) title=\(button.title)\n", stderr)
        }

        #if DEBUG
        item.length = 64
        #else
        item.length = NSStatusItem.squareLength
        #endif

        statusItem = item
        item.isVisible = true
        if button == nil {
            fputs("LindosTrayApp: Failed to obtain status item button.\n", stderr)
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 220)
        popover.contentViewController = hostingController
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

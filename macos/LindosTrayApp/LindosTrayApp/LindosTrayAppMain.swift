import SwiftUI

@main
struct LindosTrayAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No visible windows; keep settings minimal for menu bar only app.
        Settings {
            EmptyView()
        }
    }
}

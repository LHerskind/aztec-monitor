import SwiftUI

@main
struct AztecGovernanceWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }

        // Start background refresh timer
        Task { @MainActor in
            BackgroundRefresh.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop the timer
        Task { @MainActor in
            BackgroundRefresh.shared.stop()
        }
    }
}

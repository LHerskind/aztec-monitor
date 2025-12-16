import Foundation
import WidgetKit

@MainActor
final class BackgroundRefresh {
    static let shared = BackgroundRefresh()

    private var timer: Timer?

    private init() {}

    func start() {
        stop()
        let config = Config.load()
        let interval = TimeInterval(config.pollIntervalMinutes * 60)

        // Create timer and add to common run loop mode for reliable firing in menu bar apps
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performRefresh()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer

        print("Background refresh started with interval: \(config.pollIntervalMinutes) minutes")

        // Perform initial refresh immediately
        Task {
            await performRefresh()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restart() {
        start()
    }

    func performRefresh() async {
        let config = Config.load()

        guard config.isValid else {
            print("Invalid config, skipping refresh")
            return
        }

        do {
            let ethClient = try EthClient(rpcEndpoint: config.rpcEndpoint)
            var newState = try await ethClient.fetchCurrentState(config: config)

            // Preserve notification tracking
            let previousState = MonitorState.load()
            if let previous = previousState {
                newState.notifiedProposals = previous.notifiedProposals
                newState.notifiedQuorums = previous.notifiedQuorums
            }

            let (events, updatedState) = TransitionDetector.detectEvents(
                previous: previousState,
                current: newState,
                config: config
            )

            // Send notifications
            NotificationManager.shared.sendEvents(events)

            // Save state (triggers widget reload)
            updatedState.save()

            print("Refresh completed: Round \(updatedState.currentRound), \(events.count) events")
        } catch {
            print("Refresh failed: \(error)")
        }
    }
}

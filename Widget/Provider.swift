import WidgetKit
import SwiftUI

struct RoundEntry: TimelineEntry {
    let date: Date
    let state: MonitorState?
    let config: Config
    var debugPath: String = ""
    var stateFileExists: Bool = false

    var currentRound: RoundData? {
        state?.currentRoundData
    }

    static let preview = RoundEntry(
        date: Date(),
        state: MonitorState(
            currentRound: 142,
            currentSlot: 36532,  // 142 * 256 + 180 = slot 180 in round
            rounds: [
                RoundData(
                    roundNumber: 142,
                    slotNumber: 180,
                    payload: "0xabc123def456789012345678901234567890abcd",
                    executed: false,
                    signalCount: 12,
                    quorumReached: false
                ),
                RoundData(
                    roundNumber: 141,
                    slotNumber: 150,
                    payload: "0x999111222333444555666777888999000111222",
                    executed: true,
                    signalCount: 15,
                    quorumReached: true
                ),
                RoundData(
                    roundNumber: 140,
                    slotNumber: 120,
                    payload: "0x555666777888999000111222333444555666777",
                    executed: false,
                    signalCount: 8,
                    quorumReached: false
                ),
                RoundData(
                    roundNumber: 139,
                    slotNumber: 90,
                    payload: nil,
                    executed: false,
                    signalCount: nil,
                    quorumReached: false
                ),
                RoundData(
                    roundNumber: 138,
                    slotNumber: 60,
                    payload: "0x222333444555666777888999000111222333444",
                    executed: true,
                    signalCount: 15,
                    quorumReached: true
                )
            ],
            quorumSize: 15,
            roundSize: 256,
            fetchedAt: Date(),
            blockNumber: 19234567,
            notifiedProposals: [],
            notifiedQuorums: []
        ),
        config: Config.default
    )
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RoundEntry {
        RoundEntry(date: Date(), state: nil, config: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoundEntry) -> Void) {
        let entry = RoundEntry(date: Date(), state: MonitorState.load(), config: Config.load())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoundEntry>) -> Void) {
        let config = Config.load()
        let state = MonitorState.load()

        var entry = RoundEntry(date: Date(), state: state, config: config)
        entry.debugPath = MonitorState.appGroupID
        entry.stateFileExists = state != nil

        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: config.pollIntervalMinutes,
            to: Date()
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

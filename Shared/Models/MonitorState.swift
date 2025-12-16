import Foundation
import WidgetKit

struct MonitorState: Codable, Equatable {
    let currentRound: UInt64
    let currentSlot: UInt64
    let rounds: [RoundData]
    let quorumSize: UInt64
    let roundSize: UInt64
    let fetchedAt: Date
    let blockNumber: UInt64
    var notifiedProposals: Set<String>
    var notifiedQuorums: Set<String>
    var governanceData: GovernanceData?
    var gseData: GSEData?

    // MARK: - Shared Storage via App Group UserDefaults

    static let appGroupID = "group.spaztec.aztec-monitor"
    private static let stateKey = "monitorState"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> MonitorState? {
        guard let data = sharedDefaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(MonitorState.self, from: data) else {
            return nil
        }
        return state
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }
        MonitorState.sharedDefaults.set(data, forKey: MonitorState.stateKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Slot progress within the current round (0 to roundSize-1)
    var slotInRound: UInt64 {
        guard roundSize > 0 else { return 0 }
        return currentSlot % roundSize
    }

    /// Formatted slot progress like "85/1000" (no locale formatting)
    var formattedSlotProgress: String {
        String(slotInRound) + "/" + String(roundSize)
    }

    var currentRoundData: RoundData? {
        rounds.first { $0.roundNumber == currentRound }
    }

    var lastRounds: [RoundData] {
        Array(rounds.prefix(10))
    }

    var pastRounds: [RoundData] {
        Array(rounds.dropFirst().prefix(7))
    }

    var formattedFetchTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: fetchedAt)
    }

    var formattedBlockNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: blockNumber)) ?? String(blockNumber)
    }

    func notificationKey(round: UInt64, payload: String) -> String {
        "\(round):\(payload)"
    }

    static let placeholder = MonitorState(
        currentRound: 0,
        currentSlot: 0,
        rounds: [],
        quorumSize: 15,
        roundSize: 256,
        fetchedAt: Date(),
        blockNumber: 0,
        notifiedProposals: [],
        notifiedQuorums: [],
        governanceData: nil,
        gseData: nil
    )
}

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
                ),
                RoundData(
                    roundNumber: 137,
                    slotNumber: 30,
                    payload: "0x333444555666777888999000111222333444555",
                    executed: false,
                    signalCount: 10,
                    quorumReached: false
                ),
                RoundData(
                    roundNumber: 136,
                    slotNumber: 200,
                    payload: "0x444555666777888999000111222333444555666",
                    executed: true,
                    signalCount: 15,
                    quorumReached: true
                ),
                RoundData(
                    roundNumber: 135,
                    slotNumber: 100,
                    payload: nil,
                    executed: false,
                    signalCount: nil,
                    quorumReached: false
                ),
                RoundData(
                    roundNumber: 134,
                    slotNumber: 50,
                    payload: "0x555666777888999000111222333444555666777",
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
            notifiedQuorums: [],
            governanceData: GovernanceData(
                proposalCount: 0,
                totalPower: 215_530_000,
                proposals: []
            ),
            gseData: GSEData(
                totalSupply: 215_530_000,
                bonusInstanceAddress: "0x0000000000000000000000000000000000000000",
                bonusSupply: 215_530_000,
                rollupSupplyRaw: 0,
                bonusAttesterCount: 1078,
                rollupAttesterCountRaw: 1078,
                rollupIsCanonical: true,
                activationThreshold: 100_000
            ),
            rollupData: RollupData(
                pendingBlockNumber: 40708,
                provenBlockNumber: 40700,
                targetCommitteeSize: 48,
                blockReward: 0.1,
                entryQueueLength: 5,
                epochDuration: 32,
                entryQueueFlushSize: 4,
                genesisTime: 1700000000,
                slotDuration: 12,
                recentBlockSlots: [40700, 40699, 40698, 40697, 40696, 40695, 40694, 40693, 40692, 40691, 40690, 40689, 40688, 40687, 40686, 40685],
                fetchedAt: Date()
            )
        ),
        config: Config.default
    )
}

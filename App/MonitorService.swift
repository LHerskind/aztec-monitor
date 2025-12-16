import Foundation

struct MonitorService {
    let client: EthClient
    let governanceProposer: GovernanceProposer
    let governance: Governance
    let rollup: Rollup

    init(client: EthClient, config: Config) {
        self.client = client
        self.governanceProposer = GovernanceProposer(client: client, address: config.governanceProposerAddress)
        self.governance = Governance(client: client, address: config.governanceAddress)
        self.rollup = Rollup(client: client, address: config.rollupAddress)
    }

    func fetchCurrentState() async throws -> MonitorState {
        let blockNumber = try await client.getBlockNumber()
        let currentRound = try await governanceProposer.getCurrentRound()
        let currentSlot = try await rollup.getCurrentSlot()
        let quorumSize = try await governanceProposer.getQuorumSize()
        let roundSize = try await governanceProposer.getRoundSize()

        var rounds: [RoundData] = []

        let startRound = currentRound >= 8 ? currentRound - 8 : 0

        for roundNum in stride(from: currentRound, through: startRound, by: -1) {
            let (slot, payload, executed) = try await governanceProposer.getRoundData(
                instance: rollup.address,
                round: roundNum
            )

            var signalCount: UInt64? = nil
            var quorumReached = false

            if let payload = payload {
                signalCount = try await governanceProposer.getSignalCount(
                    instance: rollup.address,
                    round: roundNum,
                    payload: payload
                )
                quorumReached = signalCount! >= quorumSize
            }

            rounds.append(RoundData(
                roundNumber: roundNum,
                slotNumber: slot,
                payload: payload,
                executed: executed,
                signalCount: signalCount,
                quorumReached: quorumReached
            ))
        }

        return MonitorState(
            currentRound: currentRound,
            currentSlot: currentSlot,
            rounds: rounds,
            quorumSize: quorumSize,
            roundSize: roundSize,
            fetchedAt: Date(),
            blockNumber: blockNumber,
            notifiedProposals: [],
            notifiedQuorums: []
        )
    }
}

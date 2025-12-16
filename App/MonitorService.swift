import Foundation

struct MonitorService {
    let client: EthClient
    let governanceProposer: GovernanceProposer
    let governance: Governance
    let gse: GSE
    let rollup: Rollup

    init(client: EthClient, config: Config) {
        self.client = client
        self.governanceProposer = GovernanceProposer(client: client, address: config.governanceProposerAddress)
        self.governance = Governance(client: client, address: config.governanceAddress)
        self.gse = GSE(client: client, address: config.gseAddress)
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

        // Fetch governance data
        let governanceData = try await fetchGovernanceData()

        // Fetch GSE data
        let gseData = try await fetchGSEData()

        return MonitorState(
            currentRound: currentRound,
            currentSlot: currentSlot,
            rounds: rounds,
            quorumSize: quorumSize,
            roundSize: roundSize,
            fetchedAt: Date(),
            blockNumber: blockNumber,
            notifiedProposals: [],
            notifiedQuorums: [],
            governanceData: governanceData,
            gseData: gseData
        )
    }

    private func fetchGovernanceData() async throws -> GovernanceData {
        let proposalCount = try await governance.getProposalCount()
        let totalPower = try await governance.getTotalPowerNow()

        return GovernanceData(
            proposalCount: proposalCount,
            totalPower: totalPower
        )
    }

    private func fetchGSEData() async throws -> GSEData {
        let totalSupply = try await gse.getTotalSupply()
        let bonusInstanceAddress = try await gse.getBonusInstanceAddress()
        let latestRollup = try await gse.getLatestRollup()

        let bonusSupply = try await gse.getSupplyOf(instance: bonusInstanceAddress)
        let rollupSupply = try await gse.getSupplyOf(instance: rollup.address)

        // Get current timestamp for attester count
        let currentTimestamp = UInt64(Date().timeIntervalSince1970)

        let bonusAttesterCount = try await gse.getAttesterCountAtTime(
            instance: bonusInstanceAddress,
            timestamp: currentTimestamp
        )
        let rollupAttesterCount = try await gse.getAttesterCountAtTime(
            instance: rollup.address,
            timestamp: currentTimestamp
        )

        // Check if configured rollup is the canonical (latest) rollup
        let rollupIsCanonical = rollup.address.lowercased() == latestRollup.lowercased()

        return GSEData(
            totalSupply: totalSupply,
            bonusInstanceAddress: bonusInstanceAddress,
            bonusSupply: bonusSupply,
            rollupSupplyRaw: rollupSupply,
            bonusAttesterCount: bonusAttesterCount,
            rollupAttesterCountRaw: rollupAttesterCount,
            rollupIsCanonical: rollupIsCanonical
        )
    }
}

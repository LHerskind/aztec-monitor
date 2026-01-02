import Foundation

struct GovernanceData: Codable, Equatable {
    let proposalCount: UInt64
    let totalPower: Double
    let proposals: [ProposalData]

    var formattedTotalPower: String {
        formatLargeNumber(totalPower)
    }

    var activeProposals: [ProposalData] {
        proposals.filter { !$0.state.isTerminal }
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.2fK", value / 1_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

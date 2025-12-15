import Foundation

struct RoundData: Codable, Equatable, Identifiable {
    let roundNumber: UInt64
    let slotNumber: UInt32
    let payload: String?
    let executed: Bool
    let signalCount: UInt64?
    let quorumReached: Bool

    var id: UInt64 { roundNumber }

    var hasProposal: Bool {
        payload != nil
    }

    var statusText: String {
        guard hasProposal else {
            return "No proposal"
        }
        if executed {
            return "Executed"
        }
        if quorumReached {
            return "Quorum reached"
        }
        return "Pending"
    }

    var shortPayload: String? {
        guard let payload = payload else { return nil }
        guard payload.count >= 10 else { return payload }
        let start = payload.prefix(6)
        let end = payload.suffix(4)
        return "\(start)...\(end)"
    }

    static func placeholder(round: UInt64) -> RoundData {
        RoundData(
            roundNumber: round,
            slotNumber: 0,
            payload: nil,
            executed: false,
            signalCount: nil,
            quorumReached: false
        )
    }
}

import Foundation

enum NotificationEvent: Equatable {
    case newProposal(round: UInt64, payload: String, slot: UInt32)
    case quorumReached(round: UInt64, payload: String, signalCount: UInt64, quorumSize: UInt64)

    var title: String {
        switch self {
        case .newProposal:
            return "New Proposal"
        case .quorumReached:
            return "Quorum Reached"
        }
    }

    var body: String {
        switch self {
        case .newProposal(let round, let payload, let slot):
            let shortPayload = shortAddress(payload)
            return "Round \(round): New proposal \(shortPayload) at slot \(slot)"
        case .quorumReached(let round, let payload, let signalCount, _):
            let shortPayload = shortAddress(payload)
            return "Round \(round): Proposal \(shortPayload) reached quorum (\(signalCount) signals)"
        }
    }

    private func shortAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = address.prefix(6)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
}

struct TransitionDetector {
    static func detectEvents(
        previous: MonitorState?,
        current: MonitorState,
        config: Config
    ) -> (events: [NotificationEvent], updatedState: MonitorState) {
        var events: [NotificationEvent] = []
        var notifiedProposals = previous?.notifiedProposals ?? []
        var notifiedQuorums = previous?.notifiedQuorums ?? []

        for round in current.rounds {
            guard let payload = round.payload else { continue }

            let key = "\(round.roundNumber):\(payload)"

            // New proposal we haven't notified about
            if config.notifyOnNewProposal && !notifiedProposals.contains(key) {
                events.append(.newProposal(
                    round: round.roundNumber,
                    payload: payload,
                    slot: round.slotNumber
                ))
                notifiedProposals.insert(key)
            }

            // Quorum reached for first time
            if config.notifyOnQuorumReached
                && round.quorumReached
                && !notifiedQuorums.contains(key) {
                if let signalCount = round.signalCount {
                    events.append(.quorumReached(
                        round: round.roundNumber,
                        payload: payload,
                        signalCount: signalCount,
                        quorumSize: current.quorumSize
                    ))
                }
                notifiedQuorums.insert(key)
            }
        }

        var updatedState = current
        updatedState.notifiedProposals = notifiedProposals
        updatedState.notifiedQuorums = notifiedQuorums

        return (events, updatedState)
    }
}

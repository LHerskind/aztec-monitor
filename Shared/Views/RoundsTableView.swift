import SwiftUI

struct RoundsTableView: View {
    let rounds: [RoundData]
    let currentRound: UInt64
    let config: Config?  // Optional - if provided, enables clickable links

    private var enableLinks: Bool {
        config != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            HStack(spacing: 6) {
                Text("Round")
                    .frame(width: 44, alignment: .leading)
                Text("Leader")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Signals")
                    .frame(width: 36, alignment: .trailing)
                Text("Status")
                    .frame(width: 70, alignment: .trailing)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

            ForEach(rounds) { round in
                RoundRowView(
                    round: round,
                    currentRound: currentRound,
                    config: config
                )
            }
        }
    }
}

struct RoundRowView: View {
    let round: RoundData
    let currentRound: UInt64
    let config: Config?

    private var isPastRound: Bool {
        round.roundNumber < currentRound
    }

    var body: some View {
        HStack(spacing: 6) {
            // Round number
            Text("\(round.roundNumber)")
                .frame(width: 44, alignment: .leading)

            // Proposal/Leader
            payloadView
                .frame(maxWidth: .infinity, alignment: .leading)

            // Signals
            if let signalCount = round.signalCount {
                Text("\(signalCount)")
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            } else {
                Text("-")
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }

            // Status
            statusView
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption2)
    }

    @ViewBuilder
    private var payloadView: some View {
        if let payload = round.payload {
            if let config = config, let url = config.explorerURL(for: payload) {
                Link(destination: url) {
                    Text(payload)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.blue)
                }
            } else {
                Text(payload)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.secondary)
            }
        } else {
            Text("-")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if !round.hasProposal {
            Text("no proposal")
                .foregroundColor(.secondary)
        } else if round.executed {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("executed")
                    .foregroundColor(.green)
            }
        } else if round.quorumReached {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("passed")
                    .foregroundColor(.green)
            }
        } else if isPastRound {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("rejected")
                    .foregroundColor(.red)
            }
        } else {
            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("pending")
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    RoundsTableView(
        rounds: [
            RoundData(roundNumber: 103, slotNumber: 0, payload: "0x1234567890abcdef", executed: true, signalCount: 18, quorumReached: true),
            RoundData(roundNumber: 102, slotNumber: 0, payload: "0xabcdef1234567890", executed: false, signalCount: 12, quorumReached: false),
            RoundData(roundNumber: 101, slotNumber: 0, payload: nil, executed: false, signalCount: nil, quorumReached: false),
            RoundData(roundNumber: 100, slotNumber: 0, payload: "0x9876543210fedcba", executed: false, signalCount: 16, quorumReached: true),
        ],
        currentRound: 104,
        config: nil
    )
    .padding()
    .frame(width: 300)
}

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            Text("Aztec Governance Proposer Monitor")
                .font(.caption)
                .foregroundColor(.secondary)

            // Header
            HStack {
                Text("Round \(entry.state?.currentRound ?? 0)")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if let state = entry.state {
                    Text("slot \(state.slotInRound)/\(state.roundSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Current round details
            if let round = entry.currentRound {
                if let payload = round.payload, let shortPayload = round.shortPayload {
                    // Proposal
                    if let url = entry.config.explorerURL(for: payload) {
                        Link(destination: url) {
                            HStack {
                                Text("Proposal:")
                                    .foregroundColor(.primary)
                                Text(shortPayload)
                                    .foregroundColor(.blue)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .font(.subheadline)
                        }
                    } else {
                        HStack {
                            Text("Proposal:")
                            Text(shortPayload)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }

                    // Progress bar
                    if let signalCount = round.signalCount, let quorumSize = entry.state?.quorumSize {
                        HStack {
                            Text("Signals:")
                                .font(.caption)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(round.quorumReached ? Color.green : Color.blue)
                                        .frame(
                                            width: geometry.size.width * min(1.0, CGFloat(signalCount) / CGFloat(quorumSize)),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)

                            Text("\(signalCount)/\(quorumSize)")
                                .font(.caption)
                                .foregroundColor(round.quorumReached ? .green : .secondary)

                            if round.quorumReached {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                } else {
                    Text("No proposal yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .padding(.vertical, 2)

            // History header row
            HStack(spacing: 6) {
                Text("Round")
                    .frame(width: 36, alignment: .leading)
                Text("Leader")
                    .frame(width: 75, alignment: .leading)
                Text("Signals")
                    .frame(width: 44, alignment: .trailing)
                Text("Status")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

            // Past rounds list
            if let state = entry.state {
                ForEach(state.pastRounds) { round in
                    RoundRowView(round: round, currentRound: state.currentRound, quorumSize: state.quorumSize, config: entry.config)
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("Updated: \(entry.state?.formattedFetchTime ?? "--:--")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let blockNumber = entry.state?.formattedBlockNumber {
                    Spacer()
                    Text("block \(blockNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct RoundRowView: View {
    let round: RoundData
    let currentRound: UInt64
    let quorumSize: UInt64
    let config: Config

    private var isPastRound: Bool {
        round.roundNumber < currentRound
    }

    var body: some View {
        HStack(spacing: 6) {
            // Round number
            Text("\(round.roundNumber)")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 36, alignment: .leading)

            // Proposal
            if let shortPayload = round.shortPayload {
                Text(shortPayload)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 75, alignment: .leading)
            } else {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 75, alignment: .leading)
            }

            // Signals
            if let signalCount = round.signalCount {
                Text("\(signalCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            } else {
                Text("-")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            // Status
            statusView
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 1)
    }

    @ViewBuilder
    private var statusView: some View {
        if !round.hasProposal {
            Text("no proposal")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else if round.executed {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("executed")
                    .foregroundColor(.green)
            }
            .font(.caption2)
        } else if round.quorumReached {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("passed")
                    .foregroundColor(.green)
            }
            .font(.caption2)
        } else if isPastRound {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("rejected")
                    .foregroundColor(.red)
            }
            .font(.caption2)
        } else {
            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("pending")
                    .foregroundColor(.orange)
            }
            .font(.caption2)
        }
    }
}

// WidgetKit preview
#Preview(as: .systemLarge) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

// Simple SwiftUI preview
#Preview("Large Widget View") {
    LargeWidgetView(entry: RoundEntry.preview)
        .frame(width: 329, height: 345)
        .background(.background)
}

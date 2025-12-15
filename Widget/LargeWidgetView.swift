import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Round Monitor")
                .font(.headline)
                .fontWeight(.bold)

            Divider()

            // Rounds list
            if let state = entry.state {
                ForEach(state.lastFiveRounds) { round in
                    RoundRowView(round: round, quorumSize: state.quorumSize, config: entry.config)
                }
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()

            Divider()

            // Footer with debug info
            VStack(alignment: .leading, spacing: 2) {
                if let state = entry.state {
                    Text("Round \(state.currentRound) - \(state.formattedFetchTime)")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("State: nil (exists: \(entry.stateFileExists ? "yes" : "no"))")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                Text("Path: \(entry.debugPath)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}

struct RoundRowView: View {
    let round: RoundData
    let quorumSize: UInt64
    let config: Config

    var body: some View {
        HStack(spacing: 8) {
            // Round number
            Text("R\(round.roundNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)

            // Proposal
            if let payload = round.payload, let shortPayload = round.shortPayload {
                if let url = config.explorerURL(for: payload) {
                    Link(destination: url) {
                        Text(shortPayload)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 80, alignment: .leading)
                } else {
                    Text(shortPayload)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                }
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
            }

            // Signals
            if let signalCount = round.signalCount {
                Text("\(signalCount)/\(quorumSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }

            // Status
            statusView
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 2)
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
                Text("quorum")
                    .foregroundColor(.green)
            }
            .font(.caption2)
        } else {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle")
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

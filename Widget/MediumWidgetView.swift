import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        if let state = entry.state {
            HStack(spacing: 12) {
                // Left: Current round info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(state.currentRound)")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Slot \(state.formattedSlotProgress)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let round = state.currentRoundData {
                        HStack(spacing: 4) {
                            if round.hasProposal {
                                Image(systemName: round.quorumReached ? "checkmark.circle.fill" : "clock")
                                    .foregroundColor(round.quorumReached ? .green : .orange)
                                Text("\(round.signalCount ?? 0)/\(state.quorumSize)")
                                    .font(.caption)
                            } else {
                                Image(systemName: "doc.badge.clock")
                                    .foregroundColor(.secondary)
                                Text("No proposal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Right: Recent rounds summary
                VStack(alignment: .trailing, spacing: 4) {
                    let passedCount = state.pastRounds.filter { $0.executed || $0.quorumReached }.count
                    let totalWithProposal = state.pastRounds.filter { $0.hasProposal }.count

                    Text("\(passedCount)/\(totalWithProposal)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(passedCount == totalWithProposal ? .green : .orange)

                    Text("recent passed")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(state.formattedFetchTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(as: .systemMedium) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

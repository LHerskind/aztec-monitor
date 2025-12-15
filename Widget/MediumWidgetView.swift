import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Round \(entry.state?.currentRound ?? 0)")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if let round = entry.currentRound, let roundSize = entry.state?.roundSize {
                    Text("slot \(round.slotNumber)/\(roundSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Content
            if let round = entry.currentRound {
                if let payload = round.payload, let shortPayload = round.shortPayload {
                    // Proposal link
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
                        VStack(alignment: .leading, spacing: 4) {
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
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Status
                        HStack {
                            Text("Status:")
                                .font(.caption)
                            Text(round.statusText)
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
            } else {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Footer
            HStack {
                Text("Updated: \(entry.state?.formattedFetchTime ?? "--:--")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let blockNumber = entry.state?.formattedBlockNumber {
                    Text("block \(blockNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// WidgetKit preview
#Preview(as: .systemMedium) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

// Simple SwiftUI preview
#Preview("Medium Widget View") {
    MediumWidgetView(entry: RoundEntry.preview)
        .frame(width: 329, height: 155)
        .background(.background)
}

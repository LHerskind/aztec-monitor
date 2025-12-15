import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: Round and Slot
            HStack {
                Text("R\(entry.state?.currentRound ?? 0)")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if let round = entry.currentRound, let roundSize = entry.state?.roundSize {
                    Text("\(round.slotNumber)/\(roundSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Proposal info
            if let round = entry.currentRound {
                if let shortPayload = round.shortPayload {
                    HStack(spacing: 4) {
                        Text(shortPayload)
                            .font(.caption)
                            .lineLimit(1)

                        if let signalCount = round.signalCount {
                            Text("\(signalCount)/\(entry.state?.quorumSize ?? 15)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No proposal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Footer: Time and status
            HStack {
                Text(entry.state?.formattedFetchTime ?? "--:--")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let round = entry.currentRound, round.quorumReached {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(12)
    }
}

// WidgetKit preview
#Preview(as: .systemSmall) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

// Simple SwiftUI preview (works without full widget setup)
#Preview("Small Widget View") {
    SmallWidgetView(entry: RoundEntry.preview)
        .frame(width: 155, height: 155)
        .background(.background)
}

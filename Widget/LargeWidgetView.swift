import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        if let state = entry.state {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("Round \(state.currentRound)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("Slot \(state.formattedSlotProgress)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Rounds table
                RoundsTableView(
                    rounds: state.lastRounds,
                    currentRound: state.currentRound,
                    config: nil
                )

                Spacer()

                // Footer
                HStack {
                    Text("Updated \(state.formattedFetchTime)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Block \(state.formattedBlockNumber)")
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

#Preview(as: .systemLarge) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

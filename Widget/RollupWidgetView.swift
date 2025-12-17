import SwiftUI
import WidgetKit

struct RollupWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        if let state = entry.state, let rollup = state.rollupData {
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack {
                    Text("Rollup")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    if let avgTime = rollup.formattedAverageBlockTime {
                        Text("Avg: \(avgTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Block numbers
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pending")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(rollup.formattedPendingBlockNumber)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Proven")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(rollup.formattedProvenBlockNumber)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Unproven")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(rollup.unprovenBlocks)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(rollup.unprovenBlocks > 10 ? .orange : .primary)
                    }
                }

                // Slot strip
                if let currentSlot = rollup.recentBlockSlots.first {
                    SlotStripView(
                        blockSlots: rollup.recentBlockSlots,
                        currentSlot: currentSlot
                    )
                    .id(rollup.recentBlockSlots.hashValue)
                }

                // Footer
                HStack {
                    if let elapsed = rollup.formattedTimeSinceLastBlock {
                        Text("Last block: \(elapsed)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(state.formattedFetchTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "square.stack.3d.up")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No rollup data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(as: .systemMedium) {
    RollupWidget()
} timeline: {
    RoundEntry.preview
}

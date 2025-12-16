import SwiftUI
import WidgetKit

struct ChartWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Governance Signals")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let state = entry.state {
                    Text("Round \(state.currentRound)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Chart
            if let state = entry.state {
                SignalChartView(
                    rounds: state.lastRounds,
                    currentRound: state.currentRound,
                    quorumSize: state.quorumSize
                )

                // Compact legend
                HStack(spacing: 8) {
                    legendItem(color: .green, label: "Pass")
                    legendItem(color: .red, label: "Fail")
                    legendItem(color: .orange, label: "Pending")
                    Spacer()
                    Text(state.formattedFetchTime)
                        .foregroundColor(.secondary)
                }
                .font(.caption2)
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// WidgetKit preview
#Preview(as: .systemMedium) {
    SignalChartWidget()
} timeline: {
    RoundEntry.preview
}

// Simple SwiftUI preview
#Preview("Chart Widget View") {
    ChartWidgetView(entry: RoundEntry.preview)
        .frame(width: 329, height: 155)
        .background(.background)
}

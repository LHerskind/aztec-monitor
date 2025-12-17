import SwiftUI
import WidgetKit

struct ChartWidgetView: View {
    let entry: RoundEntry

    var body: some View {
        if let state = entry.state {
            VStack(alignment: .leading, spacing: 4) {
                SignalChartView(
                    rounds: state.lastRounds,
                    currentRound: state.currentRound,
                    quorumSize: state.quorumSize
                )

                HStack {
                    Text("Updated \(state.formattedFetchTime)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(as: .systemMedium) {
    SignalChartWidget()
} timeline: {
    RoundEntry.preview
}

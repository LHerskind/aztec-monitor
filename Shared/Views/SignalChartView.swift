import SwiftUI
import Charts

struct ChartRoundData: Identifiable {
    let id: UInt64
    let roundNumber: UInt64
    let signalCount: Int
    let status: RoundStatus

    enum RoundStatus {
        case passed      // Green - quorum reached or executed
        case rejected    // Red - past round, had proposal, didn't reach quorum
        case pending     // Orange - current round, in progress
        case noProposal  // Gray - no proposal submitted

        var color: Color {
            switch self {
            case .passed: return .green
            case .rejected: return .red
            case .pending: return .orange
            case .noProposal: return .gray.opacity(0.5)
            }
        }
    }
}

struct SignalChartView: View {
    let rounds: [RoundData]
    let currentRound: UInt64
    let quorumSize: UInt64

    private var chartData: [ChartRoundData] {
        rounds.map { round in
            let status: ChartRoundData.RoundStatus
            let isPast = round.roundNumber < currentRound

            if !round.hasProposal {
                status = .noProposal
            } else if round.executed || round.quorumReached {
                status = .passed
            } else if isPast {
                status = .rejected
            } else {
                status = .pending
            }

            return ChartRoundData(
                id: round.roundNumber,
                roundNumber: round.roundNumber,
                signalCount: Int(round.signalCount ?? 0),
                status: status
            )
        }
        .sorted { $0.roundNumber < $1.roundNumber } // Oldest to newest (left to right)
    }

    private var yAxisMax: Int {
        let maxSignals = chartData.map { $0.signalCount }.max() ?? 0
        let quorum = Int(quorumSize)
        return max(maxSignals, quorum) + 2 // Add buffer above
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Signals by Round")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Chart {
                // Quorum threshold line
                RuleMark(y: .value("Quorum", Int(quorumSize)))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Q")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                // Bars for each round
                ForEach(chartData) { data in
                    BarMark(
                        x: .value("Round", String(data.roundNumber)),
                        y: .value("Signals", data.signalCount)
                    )
                    .foregroundStyle(data.status.color)
                    .cornerRadius(2)
                }
            }
            .chartYScale(domain: 0...yAxisMax)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
    }
}

#Preview {
    SignalChartView(
        rounds: [
            RoundData(roundNumber: 100, slotNumber: 0, payload: "0x123", executed: true, signalCount: 18, quorumReached: true),
            RoundData(roundNumber: 101, slotNumber: 0, payload: "0x456", executed: false, signalCount: 12, quorumReached: false),
            RoundData(roundNumber: 102, slotNumber: 0, payload: nil, executed: false, signalCount: nil, quorumReached: false),
            RoundData(roundNumber: 103, slotNumber: 0, payload: "0x789", executed: false, signalCount: 16, quorumReached: true),
            RoundData(roundNumber: 104, slotNumber: 0, payload: "0xabc", executed: false, signalCount: 8, quorumReached: false),
            RoundData(roundNumber: 105, slotNumber: 0, payload: "0xdef", executed: false, signalCount: 10, quorumReached: false),
        ],
        currentRound: 105,
        quorumSize: 15
    )
    .frame(width: 280, height: 180)
    .padding()
}

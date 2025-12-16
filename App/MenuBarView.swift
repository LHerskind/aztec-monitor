import SwiftUI

struct MenuBarView: View {
    @State private var currentState: MonitorState? = MonitorState.load()
    @State private var config: Config = Config.load()
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Aztec Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            Divider()

            // Section 1: Governance Proposer
            VStack(alignment: .leading, spacing: 8) {
                Text("Governance Proposer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 16) {
                    // Left - Base info
                    proposerBasePanel
                        .frame(width: 320)

                    Divider()

                    // Right - Chart
                    proposerChartPanel
                        .frame(width: 300)
                }
            }

            Divider()

            // Section 2: Governance & GSE | Rollup
            HStack(alignment: .top, spacing: 16) {
                // Left column - Governance & GSE stacked
                VStack(alignment: .leading, spacing: 12) {
                    governanceSection
                    Divider()
                    gseSection
                }
                .frame(width: 320)

                Divider()

                // Right column - Rollup (placeholder for future)
                rollupSection
                    .frame(width: 300)
            }

            Divider()

            // Footer
            footerSection
        }
        .padding(16)
        .frame(width: 680)
        .onAppear {
            refreshState()
        }
    }

    // MARK: - Proposer Base Panel (Left)

    @ViewBuilder
    private var proposerBasePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current round section
            if let state = currentState, let round = state.currentRoundData {
                currentRoundSection(state: state, round: round)
            } else if currentState != nil {
                Text("No proposal in current round")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Divider()

            // History
            if let state = currentState {
                historySection(state: state)
            }
        }
    }

    // MARK: - Proposer Chart Panel (Right)

    @ViewBuilder
    private var proposerChartPanel: some View {
        if let state = currentState {
            VStack(alignment: .leading, spacing: 8) {
                let allRounds = state.lastRounds
                SignalChartView(
                    rounds: allRounds,
                    currentRound: state.currentRound,
                    quorumSize: state.quorumSize
                )
                .frame(height: 160)

                // Legend
                legendView
            }
        } else {
            Text("No data available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            legendItem(color: .green, label: "Passed")
            legendItem(color: .red, label: "Rejected")
            legendItem(color: .orange, label: "Pending")
            legendItem(color: .gray.opacity(0.5), label: "No proposal")
        }
        .font(.caption2)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Governance Section

    @ViewBuilder
    private var governanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Governance")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if let governance = currentState?.governanceData {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Proposals:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(governance.proposalCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Total Power:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(governance.formattedTotalPower)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - GSE Section

    @ViewBuilder
    private var gseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GSE")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if let gse = currentState?.gseData {
                // Header row
                HStack {
                    Text("")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text("Supply")
                        .frame(width: 60, alignment: .trailing)
                    Text("Attesters")
                        .frame(width: 55, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                // Total row
                HStack {
                    Text("Total")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text(gse.formattedTotalSupply)
                        .frame(width: 60, alignment: .trailing)
                    Text("\(gse.totalAttesterCount)")
                        .frame(width: 55, alignment: .trailing)
                }
                .font(.caption)
                .fontWeight(.medium)

                Divider()

                // Latest Rollup section
                Text("Latest Rollup")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Direct row
                HStack {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Direct")
                    }
                    .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text(gse.formattedRollupSupplyDirect)
                        .frame(width: 60, alignment: .trailing)
                    Text("\(gse.rollupAttesterCountDirect)")
                        .frame(width: 55, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundColor(.blue)

                // Bonus row (follows canonical)
                HStack {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                        Text("+ Bonus")
                    }
                    .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text(gse.formattedBonusSupply)
                        .frame(width: 60, alignment: .trailing)
                    Text("\(gse.bonusAttesterCount)")
                        .frame(width: 55, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundColor(.purple)

                // Effective row
                HStack {
                    Text("= Effective")
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    Text(gse.formattedRollupSupplyEffective)
                        .frame(width: 60, alignment: .trailing)
                    Text("\(gse.rollupAttesterCountEffective)")
                        .frame(width: 55, alignment: .trailing)
                }
                .font(.caption)
                .fontWeight(.medium)

                // Stacked bar showing composition
                StackedBar(
                    values: [
                        (gse.rollupSupplyDirect, Color.blue),
                        (gse.bonusSupply, Color.purple)
                    ],
                    total: gse.totalSupply
                )
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Rollup Section

    @ViewBuilder
    private var rollupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rollup")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Placeholder for future rollup-specific data
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Current Round

    @ViewBuilder
    private func currentRoundSection(state: MonitorState, round: RoundData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Round \(state.currentRound)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("slot \(state.slotInRound)/\(state.roundSize)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let payload = round.payload {
                if let url = config.explorerURL(for: payload) {
                    Link(destination: url) {
                        HStack {
                            Text("Proposal:")
                                .foregroundColor(.primary)
                            Text(payload)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .font(.caption2)
                    }
                }

                // Progress bar
                if let signalCount = round.signalCount {
                    HStack {
                        Text("Signals:")
                            .font(.caption2)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(round.quorumReached ? Color.green : Color.blue)
                                    .frame(
                                        width: geometry.size.width * min(1.0, CGFloat(signalCount) / CGFloat(state.quorumSize)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)

                        Text("\(signalCount)/\(state.quorumSize)")
                            .font(.caption2)
                            .foregroundColor(round.quorumReached ? .green : .secondary)

                        if round.quorumReached {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)
                        }
                    }
                }
            } else {
                Text("No proposal yet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private func historySection(state: MonitorState) -> some View {
        RoundsTableView(
            rounds: state.pastRounds,
            currentRound: state.currentRound,
            config: config
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if let state = currentState {
                Text("Updated: \(state.formattedFetchTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("block \(state.formattedBlockNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                Task { await refreshNow() }
            }) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .disabled(isRefreshing)

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Actions

    private func refreshState() {
        currentState = MonitorState.load()
        config = Config.load()
    }

    @MainActor
    private func refreshNow() async {
        isRefreshing = true

        do {
            let ethClient = try EthClient(rpcEndpoint: config.rpcEndpoint)
            let monitorService = MonitorService(client: ethClient, config: config)
            var newState = try await monitorService.fetchCurrentState()

            if let previous = MonitorState.load() {
                newState.notifiedProposals = previous.notifiedProposals
                newState.notifiedQuorums = previous.notifiedQuorums
            }

            let (events, updatedState) = TransitionDetector.detectEvents(
                previous: currentState,
                current: newState,
                config: config
            )

            NotificationManager.shared.sendEvents(events)
            updatedState.save()
            currentState = updatedState
        } catch {
            print("Refresh error: \(error)")
        }

        isRefreshing = false
    }
}

// MARK: - Distribution Bar

struct DistributionBar: View {
    let leftValue: Double
    let rightValue: Double
    let leftColor: Color
    let rightColor: Color

    private var total: Double {
        leftValue + rightValue
    }

    private var leftPercentage: CGFloat {
        guard total > 0 else { return 0.5 }
        return CGFloat(leftValue / total)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(leftColor)
                    .frame(width: max(2, geometry.size.width * leftPercentage))

                RoundedRectangle(cornerRadius: 2)
                    .fill(rightColor)
                    .frame(width: max(2, geometry.size.width * (1 - leftPercentage)))
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let value: Double
    let total: Double
    let color: Color

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(value / total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(2, geometry.size.width * percentage))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Stacked Bar

struct StackedBar: View {
    let values: [(Double, Color)]
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                    let (value, color) = item
                    let width = total > 0 ? geometry.size.width * CGFloat(value / total) : 0
                    RoundedRectangle(cornerRadius: 0)
                        .fill(color)
                        .frame(width: max(0, width))
                }
                // Remaining space (other/unaccounted)
                Spacer(minLength: 0)
            }
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 8)
    }
}

#Preview {
    MenuBarView()
}

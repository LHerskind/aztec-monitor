import SwiftUI

struct MenuBarView: View {
    @State private var currentState: MonitorState? = MonitorState.load()
    @State private var config: Config = Config.load()
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Governance Proposer")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            Divider()

            // Main content - side by side
            HStack(alignment: .top, spacing: 16) {
                // Left panel - Base info
                basePanel
                    .frame(width: 300)

                Divider()

                // Right panel - Chart
                chartPanel
                    .frame(width: 280)
            }

            Divider()

            // Footer
            footerSection
        }
        .padding()
        .frame(width: 640)
        .onAppear {
            refreshState()
        }
    }

    // MARK: - Base Panel (Left)

    @ViewBuilder
    private var basePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current round section
            if let state = currentState, let round = state.currentRoundData {
                currentRoundSection(state: state, round: round)
            } else if currentState != nil {
                Text("No proposal in current round")
                    .foregroundColor(.secondary)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
            }

            Divider()

            // History
            if let state = currentState {
                historySection(state: state)
            }
        }
    }

    // MARK: - Chart Panel (Right)

    @ViewBuilder
    private var chartPanel: some View {
        if let state = currentState {
            VStack(alignment: .leading, spacing: 8) {
                // Include current round in chart data
                let allRounds = state.lastRounds
                SignalChartView(
                    rounds: allRounds,
                    currentRound: state.currentRound,
                    quorumSize: state.quorumSize
                )
                .frame(height: 180)

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

    // MARK: - Current Round

    @ViewBuilder
    private func currentRoundSection(state: MonitorState, round: RoundData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Round \(state.currentRound)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("slot \(state.slotInRound)/\(state.roundSize)")
                    .font(.caption)
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
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                }

                // Progress bar
                if let signalCount = round.signalCount {
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
                                        width: geometry.size.width * min(1.0, CGFloat(signalCount) / CGFloat(state.quorumSize)),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)

                        Text("\(signalCount)/\(state.quorumSize)")
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
                    .font(.caption)
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
            config: config  // Enable clickable links
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if let state = currentState {
                Text("Updated: \(state.formattedFetchTime)")
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
            var newState = try await ethClient.fetchCurrentState(config: config)

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

#Preview {
    MenuBarView()
}

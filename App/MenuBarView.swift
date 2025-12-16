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
                if let state = currentState {
                    Text("slot \(state.slotInRound)/\(state.roundSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

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

            Divider()

            // Footer
            footerSection
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            refreshState()
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
            }

            if let payload = round.payload, let shortPayload = round.shortPayload {
                if let url = config.explorerURL(for: payload) {
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
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            HStack(spacing: 6) {
                Text("Round")
                    .frame(width: 40, alignment: .leading)
                Text("Leader")
                    .frame(width: 80, alignment: .leading)
                Text("Signals")
                    .frame(width: 44, alignment: .trailing)
                Text("Status")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

            ForEach(state.pastRounds) { round in
                HStack(spacing: 6) {
                    Text("\(round.roundNumber)")
                        .frame(width: 40, alignment: .leading)

                    if let shortPayload = round.shortPayload {
                        Text(shortPayload)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("-")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }

                    if let signalCount = round.signalCount {
                        Text("\(signalCount)")
                            .foregroundColor(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    } else {
                        Text("-")
                            .foregroundColor(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }

                    statusView(for: round, currentRound: state.currentRound)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private func statusView(for round: RoundData, currentRound: UInt64) -> some View {
        let isPast = round.roundNumber < currentRound

        if !round.hasProposal {
            Text("no proposal")
                .foregroundColor(.secondary)
        } else if round.executed {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("executed")
                    .foregroundColor(.green)
            }
        } else if round.quorumReached {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("passed")
                    .foregroundColor(.green)
            }
        } else if isPast {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("rejected")
                    .foregroundColor(.red)
            }
        } else {
            HStack(spacing: 2) {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("pending")
                    .foregroundColor(.orange)
            }
        }
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

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var config: Config = Config.load()
    @State private var currentState: MonitorState? = MonitorState.load()
    @State private var isRefreshing = false
    @State private var lastError: String?
    private let pollIntervalOptions = [15, 30, 60, 120, 240]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Aztec Governance Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                configSection
                notificationSection
                saveButton
                statusSection
                refreshButton
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            refreshState()
        }
    }

    // MARK: - Configuration Section

    private var configSection: some View {
        GroupBox("Configuration") {
            VStack(alignment: .leading, spacing: 12) {
                configField("RPC Endpoint", text: $config.rpcEndpoint)
                configField("Contract Address", text: $config.contractAddress)
                configField("Instance Address", text: $config.instanceAddress)
                configField("Block Explorer URL", text: $config.explorerBaseURL)

                HStack {
                    Text("Poll Interval:")
                    Picker("", selection: $config.pollIntervalMinutes) {
                        ForEach(pollIntervalOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .frame(width: 100)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func configField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        GroupBox("Notifications") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("New proposal appears", isOn: $config.notifyOnNewProposal)
                Toggle("Quorum reached", isOn: $config.notifyOnQuorumReached)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        GroupBox("Status") {
            VStack(alignment: .leading, spacing: 8) {
                if let state = currentState {
                    HStack {
                        Text("Last fetch:")
                        Text(state.formattedFetchTime)
                            .foregroundColor(.secondary)
                        Text("(block \(state.formattedBlockNumber))")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Round \(state.currentRound)")
                            .font(.headline)
                        Text("Slot \(state.formattedSlotProgress)")
                            .foregroundColor(.secondary)
                    }

                    if let round = state.currentRoundData {
                        if let payload = round.shortPayload {
                            HStack {
                                Text("Proposal:")
                                Link(payload, destination: config.explorerURL(for: round.payload!) ?? URL(string: "https://etherscan.io")!)
                                    .foregroundColor(.blue)
                            }

                            HStack {
                                Text("Signals:")
                                Text("\(round.signalCount ?? 0)/\(state.quorumSize)")
                                if round.quorumReached {
                                    Text("(quorum reached)")
                                        .foregroundColor(.green)
                                }
                            }
                        } else {
                            Text("No proposal yet")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No data yet - press Refresh Now")
                        .foregroundColor(.secondary)
                }

                if let error = lastError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Buttons

    private var saveButton: some View {
        HStack {
            Spacer()
            Button("Save Configuration") {
                saveConfig()
            }
            .disabled(!config.isValid)
            .keyboardShortcut("s", modifiers: .command)
        }
    }

    private var refreshButton: some View {
        HStack {
            Spacer()
            Button("Refresh Now") {
                Task {
                    await refreshNow()
                }
            }
            .disabled(isRefreshing || !config.isValid)
        }
    }

    // MARK: - Actions

    private func saveConfig() {
        config.save()
        BackgroundRefresh.shared.restart()
    }

    private func refreshState() {
        currentState = MonitorState.load()
    }

    @MainActor
    private func refreshNow() async {
        isRefreshing = true
        lastError = nil

        do {
            let ethClient = try EthClient(rpcEndpoint: config.rpcEndpoint)
            var newState = try await ethClient.fetchCurrentState(config: config)

            // Preserve notification tracking from previous state
            if let previous = MonitorState.load() {
                newState.notifiedProposals = previous.notifiedProposals
                newState.notifiedQuorums = previous.notifiedQuorums
            }

            let (events, updatedState) = TransitionDetector.detectEvents(
                previous: currentState,
                current: newState,
                config: config
            )

            // Send notifications
            NotificationManager.shared.sendEvents(events)

            // Save state (this also triggers widget reload)
            updatedState.save()
            currentState = updatedState
        } catch {
            lastError = error.localizedDescription
        }

        isRefreshing = false
    }
}

#Preview {
    ContentView()
}

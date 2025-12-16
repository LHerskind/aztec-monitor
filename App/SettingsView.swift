import SwiftUI

struct SettingsView: View {
    @State private var config: Config = Config.load()
    @State private var isSaved = false
    private let pollIntervalOptions = [5, 15, 30, 60, 120]

    var body: some View {
        Form {
            Section("RPC Configuration") {
                TextField("RPC Endpoint", text: $config.rpcEndpoint)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Contract Addresses") {
                TextField("Governance Proposer", text: $config.governanceProposerAddress)
                    .textFieldStyle(.roundedBorder)

                TextField("Governance", text: $config.governanceAddress)
                    .textFieldStyle(.roundedBorder)

                TextField("Rollup", text: $config.rollupAddress)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Explorer") {
                TextField("Block Explorer URL", text: $config.explorerBaseURL)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Refresh") {
                Picker("Poll Interval", selection: $config.pollIntervalMinutes) {
                    ForEach(pollIntervalOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
            }

            Section("Notifications") {
                Toggle("New proposal appears", isOn: $config.notifyOnNewProposal)
                Toggle("Quorum reached", isOn: $config.notifyOnQuorumReached)
            }

            Section {
                HStack {
                    Spacer()
                    if isSaved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Button("Save") {
                        saveConfig()
                    }
                    .disabled(!config.isValid)
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 480)
        .onChange(of: config) { _, _ in
            isSaved = false
        }
    }

    private func saveConfig() {
        config.save()
        BackgroundRefresh.shared.restart()
        isSaved = true

        // Hide saved indicator after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSaved = false
        }
    }
}

#Preview {
    SettingsView()
}

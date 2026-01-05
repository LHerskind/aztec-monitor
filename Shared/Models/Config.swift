import Foundation
import WidgetKit

struct Config: Codable, Equatable {
    var rpcEndpoint: String
    var governanceProposerAddress: String
    var governanceAddress: String
    var gseAddress: String
    var rollupAddress: String
    var explorerBaseURL: String
    var pollIntervalMinutes: Int
    var notifyOnNewProposal: Bool
    var notifyOnQuorumReached: Bool
    var monitoredProposalIds: [UInt64]
    var maxProposalsToDisplay: Int
    var enableRateLimiting: Bool?
    var requestsPerSecond: Int?

    // MARK: - Shared Storage via App Group UserDefaults

    private static let configKey = "config"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: MonitorState.appGroupID) ?? .standard
    }

    static func load() -> Config {
        guard let data = sharedDefaults.data(forKey: configKey),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return .default
        }
        return config
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }
        Config.sharedDefaults.set(data, forKey: Config.configKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static let `default` = Config(
        rpcEndpoint: "http://localhost:8545",
        governanceProposerAddress: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
        governanceAddress: "0x1102471Eb3378FEE427121c9EfcEa452E4B6B75e",
        gseAddress: "0xa92ecFD0E70c9cd5E5cd76c50Af0F7Da93567a4f",
        rollupAddress: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
        explorerBaseURL: "https://etherscan.io/address/",
        pollIntervalMinutes: 60,
        notifyOnNewProposal: true,
        notifyOnQuorumReached: true,
        monitoredProposalIds: [],
        maxProposalsToDisplay: 5,
        enableRateLimiting: nil,
        requestsPerSecond: nil
    )
    
    var effectiveRequestsPerSecond: Int {
        requestsPerSecond ?? 5
    }
    
    var shouldRateLimit: Bool {
        if let explicit = enableRateLimiting {
            return explicit
        }
        return !rpcEndpoint.contains("localhost") && !rpcEndpoint.contains("127.0.0.1")
    }

    var isValid: Bool {
        !rpcEndpoint.isEmpty &&
        governanceProposerAddress.hasPrefix("0x") && governanceProposerAddress.count == 42 &&
        governanceAddress.hasPrefix("0x") && governanceAddress.count == 42 &&
        gseAddress.hasPrefix("0x") && gseAddress.count == 42 &&
        rollupAddress.hasPrefix("0x") && rollupAddress.count == 42 &&
        !explorerBaseURL.isEmpty &&
        pollIntervalMinutes > 0
    }

    func explorerURL(for address: String) -> URL? {
        URL(string: explorerBaseURL + address)
    }

    var shortGovernanceProposerAddress: String {
        guard governanceProposerAddress.count > 10 else { return governanceProposerAddress }
        return String(governanceProposerAddress.prefix(6)) + "..." + String(governanceProposerAddress.suffix(4))
    }

    var shortGovernanceAddress: String {
        guard governanceAddress.count > 10 else { return governanceAddress }
        return String(governanceAddress.prefix(6)) + "..." + String(governanceAddress.suffix(4))
    }

    var shortGseAddress: String {
        guard gseAddress.count > 10 else { return gseAddress }
        return String(gseAddress.prefix(6)) + "..." + String(gseAddress.suffix(4))
    }

    var shortRollupAddress: String {
        guard rollupAddress.count > 10 else { return rollupAddress }
        return String(rollupAddress.prefix(6)) + "..." + String(rollupAddress.suffix(4))
    }
}

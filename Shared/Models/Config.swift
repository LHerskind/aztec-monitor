import Foundation
import WidgetKit

struct Config: Codable, Equatable {
    var rpcEndpoint: String
    var contractAddress: String
    var instanceAddress: String
    var explorerBaseURL: String
    var pollIntervalMinutes: Int
    var notifyOnNewProposal: Bool
    var notifyOnQuorumReached: Bool

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
        contractAddress: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
        instanceAddress: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
        explorerBaseURL: "https://etherscan.io/address/",
        pollIntervalMinutes: 60,
        notifyOnNewProposal: true,
        notifyOnQuorumReached: true
    )

    var isValid: Bool {
        !rpcEndpoint.isEmpty &&
        contractAddress.hasPrefix("0x") && contractAddress.count == 42 &&
        instanceAddress.hasPrefix("0x") && instanceAddress.count == 42 &&
        !explorerBaseURL.isEmpty &&
        pollIntervalMinutes > 0
    }

    func explorerURL(for address: String) -> URL? {
        URL(string: explorerBaseURL + address)
    }

    var shortContractAddress: String {
        guard contractAddress.count > 10 else { return contractAddress }
        return String(contractAddress.prefix(6)) + "..." + String(contractAddress.suffix(4))
    }

    var shortInstanceAddress: String {
        guard instanceAddress.count > 10 else { return instanceAddress }
        return String(instanceAddress.prefix(6)) + "..." + String(instanceAddress.suffix(4))
    }
}

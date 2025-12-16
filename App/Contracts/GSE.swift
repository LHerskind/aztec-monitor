import Foundation

struct GSE {
    let client: EthClient
    let address: String

    // Function selectors (first 4 bytes of keccak256 hash of function signature)
    private enum Selectors {
        static let bonusInstanceAddress = "0x710ca354"    // BONUS_INSTANCE_ADDRESS()
        static let totalSupply = "0x18160ddd"             // totalSupply()
        static let supplyOf = "0x62400e4c"                // supplyOf(address)
        static let getAttesterCountAtTime = "0xec6e69db"  // getAttesterCountAtTime(address,uint256)
        static let getLatestRollup = "0xb35186a8"         // getLatestRollup()
    }

    // MARK: - Read Methods

    func getBonusInstanceAddress() async throws -> String {
        let result = try await client.call(to: address, data: Selectors.bonusInstanceAddress)
        return ABI.parseAddress(result, byteOffset: 0)
    }

    func getTotalSupply() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.totalSupply)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }

    func getSupplyOf(instance: String) async throws -> Double {
        let calldata = Selectors.supplyOf + ABI.encodeAddress(instance)
        let result = try await client.call(to: address, data: calldata)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }

    func getAttesterCountAtTime(instance: String, timestamp: UInt64) async throws -> UInt64 {
        let calldata = Selectors.getAttesterCountAtTime + ABI.encodeAddress(instance) + ABI.encodeUint256(timestamp)
        let result = try await client.call(to: address, data: calldata)
        return ABI.parseUint256(result)
    }

    func getLatestRollup() async throws -> String {
        let result = try await client.call(to: address, data: Selectors.getLatestRollup)
        return ABI.parseAddress(result, byteOffset: 0)
    }
}

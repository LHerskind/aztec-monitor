import Foundation

struct Rollup {
    let client: EthClient
    let address: String

    // Function selectors (first 4 bytes of keccak256 hash of function signature)
    private enum Selectors {
        static let getCurrentSlot = "0xd8e3784c"  // getCurrentSlot()
    }

    // MARK: - Read Methods

    func getCurrentSlot() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getCurrentSlot)
        return ABI.parseUint256(result)
    }
}

import Foundation

struct Governance {
    let client: EthClient
    let address: String

    // Function selectors (first 4 bytes of keccak256 hash of function signature)
    private enum Selectors {
        static let proposalCount = "0xda35c664"  // proposalCount()
        static let totalPowerNow = "0x7f514e78"  // totalPowerNow()
    }

    // MARK: - Read Methods

    func getProposalCount() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.proposalCount)
        return ABI.parseUint256(result)
    }

    func getTotalPowerNow() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.totalPowerNow)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }
}

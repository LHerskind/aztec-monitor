import Foundation

struct Rollup {
    let client: EthClient
    let address: String

    // Function selectors (first 4 bytes of keccak256 hash of function signature)
    private enum Selectors {
        static let getCurrentSlot = "0xd8e3784c"         // getCurrentSlot()
        static let getPendingBlockNumber = "0x48b9e57b"  // getPendingBlockNumber()
        static let getProvenBlockNumber = "0xb67d057b"   // getProvenBlockNumber()
        static let getTargetCommitteeSize = "0x7de3ca89" // getTargetCommitteeSize()
        static let getBlockReward = "0xf89d4086"         // getBlockReward()
        static let getBlock = "0x04c07569"               // getBlock(uint256)
        static let getEntryQueueLength = "0x1b56a0e7"    // getEntryQueueLength()
        static let getGenesisTime = "0x723d8e96"         // getGenesisTime()
        static let getSlotDuration = "0xc4014c12"        // getSlotDuration()
        static let getActivationThreshold = "0xaa10df4c" // getActivationThreshold()
    }

    // MARK: - Read Methods

    func getCurrentSlot() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getCurrentSlot)
        return ABI.parseUint256(result)
    }

    func getPendingBlockNumber() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getPendingBlockNumber)
        return ABI.parseUint256(result)
    }

    func getProvenBlockNumber() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getProvenBlockNumber)
        return ABI.parseUint256(result)
    }

    func getTargetCommitteeSize() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getTargetCommitteeSize)
        return ABI.parseUint256(result)
    }

    func getBlockReward() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.getBlockReward)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }

    func getBlock(blockNumber: UInt64) async throws -> String {
        let calldata = Selectors.getBlock + ABI.encodeUint256(blockNumber)
        let result = try await client.call(to: address, data: calldata)
        return result  // Raw bytes for now, decode later
    }

    func getEntryQueueLength() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getEntryQueueLength)
        return ABI.parseUint256(result)
    }

    func getGenesisTime() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getGenesisTime)
        return ABI.parseUint256(result)
    }

    func getSlotDuration() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getSlotDuration)
        return ABI.parseUint256(result)
    }

    func getActivationThreshold() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.getActivationThreshold)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }

    /// Parse slot number from block data (at byte offset 160)
    static func parseSlotFromBlockData(_ blockData: String) -> UInt64? {
        let cleaned = blockData.hasPrefix("0x") ? String(blockData.dropFirst(2)) : blockData
        // Slot is at byte offset 160, which is character offset 320 in hex string
        let charOffset = 160 * 2
        guard cleaned.count >= charOffset + 64 else { return nil }

        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slotHex = String(cleaned[startIndex..<endIndex])

        return UInt64(slotHex, radix: 16)
    }
}

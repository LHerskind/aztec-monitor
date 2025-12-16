import Foundation

struct GovernanceProposer {
    let client: EthClient
    let address: String

    // Function selectors (first 4 bytes of keccak256 hash of function signature)
    private enum Selectors {
        static let getCurrentRound = "0xa32bf597"  // getCurrentRound()
        static let getRoundData = "0x16af8be1"     // getRoundData(address,uint256)
        static let signalCount = "0x11739538"      // signalCount(address,uint256,address)
        static let quorumSize = "0x5cb165a0"       // QUORUM_SIZE()
        static let roundSize = "0x54133307"        // ROUND_SIZE()
    }

    // MARK: - Read Methods

    func getCurrentRound() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.getCurrentRound)
        return ABI.parseUint256(result)
    }

    func getRoundData(instance: String, round: UInt64) async throws -> (slot: UInt32, payload: String?, executed: Bool) {
        let calldata = Selectors.getRoundData + ABI.encodeAddress(instance) + ABI.encodeUint256(round)
        let result = try await client.call(to: address, data: calldata)
        return decodeGetRoundData(result)
    }

    func getSignalCount(instance: String, round: UInt64, payload: String) async throws -> UInt64 {
        let calldata = Selectors.signalCount + ABI.encodeAddress(instance) + ABI.encodeUint256(round) + ABI.encodeAddress(payload)
        let result = try await client.call(to: address, data: calldata)
        return ABI.parseUint256(result)
    }

    func getQuorumSize() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.quorumSize)
        return ABI.parseUint256(result)
    }

    func getRoundSize() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.roundSize)
        return ABI.parseUint256(result)
    }

    // MARK: - Response Decoding

    private func decodeGetRoundData(_ hex: String) -> (slot: UInt32, payload: String?, executed: Bool) {
        // Returns: uint32 slotNumber (padded to 32 bytes), address payload (32 bytes), bool executed (32 bytes)
        let slot = ABI.parseUint32(hex, byteOffset: 0)
        let payload = ABI.parseAddress(hex, byteOffset: 32)
        let executed = ABI.parseBool(hex, byteOffset: 64)

        let isZeroAddress = payload.lowercased() == ABI.zeroAddress.lowercased()
        return (slot, isZeroAddress ? nil : payload, executed)
    }
}

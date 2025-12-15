import Foundation

enum ContractCalls {
    // Pre-computed function selectors (first 4 bytes of keccak256 hash of function signature)
    // getCurrentRound()
    static let getCurrentRound = "0xa32bf597"

    // getRoundData(address,uint256)
    static let getRoundData = "0x16af8be1"

    // signalCount(address,uint256,address)
    static let signalCount = "0x11739538"

    // QUORUM_SIZE()
    static let quorumSize = "0x5cb165a0"

    // ROUND_SIZE()
    static let roundSize = "0x54133307"

    // getCurrentSlot() - called on the rollup (instance) contract
    static let getCurrentSlot = "0xd8e3784c"

    static let zeroAddress = "0x0000000000000000000000000000000000000000"

    // MARK: - Encoding

    static func encodeAddress(_ address: String) -> String {
        let cleaned = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
        let padded = String(repeating: "0", count: 64 - cleaned.count) + cleaned.lowercased()
        return padded
    }

    static func encodeUint256(_ value: UInt64) -> String {
        String(format: "%064x", value)
    }

    static func encodeGetRoundData(instance: String, round: UInt64) -> String {
        getRoundData + encodeAddress(instance) + encodeUint256(round)
    }

    static func encodeSignalCount(instance: String, round: UInt64, payload: String) -> String {
        signalCount + encodeAddress(instance) + encodeUint256(round) + encodeAddress(payload)
    }

    // MARK: - Decoding

    static func parseUint256(_ hex: String) -> UInt64 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        // Take only the last 16 hex chars (64 bits) for UInt64
        let truncated = cleaned.count > 16 ? String(cleaned.suffix(16)) : cleaned
        return UInt64(truncated, radix: 16) ?? 0
    }

    static func parseUint32(_ hex: String, byteOffset: Int) -> UInt32 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slice = String(cleaned[startIndex..<endIndex])
        // Take last 8 hex chars for UInt32
        let truncated = slice.count > 8 ? String(slice.suffix(8)) : slice
        return UInt32(truncated, radix: 16) ?? 0
    }

    static func parseAddress(_ hex: String, byteOffset: Int) -> String {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slice = String(cleaned[startIndex..<endIndex])
        // Address is last 20 bytes (40 hex chars) of 32 byte slot
        let address = "0x" + String(slice.suffix(40))
        return address
    }

    static func parseBool(_ hex: String, byteOffset: Int) -> Bool {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slice = String(cleaned[startIndex..<endIndex])
        // Bool is non-zero value
        return slice.contains { $0 != "0" }
    }

    static func decodeGetRoundData(_ hex: String) -> (slot: UInt32, payload: String?, executed: Bool) {
        // Returns: uint32 slotNumber (padded to 32 bytes), address payload (32 bytes), bool executed (32 bytes)
        let slot = parseUint32(hex, byteOffset: 0)
        let payload = parseAddress(hex, byteOffset: 32)
        let executed = parseBool(hex, byteOffset: 64)

        let isZeroAddress = payload.lowercased() == zeroAddress.lowercased()
        return (slot, isZeroAddress ? nil : payload, executed)
    }
}

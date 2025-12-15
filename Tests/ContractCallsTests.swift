import XCTest
@testable import aztec_governance_widget

final class ContractCallsTests: XCTestCase {

    // MARK: - Address Encoding Tests

    func testEncodeAddress_withPrefix() {
        let address = "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12"
        let encoded = ContractCalls.encodeAddress(address)

        XCTAssertEqual(encoded.count, 64, "Encoded address should be 64 hex chars (32 bytes)")
        XCTAssertTrue(encoded.hasSuffix("603bb2c05d474794ea97805e8de69bccfb3bca12"))
        XCTAssertTrue(encoded.hasPrefix("000000000000000000000000")) // 24 zeros (12 bytes padding)
    }

    func testEncodeAddress_withoutPrefix() {
        let address = "603bb2c05D474794ea97805e8De69bCcFb3bCA12"
        let encoded = ContractCalls.encodeAddress(address)

        XCTAssertEqual(encoded.count, 64)
        XCTAssertTrue(encoded.hasSuffix("603bb2c05d474794ea97805e8de69bccfb3bca12"))
    }

    func testEncodeAddress_lowercase() {
        let address = "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
        let encoded = ContractCalls.encodeAddress(address)

        // Should be lowercased
        XCTAssertEqual(encoded, "000000000000000000000000abcdef1234567890abcdef1234567890abcdef12")
    }

    // MARK: - Uint256 Encoding Tests

    func testEncodeUint256_zero() {
        let encoded = ContractCalls.encodeUint256(0)
        XCTAssertEqual(encoded, String(repeating: "0", count: 64))
    }

    func testEncodeUint256_one() {
        let encoded = ContractCalls.encodeUint256(1)
        XCTAssertEqual(encoded, String(repeating: "0", count: 63) + "1")
    }

    func testEncodeUint256_largeNumber() {
        let encoded = ContractCalls.encodeUint256(255)
        XCTAssertEqual(encoded, String(repeating: "0", count: 62) + "ff")
    }

    func testEncodeUint256_roundNumber() {
        let encoded = ContractCalls.encodeUint256(142)
        XCTAssertTrue(encoded.hasSuffix("8e")) // 142 = 0x8e
        XCTAssertEqual(encoded.count, 64)
    }

    // MARK: - GetRoundData Encoding Tests

    func testEncodeGetRoundData() {
        let instance = "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12"
        let round: UInt64 = 5

        let encoded = ContractCalls.encodeGetRoundData(instance: instance, round: round)

        // Should be: selector (10 chars) + address (64 chars) + uint256 (64 chars) = 138 chars
        XCTAssertEqual(encoded.count, 138)
        XCTAssertTrue(encoded.hasPrefix("0x16af8be1")) // getRoundData selector
    }

    // MARK: - SignalCount Encoding Tests

    func testEncodeSignalCount() {
        let instance = "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12"
        let round: UInt64 = 5
        let payload = "0xabc123def456789012345678901234567890abcd"

        let encoded = ContractCalls.encodeSignalCount(instance: instance, round: round, payload: payload)

        // Should be: selector (10 chars) + address (64) + uint256 (64) + address (64) = 202 chars
        XCTAssertEqual(encoded.count, 202)
        XCTAssertTrue(encoded.hasPrefix("0x11739538")) // signalCount selector
    }

    // MARK: - Uint256 Parsing Tests

    func testParseUint256_zero() {
        let hex = "0x0000000000000000000000000000000000000000000000000000000000000000"
        let value = ContractCalls.parseUint256(hex)
        XCTAssertEqual(value, 0)
    }

    func testParseUint256_one() {
        let hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let value = ContractCalls.parseUint256(hex)
        XCTAssertEqual(value, 1)
    }

    func testParseUint256_142() {
        let hex = "0x000000000000000000000000000000000000000000000000000000000000008e"
        let value = ContractCalls.parseUint256(hex)
        XCTAssertEqual(value, 142)
    }

    func testParseUint256_withoutPrefix() {
        let hex = "000000000000000000000000000000000000000000000000000000000000000f"
        let value = ContractCalls.parseUint256(hex)
        XCTAssertEqual(value, 15)
    }

    // MARK: - Address Parsing Tests

    func testParseAddress_atOffset0() {
        // 32 bytes with address in last 20 bytes
        let hex = "0x000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca12"
        let address = ContractCalls.parseAddress(hex, byteOffset: 0)
        XCTAssertEqual(address.lowercased(), "0x603bb2c05d474794ea97805e8de69bccfb3bca12")
    }

    func testParseAddress_atOffset32() {
        // Two 32-byte slots, address in second slot
        let hex = "0x" +
            "0000000000000000000000000000000000000000000000000000000000000001" + // slot 0
            "000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca12"   // slot 1 (address)
        let address = ContractCalls.parseAddress(hex, byteOffset: 32)
        XCTAssertEqual(address.lowercased(), "0x603bb2c05d474794ea97805e8de69bccfb3bca12")
    }

    // MARK: - Bool Parsing Tests

    func testParseBool_false() {
        let hex = "0x0000000000000000000000000000000000000000000000000000000000000000"
        let value = ContractCalls.parseBool(hex, byteOffset: 0)
        XCTAssertFalse(value)
    }

    func testParseBool_true() {
        let hex = "0x0000000000000000000000000000000000000000000000000000000000000001"
        let value = ContractCalls.parseBool(hex, byteOffset: 0)
        XCTAssertTrue(value)
    }

    func testParseBool_nonZeroIsTrue() {
        let hex = "0x00000000000000000000000000000000000000000000000000000000000000ff"
        let value = ContractCalls.parseBool(hex, byteOffset: 0)
        XCTAssertTrue(value)
    }

    // MARK: - Uint32 Parsing Tests

    func testParseUint32_atOffset0() {
        // uint32 is stored in a 32-byte slot, value in last 4 bytes
        let hex = "0x00000000000000000000000000000000000000000000000000000000000000b4" // 180
        let value = ContractCalls.parseUint32(hex, byteOffset: 0)
        XCTAssertEqual(value, 180)
    }

    // MARK: - DecodeGetRoundData Tests

    func testDecodeGetRoundData_withPayload() {
        // Simulated response: slot=180, payload=0x603bb2c05d474794ea97805e8de69bccfb3bca12, executed=false
        let hex = "0x" +
            "00000000000000000000000000000000000000000000000000000000000000b4" + // slot = 180
            "000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca12" + // payload
            "0000000000000000000000000000000000000000000000000000000000000000"   // executed = false

        let (slot, payload, executed) = ContractCalls.decodeGetRoundData(hex)

        XCTAssertEqual(slot, 180)
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.lowercased(), "0x603bb2c05d474794ea97805e8de69bccfb3bca12")
        XCTAssertFalse(executed)
    }

    func testDecodeGetRoundData_noPayload() {
        // Simulated response: slot=90, payload=zero address, executed=false
        let hex = "0x" +
            "000000000000000000000000000000000000000000000000000000000000005a" + // slot = 90
            "0000000000000000000000000000000000000000000000000000000000000000" + // zero address
            "0000000000000000000000000000000000000000000000000000000000000000"   // executed = false

        let (slot, payload, executed) = ContractCalls.decodeGetRoundData(hex)

        XCTAssertEqual(slot, 90)
        XCTAssertNil(payload, "Zero address should be decoded as nil")
        XCTAssertFalse(executed)
    }

    func testDecodeGetRoundData_executed() {
        // Simulated response: slot=60, payload=some address, executed=true
        let hex = "0x" +
            "000000000000000000000000000000000000000000000000000000000000003c" + // slot = 60
            "000000000000000000000000abcdef1234567890abcdef1234567890abcdef12" + // payload
            "0000000000000000000000000000000000000000000000000000000000000001"   // executed = true

        let (slot, payload, executed) = ContractCalls.decodeGetRoundData(hex)

        XCTAssertEqual(slot, 60)
        XCTAssertNotNil(payload)
        XCTAssertTrue(executed)
    }

    // MARK: - Zero Address Tests

    func testZeroAddress() {
        XCTAssertEqual(ContractCalls.zeroAddress, "0x0000000000000000000000000000000000000000")
        XCTAssertEqual(ContractCalls.zeroAddress.count, 42) // 0x + 40 hex chars
    }

    // MARK: - Selector Format Tests

    func testSelectorFormat() {
        // All selectors should be 0x + 8 hex chars = 10 chars total
        XCTAssertEqual(ContractCalls.getCurrentRound.count, 10)
        XCTAssertEqual(ContractCalls.getRoundData.count, 10)
        XCTAssertEqual(ContractCalls.signalCount.count, 10)
        XCTAssertEqual(ContractCalls.quorumSize.count, 10)
        XCTAssertEqual(ContractCalls.roundSize.count, 10)

        XCTAssertTrue(ContractCalls.getCurrentRound.hasPrefix("0x"))
        XCTAssertTrue(ContractCalls.getRoundData.hasPrefix("0x"))
        XCTAssertTrue(ContractCalls.signalCount.hasPrefix("0x"))
        XCTAssertTrue(ContractCalls.quorumSize.hasPrefix("0x"))
        XCTAssertTrue(ContractCalls.roundSize.hasPrefix("0x"))
    }
}

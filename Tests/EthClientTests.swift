import XCTest
@testable import aztec_governance_widget

// MARK: - Mock URL Protocol for testing

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var mockHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?
    nonisolated(unsafe) static var lastRequestBody: [String: Any]?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Capture request body synchronously before async handling
        if let body = request.httpBody {
            MockURLProtocol.lastRequestBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        }

        guard let handler = MockURLProtocol.mockHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock handler set"]))
            return
        }

        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func reset() {
        mockHandler = nil
        lastRequestBody = nil
    }
}

// MARK: - Testable EthClient with injectable session

actor TestableEthClient {
    private let rpcEndpoint: URL
    private let session: URLSession

    init(rpcEndpoint: String, session: URLSession) throws {
        guard let url = URL(string: rpcEndpoint) else {
            throw EthError.invalidURL
        }
        self.rpcEndpoint = url
        self.session = session
    }

    private func jsonRPC(method: String, params: [Any]) async throws -> Any {
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EthError.invalidResponse
        }

        if let error = json["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown error"
            throw EthError.rpcError(message)
        }

        guard let result = json["result"] else {
            throw EthError.invalidResponse
        }

        return result
    }

    func call(to: String, data: String) async throws -> String {
        let callObject: [String: String] = ["to": to, "data": data]
        let params: [Any] = [callObject, "latest"]
        let result = try await jsonRPC(method: "eth_call", params: params)
        guard let hexString = result as? String else {
            throw EthError.invalidResponse
        }
        return hexString
    }

    func getBlockNumber() async throws -> UInt64 {
        let result = try await jsonRPC(method: "eth_blockNumber", params: [])
        guard let hexString = result as? String else {
            throw EthError.invalidResponse
        }
        let cleaned = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
        return UInt64(cleaned, radix: 16) ?? 0
    }

    func getCurrentRound(contract: String) async throws -> UInt64 {
        let result = try await call(to: contract, data: ContractCalls.getCurrentRound)
        return ContractCalls.parseUint256(result)
    }

    func getRoundData(
        contract: String,
        instance: String,
        round: UInt64
    ) async throws -> (slot: UInt32, payload: String?, executed: Bool) {
        let calldata = ContractCalls.encodeGetRoundData(instance: instance, round: round)
        let result = try await call(to: contract, data: calldata)
        return ContractCalls.decodeGetRoundData(result)
    }

    func getSignalCount(
        contract: String,
        instance: String,
        round: UInt64,
        payload: String
    ) async throws -> UInt64 {
        let calldata = ContractCalls.encodeSignalCount(instance: instance, round: round, payload: payload)
        let result = try await call(to: contract, data: calldata)
        return ContractCalls.parseUint256(result)
    }

    func getQuorumSize(contract: String) async throws -> UInt64 {
        let result = try await call(to: contract, data: ContractCalls.quorumSize)
        return ContractCalls.parseUint256(result)
    }

    func getRoundSize(contract: String) async throws -> UInt64 {
        let result = try await call(to: contract, data: ContractCalls.roundSize)
        return ContractCalls.parseUint256(result)
    }
}

// MARK: - EthClient Tests

final class EthClientTests: XCTestCase {

    var session: URLSession!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func mockResponse(_ json: String) {
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (json.data(using: .utf8)!, response)
        }
    }

    // MARK: - Initialization Tests

    func testInit_validURL() throws {
        XCTAssertNoThrow(try EthClient(rpcEndpoint: "http://localhost:8545"))
    }

    func testInit_emptyString() {
        XCTAssertThrowsError(try EthClient(rpcEndpoint: "")) { error in
            XCTAssertTrue(error is EthError)
        }
    }

    // MARK: - Request Format Tests

    func testCall_returnsResult() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x05"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let result = try await client.call(to: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef", data: "0xa32bf597")

        XCTAssertEqual(result, "0x05")
    }

    func testGetBlockNumber_parsesHex() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x10"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let blockNumber = try await client.getBlockNumber()

        XCTAssertEqual(blockNumber, 16)
    }

    func testGetBlockNumber_parsesLargeNumber() async throws {
        // Block 21,000,000 = 0x1406F40
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x1406f40"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let blockNumber = try await client.getBlockNumber()

        XCTAssertEqual(blockNumber, 21_000_000)
    }

    // MARK: - Response Parsing Tests

    func testCall_parsesHexResult() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca12"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let result = try await client.call(to: "0x123", data: "0x456")

        XCTAssertEqual(result, "0x000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca12")
    }

    // MARK: - Error Handling Tests

    func testCall_handlesRPCError() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"error":{"code":-32000,"message":"execution reverted"}}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)

        do {
            _ = try await client.call(to: "0x123", data: "0x456")
            XCTFail("Should have thrown an error")
        } catch let error as EthError {
            if case .rpcError(let message) = error {
                XCTAssertEqual(message, "execution reverted")
            } else {
                XCTFail("Expected rpcError")
            }
        }
    }

    func testCall_handlesInvalidResponse() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)

        do {
            _ = try await client.call(to: "0x123", data: "0x456")
            XCTFail("Should have thrown an error")
        } catch let error as EthError {
            if case .invalidResponse = error {
                // Expected
            } else {
                XCTFail("Expected invalidResponse")
            }
        }
    }

    // MARK: - Contract Method Tests

    func testGetCurrentRound_parsesRoundNumber() async throws {
        // Round 142 = 0x8e
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000008e"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let round = try await client.getCurrentRound(contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef")

        XCTAssertEqual(round, 142)
    }

    func testGetCurrentRound_parsesZero() async throws {
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x0000000000000000000000000000000000000000000000000000000000000000"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let round = try await client.getCurrentRound(contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef")

        XCTAssertEqual(round, 0)
    }

    func testGetQuorumSize_parsesCorrectly() async throws {
        // Quorum size 9
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x0000000000000000000000000000000000000000000000000000000000000009"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let quorum = try await client.getQuorumSize(contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef")

        XCTAssertEqual(quorum, 9)
    }

    func testGetRoundSize_parsesCorrectly() async throws {
        // Round size 180
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x00000000000000000000000000000000000000000000000000000000000000b4"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let roundSize = try await client.getRoundSize(contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef")

        XCTAssertEqual(roundSize, 180)
    }

    func testGetRoundData_decodesAllFields() async throws {
        // slot=180 (0xb4), payload=0x603bb2c05d474794ea97805e8de69bccfb3bca12, executed=false
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x00000000000000000000000000000000000000000000000000000000000000b4000000000000000000000000603bb2c05d474794ea97805e8de69bccfb3bca120000000000000000000000000000000000000000000000000000000000000000"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let (slot, payload, executed) = try await client.getRoundData(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 5
        )

        XCTAssertEqual(slot, 180)
        XCTAssertEqual(payload?.lowercased(), "0x603bb2c05d474794ea97805e8de69bccfb3bca12")
        XCTAssertFalse(executed)
    }

    func testGetRoundData_noPayload() async throws {
        // slot=90, payload=zero address, executed=false
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000005a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let (slot, payload, executed) = try await client.getRoundData(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 1
        )

        XCTAssertEqual(slot, 90)
        XCTAssertNil(payload, "Zero address should decode as nil")
        XCTAssertFalse(executed)
    }

    func testGetRoundData_executed() async throws {
        // slot=60, payload=some address, executed=true
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000003c000000000000000000000000abcdef1234567890abcdef1234567890abcdef120000000000000000000000000000000000000000000000000000000000000001"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let (slot, payload, executed) = try await client.getRoundData(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 10
        )

        XCTAssertEqual(slot, 60)
        XCTAssertNotNil(payload)
        XCTAssertTrue(executed)
    }

    func testGetSignalCount_parsesCorrectly() async throws {
        // Signal count = 7
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x0000000000000000000000000000000000000000000000000000000000000007"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let count = try await client.getSignalCount(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 5,
            payload: "0xabcdef1234567890abcdef1234567890abcdef12"
        )

        XCTAssertEqual(count, 7)
    }

    // MARK: - Real Contract Data Tests
    // These tests use actual responses from the Aztec governance contract

    func testGetCurrentRound_realData() async throws {
        // Real response from getCurrentRound() on contract 0x06Ef1DcF87E419C48B94a331B252819FADbD63ef
        // Round 39 = 0x27
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x0000000000000000000000000000000000000000000000000000000000000027"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let round = try await client.getCurrentRound(contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef")

        XCTAssertEqual(round, 39)
    }

    func testGetRoundData_realData_emptyRound() async throws {
        // Real response from getRoundData(0x603bb2c05D474794ea97805e8De69bCcFb3bCA12, 1)
        // Round 1 has no proposal: slot=0, payload=zero, executed=false
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let (slot, payload, executed) = try await client.getRoundData(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 1
        )

        XCTAssertEqual(slot, 0)
        XCTAssertNil(payload, "Zero address should decode as nil")
        XCTAssertFalse(executed)
    }

    func testGetRoundData_realData_withProposal() async throws {
        // Real response from getRoundData(0x603bb2c05D474794ea97805e8De69bCcFb3bCA12, 39)
        // Round 39: slot=39063 (0x9897), payload=0x05d2a884760f801c1c59369f6fe576132e8ef96c, executed=false
        mockResponse("""
        {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000000000000000000989700000000000000000000000005d2a884760f801c1c59369f6fe576132e8ef96c0000000000000000000000000000000000000000000000000000000000000000"}
        """)

        let client = try TestableEthClient(rpcEndpoint: "http://localhost:8545", session: session)
        let (slot, payload, executed) = try await client.getRoundData(
            contract: "0x06Ef1DcF87E419C48B94a331B252819FADbD63ef",
            instance: "0x603bb2c05D474794ea97805e8De69bCcFb3bCA12",
            round: 39
        )

        XCTAssertEqual(slot, 39063, "Slot should be 0x9897 = 39063")
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.lowercased(), "0x05d2a884760f801c1c59369f6fe576132e8ef96c")
        XCTAssertFalse(executed)
    }
}

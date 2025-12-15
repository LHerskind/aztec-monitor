import Foundation

enum EthError: Error, LocalizedError {
    case invalidURL
    case rpcError(String)
    case invalidResponse
    case networkError(Error)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RPC URL"
        case .rpcError(let message):
            return "RPC Error: \(message)"
        case .invalidResponse:
            return "Invalid response from RPC"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

actor EthClient {
    private let rpcEndpoint: URL
    private let session: URLSession

    init(rpcEndpoint: String) throws {
        guard let url = URL(string: rpcEndpoint) else {
            throw EthError.invalidURL
        }
        self.rpcEndpoint = url
        self.session = URLSession.shared
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
        return parseHexUInt64(hexString)
    }

    private func parseHexUInt64(_ hex: String) -> UInt64 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        return UInt64(cleaned, radix: 16) ?? 0
    }
}

// MARK: - Contract-specific methods

extension EthClient {
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

    func getCurrentSlot(rollup: String) async throws -> UInt64 {
        let result = try await call(to: rollup, data: ContractCalls.getCurrentSlot)
        return ContractCalls.parseUint256(result)
    }

    func fetchCurrentState(config: Config) async throws -> MonitorState {
        let blockNumber = try await getBlockNumber()
        let currentRound = try await getCurrentRound(contract: config.contractAddress)
        let currentSlot = try await getCurrentSlot(rollup: config.instanceAddress)
        let quorumSize = try await getQuorumSize(contract: config.contractAddress)
        let roundSize = try await getRoundSize(contract: config.contractAddress)

        var rounds: [RoundData] = []

        let startRound = currentRound >= 4 ? currentRound - 4 : 0

        for roundNum in stride(from: currentRound, through: startRound, by: -1) {
            let (slot, payload, executed) = try await getRoundData(
                contract: config.contractAddress,
                instance: config.instanceAddress,
                round: roundNum
            )

            var signalCount: UInt64? = nil
            var quorumReached = false

            if let payload = payload {
                signalCount = try await getSignalCount(
                    contract: config.contractAddress,
                    instance: config.instanceAddress,
                    round: roundNum,
                    payload: payload
                )
                quorumReached = signalCount! >= quorumSize
            }

            rounds.append(RoundData(
                roundNumber: roundNum,
                slotNumber: slot,
                payload: payload,
                executed: executed,
                signalCount: signalCount,
                quorumReached: quorumReached
            ))
        }

        return MonitorState(
            currentRound: currentRound,
            currentSlot: currentSlot,
            rounds: rounds,
            quorumSize: quorumSize,
            roundSize: roundSize,
            fetchedAt: Date(),
            blockNumber: blockNumber,
            notifiedProposals: [],
            notifiedQuorums: []
        )
    }
}

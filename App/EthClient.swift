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

// MARK: - ABI Encoding/Decoding Utilities

enum ABI {
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


import Foundation

enum EthError: Error, LocalizedError {
    case invalidURL
    case rpcError(String)
    case invalidResponse(String)
    case httpError(statusCode: Int, body: String?)
    case networkError(Error)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RPC URL"
        case .rpcError(let message):
            return "RPC Error: \(message)"
        case .invalidResponse(let details):
            return "Invalid response from RPC: \(details)"
        case .httpError(let statusCode, let body):
            var message = "HTTP \(statusCode)"
            if statusCode == 429 {
                message += " (Rate Limited)"
            } else if statusCode == 403 {
                message += " (Forbidden)"
            } else if statusCode == 401 {
                message += " (Unauthorized)"
            } else if statusCode >= 500 {
                message += " (Server Error)"
            }
            if let body = body, !body.isEmpty {
                let truncated = body.count > 200 ? String(body.prefix(200)) + "..." : body
                message += " - \(truncated)"
            }
            return message
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

    static func parseUint256AsDouble(_ hex: String, decimals: Int = 18) -> Double {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        // Parse full 256-bit value using Decimal for precision
        guard let value = Double("0x" + cleaned) ?? parseHexToDouble(cleaned) else {
            return 0
        }
        let divisor = pow(10.0, Double(decimals))
        return value / divisor
    }

    private static func parseHexToDouble(_ hex: String) -> Double? {
        // Parse hex string chunk by chunk to handle large numbers
        var result: Double = 0
        let base: Double = 16
        for char in hex {
            guard let digit = Int(String(char), radix: 16) else { return nil }
            result = result * base + Double(digit)
        }
        return result
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
        return slice.contains { $0 != "0" }
    }

    static func parseUint256(_ hex: String, byteOffset: Int) -> UInt64 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        guard cleaned.count >= charOffset + 64 else { return 0 }

        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slice = String(cleaned[startIndex..<endIndex])

        let truncated = slice.count > 16 ? String(slice.suffix(16)) : slice
        return UInt64(truncated, radix: 16) ?? 0
    }

    static func parseUint256AsDouble(_ hex: String, byteOffset: Int, decimals: Int = 18) -> Double {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        guard cleaned.count >= charOffset + 64 else { return 0 }

        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let hexSlice = String(cleaned[startIndex..<endIndex])

        guard let value = parseHexToDouble(hexSlice) else { return 0 }
        let divisor = pow(10.0, Double(decimals))
        return value / divisor
    }

    static func parseUint8(_ hex: String, byteOffset: Int) -> UInt8 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let charOffset = byteOffset * 2
        guard cleaned.count >= charOffset + 64 else { return 0 }

        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: 64)
        let slice = String(cleaned[startIndex..<endIndex])

        let truncated = slice.count > 2 ? String(slice.suffix(2)) : slice
        return UInt8(truncated, radix: 16) ?? 0
    }

    static func parseTimestamp(_ hex: String, byteOffset: Int) -> Date {
        let timestamp = parseUint256(hex, byteOffset: byteOffset)
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    static func parseString(_ hex: String) -> String? {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard cleaned.count >= 128 else { return nil }

        let offset = parseUint256(cleaned, byteOffset: 0)
        let lengthOffset = Int(offset)
        let length = parseUint256(cleaned, byteOffset: lengthOffset)

        guard length > 0, length < 10000 else { return nil }

        let dataOffset = lengthOffset + 32
        let dataCharOffset = dataOffset * 2
        let dataLength = Int(length) * 2

        guard cleaned.count >= dataCharOffset + dataLength else { return nil }

        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: dataCharOffset)
        let endIndex = cleaned.index(startIndex, offsetBy: dataLength)
        let hexData = String(cleaned[startIndex..<endIndex])

        var bytes: [UInt8] = []
        var i = hexData.startIndex
        while i < hexData.endIndex {
            let nextIndex = hexData.index(i, offsetBy: 2, limitedBy: hexData.endIndex) ?? hexData.endIndex
            if let byte = UInt8(hexData[i..<nextIndex], radix: 16) {
                bytes.append(byte)
            }
            i = nextIndex
        }

        return String(bytes: bytes, encoding: .utf8)
    }
}

actor EthClient {
    private let rpcEndpoint: URL
    private let session: URLSession
    private var lastRequestTime: Date = .distantPast
    private let rateLimitEnabled: Bool
    private let minRequestInterval: TimeInterval
    
    init(rpcEndpoint: String, rateLimitEnabled: Bool = false, requestsPerSecond: Int = 5) throws {
        guard let url = URL(string: rpcEndpoint) else {
            throw EthError.invalidURL
        }
        self.rpcEndpoint = url
        self.session = URLSession.shared
        self.rateLimitEnabled = rateLimitEnabled
        self.minRequestInterval = 1.0 / Double(max(1, requestsPerSecond))
    }
    
    private func throttle() async {
        guard rateLimitEnabled else { return }
        
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minRequestInterval {
            let delay = minRequestInterval - elapsed
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
    }

    private func jsonRPC(method: String, params: [Any]) async throws -> Any {
        await throttle()
        
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

        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let bodyString = String(data: data, encoding: .utf8)
            throw EthError.httpError(statusCode: httpResponse.statusCode, body: bodyString)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let bodyPreview = String(data: data, encoding: .utf8) ?? "non-UTF8 data"
            throw EthError.invalidResponse("Failed to parse JSON. Response: \(bodyPreview.prefix(200))")
        }

        if let error = json["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown error"
            let code = error["code"] as? Int
            let fullMessage = code != nil ? "[\(code!)] \(message)" : message
            throw EthError.rpcError(fullMessage)
        }

        guard let result = json["result"] else {
            throw EthError.invalidResponse("Missing 'result' field in response. Keys: \(json.keys.joined(separator: ", "))")
        }

        return result
    }

    func call(to: String, data: String) async throws -> String {
        let callObject: [String: String] = ["to": to, "data": data]
        let params: [Any] = [callObject, "latest"]
        let result = try await jsonRPC(method: "eth_call", params: params)
        guard let hexString = result as? String else {
            throw EthError.invalidResponse("Expected hex string from eth_call, got \(type(of: result))")
        }
        return hexString
    }

    func getBlockNumber() async throws -> UInt64 {
        let result = try await jsonRPC(method: "eth_blockNumber", params: [])
        guard let hexString = result as? String else {
            throw EthError.invalidResponse("Expected hex string from eth_blockNumber, got \(type(of: result))")
        }
        return parseHexUInt64(hexString)
    }

    private func parseHexUInt64(_ hex: String) -> UInt64 {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        return UInt64(cleaned, radix: 16) ?? 0
    }
}


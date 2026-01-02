import Foundation

struct Governance {
    let client: EthClient
    let address: String

    private enum Selectors {
        static let proposalCount = "0xda35c664"
        static let totalPowerNow = "0x7f514e78"
        static let getProposal = "0xc7f758a8"
    }

    private enum PayloadSelectors {
        static let getOriginalPayload = "0xad9c74b5"
        static let getURI = "0x7754305c"
    }

    func getProposalCount() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.proposalCount)
        return ABI.parseUint256(result)
    }

    func getTotalPowerNow() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.totalPowerNow)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }

    func getProposal(proposalId: UInt64) async throws -> ProposalData {
        let calldata = Selectors.getProposal + ABI.encodeUint256(proposalId)
        let result = try await client.call(to: address, data: calldata)
        return decodeProposal(result, proposalId: proposalId)
    }

    private func decodeProposal(_ hex: String, proposalId: UInt64) -> ProposalData {
        let config = ProposalConfiguration(
            votingDelay: TimeInterval(ABI.parseUint256(hex, byteOffset: 0)),
            votingDuration: TimeInterval(ABI.parseUint256(hex, byteOffset: 32)),
            executionDelay: TimeInterval(ABI.parseUint256(hex, byteOffset: 64)),
            gracePeriod: TimeInterval(ABI.parseUint256(hex, byteOffset: 96)),
            quorumPercent: ABI.parseUint256AsDouble(hex, byteOffset: 128, decimals: 18) * 100.0,
            yeaMarginPercent: ABI.parseUint256AsDouble(hex, byteOffset: 160, decimals: 18) * 100.0,
            minimumVotes: ABI.parseUint256AsDouble(hex, byteOffset: 192, decimals: 18)
        )

        let stateRaw = ABI.parseUint8(hex, byteOffset: 224)
        let state = ProposalState(rawValue: stateRaw) ?? .pending

        let payloadAddress = ABI.parseAddress(hex, byteOffset: 256)
        let proposerAddress = ABI.parseAddress(hex, byteOffset: 288)
        let creation = ABI.parseTimestamp(hex, byteOffset: 320)

        let ballot = Ballot(
            yea: ABI.parseUint256AsDouble(hex, byteOffset: 352, decimals: 18),
            nay: ABI.parseUint256AsDouble(hex, byteOffset: 384, decimals: 18)
        )

        return ProposalData(
            proposalId: proposalId,
            state: state,
            config: config,
            payloadAddress: payloadAddress,
            proposerAddress: proposerAddress,
            creation: creation,
            ballot: ballot
        )
    }

    func getPayloadOriginalPayload(payloadAddress: String) async throws -> String? {
        do {
            let result = try await client.call(to: payloadAddress, data: PayloadSelectors.getOriginalPayload)
            let address = ABI.parseAddress(result, byteOffset: 0)
            return address == ABI.zeroAddress ? nil : address
        } catch {
            return nil
        }
    }

    func getPayloadURI(payloadAddress: String) async throws -> String? {
        do {
            let result = try await client.call(to: payloadAddress, data: PayloadSelectors.getURI)
            return ABI.parseString(result)
        } catch {
            return nil
        }
    }
}

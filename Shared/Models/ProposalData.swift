import Foundation
import SwiftUI

// MARK: - Main Proposal Data

struct ProposalData: Codable, Equatable, Identifiable {
    let proposalId: UInt64
    var state: ProposalState
    let config: ProposalConfiguration
    let payloadAddress: String
    let proposerAddress: String
    let creation: Date
    let ballot: Ballot
    var originalPayload: String?
    var uri: String?
    var snapshotPower: Double?

    var id: UInt64 { proposalId }

    var isUriURL: Bool {
        guard let uri = uri else { return false }
        return uri.hasPrefix("http://") || uri.hasPrefix("https://")
    }

    var uriURL: URL? {
        guard isUriURL, let uri = uri else { return nil }
        return URL(string: uri)
    }

    var totalVotes: Double {
        ballot.yea + ballot.nay
    }

    var yeaPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return (ballot.yea / totalVotes) * 100
    }

    var nayPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return (ballot.nay / totalVotes) * 100
    }

    func quorumProgress(totalPower: Double) -> Double {
        guard totalPower > 0 else { return 0 }
        return (totalVotes / totalPower) * 100
    }

    func isQuorumMet(totalPower: Double) -> Bool {
        let requiredVotes = (config.quorumPercent / 100.0) * totalPower
        return totalVotes >= requiredVotes
    }

    func isMarginMet() -> Bool {
        guard totalVotes > 0 else { return false }
        let requiredYeaFraction = (1.0 + config.yeaMarginPercent / 100.0) / 2.0
        let requiredYeaVotes = totalVotes * requiredYeaFraction
        return ballot.yea > requiredYeaVotes
    }

    func requiredYeaPercent() -> Double {
        return (1.0 + config.yeaMarginPercent / 100.0) / 2.0 * 100.0
    }

    func isMinimumPowerMet() -> Bool {
        guard let power = snapshotPower else { return false }
        return power >= config.minimumVotes
    }

    var pendingThrough: Date {
        creation.addingTimeInterval(config.votingDelay)
    }

    var activeThrough: Date {
        pendingThrough.addingTimeInterval(config.votingDuration)
    }

    var queuedThrough: Date {
        activeThrough.addingTimeInterval(config.executionDelay)
    }

    var executableThrough: Date {
        queuedThrough.addingTimeInterval(config.gracePeriod)
    }

    var totalLifecycleDuration: TimeInterval {
        config.votingDelay + config.votingDuration + config.executionDelay + config.gracePeriod
    }

    var nextStateChangeTime: Date? {
        switch state {
        case .pending:
            return pendingThrough
        case .active:
            return activeThrough
        case .queued:
            return queuedThrough
        case .executable:
            return executableThrough
        case .rejected, .executed, .droppable, .dropped, .expired:
            return nil
        }
    }

    func timeRemainingInCurrentPhase(from now: Date = Date()) -> TimeInterval? {
        guard let nextChange = nextStateChangeTime else { return nil }
        let remaining = nextChange.timeIntervalSince(now)
        return remaining > 0 ? remaining : nil
    }

    func formattedTimeRemaining(from now: Date = Date()) -> String? {
        guard let remaining = timeRemainingInCurrentPhase(from: now) else { return nil }
        return formatDuration(remaining)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds >= 86400 {
            let days = Int(seconds / 86400)
            let hours = Int((seconds.truncatingRemainder(dividingBy: 86400)) / 3600)
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        } else if seconds >= 3600 {
            let hours = Int(seconds / 3600)
            let mins = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        } else if seconds >= 60 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else {
            return "\(Int(seconds))s"
        }
    }

    var formattedProposer: String {
        guard proposerAddress.count > 10 else { return proposerAddress }
        return String(proposerAddress.prefix(6)) + "..." + String(proposerAddress.suffix(4))
    }

    var formattedPayload: String {
        guard payloadAddress.count > 10 else { return payloadAddress }
        return String(payloadAddress.prefix(6)) + "..." + String(payloadAddress.suffix(4))
    }

    var formattedTotalVotes: String {
        formatLargeNumber(totalVotes)
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.2fK", value / 1_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Ballot

struct Ballot: Codable, Equatable {
    let yea: Double
    let nay: Double

    var formattedYea: String {
        formatLargeNumber(yea)
    }

    var formattedNay: String {
        formatLargeNumber(nay)
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.2fK", value / 1_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Proposal State

enum ProposalState: UInt8, Codable, Equatable, CaseIterable {
    case pending = 0
    case active = 1
    case queued = 2
    case executable = 3
    case rejected = 4
    case executed = 5
    case droppable = 6
    case dropped = 7
    case expired = 8

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .queued: return "Queued"
        case .executable: return "Executable"
        case .rejected: return "Rejected"
        case .executed: return "Executed"
        case .droppable: return "Droppable"
        case .dropped: return "Dropped"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .active: return .blue
        case .queued: return .purple
        case .executable: return .green
        case .rejected: return .red
        case .executed: return .gray
        case .droppable: return .orange
        case .dropped: return .gray
        case .expired: return .gray
        }
    }

    var isTerminal: Bool {
        switch self {
        case .executed, .dropped, .expired, .rejected:
            return true
        default:
            return false
        }
    }
}

// MARK: - Proposal Configuration

struct ProposalConfiguration: Codable, Equatable {
    let votingDelay: TimeInterval
    let votingDuration: TimeInterval
    let executionDelay: TimeInterval
    let gracePeriod: TimeInterval
    let quorumPercent: Double
    let yeaMarginPercent: Double
    let minimumVotes: Double

    var formattedVotingDelay: String {
        formatDuration(votingDelay)
    }

    var formattedVotingDuration: String {
        formatDuration(votingDuration)
    }

    var formattedExecutionDelay: String {
        formatDuration(executionDelay)
    }

    var formattedGracePeriod: String {
        formatDuration(gracePeriod)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds >= 86400 {
            let days = Int(seconds / 86400)
            return "\(days)d"
        } else if seconds >= 3600 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else if seconds >= 60 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else {
            return "\(Int(seconds))s"
        }
    }
}

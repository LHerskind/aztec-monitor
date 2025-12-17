import Foundation

struct RollupData: Codable, Equatable {
    let pendingBlockNumber: UInt64
    let provenBlockNumber: UInt64
    let targetCommitteeSize: UInt64
    let blockReward: Double
    let entryQueueLength: UInt64

    // Timing data
    let genesisTime: UInt64
    let slotDuration: UInt64
    let recentBlockSlots: [UInt64]  // Slots of recent blocks (newest first)
    let fetchedAt: Date

    // MARK: - Computed Properties

    var unprovenBlocks: UInt64 {
        pendingBlockNumber > provenBlockNumber
            ? pendingBlockNumber - provenBlockNumber
            : 0
    }

    /// Total rewards paid out (proven blocks * block reward)
    var totalRewardsPaid: Double {
        Double(provenBlockNumber) * blockReward
    }

    /// Yearly reward budget
    static let yearlyRewardBudget: Double = 249_000_000

    /// Total rewards as percentage of yearly budget
    var rewardsAsPercentageOfYearlyBudget: Double {
        (totalRewardsPaid / RollupData.yearlyRewardBudget) * 100
    }

    /// Probability of being included in the next committee (as percentage)
    func committeeProbability(totalAttesters: UInt64) -> Double {
        guard totalAttesters > 0 else { return 0 }
        return (Double(targetCommitteeSize) / Double(totalAttesters)) * 100
    }

    /// Calculate timestamp for a given slot
    func timestampForSlot(_ slot: UInt64) -> UInt64 {
        genesisTime + (slot * slotDuration)
    }

    /// Average block time in seconds (based on recent blocks)
    var averageBlockTime: Double? {
        guard recentBlockSlots.count >= 2 else { return nil }

        // Calculate slot differences between consecutive blocks
        var slotDiffs: [UInt64] = []
        for i in 0..<(recentBlockSlots.count - 1) {
            let newerSlot = recentBlockSlots[i]
            let olderSlot = recentBlockSlots[i + 1]
            if newerSlot > olderSlot {
                slotDiffs.append(newerSlot - olderSlot)
            }
        }

        guard !slotDiffs.isEmpty else { return nil }

        let avgSlotDiff = Double(slotDiffs.reduce(0, +)) / Double(slotDiffs.count)
        return avgSlotDiff * Double(slotDuration)
    }

    /// Time since last block in seconds (at time of fetch)
    var timeSinceLastBlock: Double? {
        guard let lastSlot = recentBlockSlots.first else { return nil }
        let lastBlockTime = timestampForSlot(lastSlot)
        let fetchTime = UInt64(fetchedAt.timeIntervalSince1970)
        return Double(fetchTime) - Double(lastBlockTime)
    }

    // MARK: - Formatting

    var formattedBlockReward: String {
        if blockReward >= 1 {
            return String(format: "%.2f", blockReward)
        } else if blockReward >= 0.01 {
            return String(format: "%.4f", blockReward)
        } else {
            return String(format: "%.6f", blockReward)
        }
    }

    var formattedPendingBlockNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: pendingBlockNumber)) ?? String(pendingBlockNumber)
    }

    var formattedProvenBlockNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: provenBlockNumber)) ?? String(provenBlockNumber)
    }

    var formattedTotalRewardsPaid: String {
        if totalRewardsPaid >= 1_000_000 {
            return String(format: "%.2fM", totalRewardsPaid / 1_000_000)
        } else if totalRewardsPaid >= 1_000 {
            return String(format: "%.2fK", totalRewardsPaid / 1_000)
        } else if totalRewardsPaid >= 1 {
            return String(format: "%.2f", totalRewardsPaid)
        } else {
            return String(format: "%.4f", totalRewardsPaid)
        }
    }

    /// Number of blocks used in average calculation
    var blocksInAverage: Int {
        max(0, recentBlockSlots.count - 1)
    }

    var formattedAverageBlockTime: String? {
        guard let avg = averageBlockTime else { return nil }
        if avg >= 60 {
            let minutes = Int(avg) / 60
            let seconds = Int(avg) % 60
            return "\(minutes)m \(seconds)s"
        } else {
            return String(format: "%.1fs", avg)
        }
    }

    var formattedTimeSinceLastBlock: String? {
        guard let elapsed = timeSinceLastBlock else { return nil }
        if elapsed < 0 {
            return "future"
        } else if elapsed >= 3600 {
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            return "\(hours)h \(minutes)m ago"
        } else if elapsed >= 60 {
            let minutes = Int(elapsed) / 60
            let seconds = Int(elapsed) % 60
            return "\(minutes)m \(seconds)s ago"
        } else {
            return String(format: "%.0fs ago", elapsed)
        }
    }
}

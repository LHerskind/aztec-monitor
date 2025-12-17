import Foundation

struct GSEData: Codable, Equatable {
    let totalSupply: Double
    let bonusInstanceAddress: String
    let bonusSupply: Double
    let rollupSupplyRaw: Double  // Raw from contract (direct stake only, excludes bonus)
    let bonusAttesterCount: UInt64
    let rollupAttesterCountRaw: UInt64  // Raw from contract (includes bonus when canonical)
    let rollupIsCanonical: Bool
    let activationThreshold: Double

    // MARK: - Direct Values (excluding bonus)
    // Note: Contract behavior differs between supply and attesters:
    // - supplyOf(rollup) returns ONLY direct stake (excludes bonus)
    // - getAttesterCountAtTime(rollup) returns TOTAL including bonus when canonical

    /// Direct supply staked to rollup (supplyOf already excludes bonus)
    var rollupSupplyDirect: Double {
        return rollupSupplyRaw
    }

    /// Direct attesters staked to rollup (need to subtract bonus when canonical)
    var rollupAttesterCountDirect: UInt64 {
        if rollupIsCanonical {
            return rollupAttesterCountRaw > bonusAttesterCount
                ? rollupAttesterCountRaw - bonusAttesterCount
                : 0
        }
        return rollupAttesterCountRaw
    }

    // MARK: - Effective Values (what the rollup actually has)

    /// Effective supply = direct + bonus (when canonical)
    var rollupSupplyEffective: Double {
        if rollupIsCanonical {
            return rollupSupplyRaw + bonusSupply  // Need to add bonus
        }
        return rollupSupplyRaw  // Not canonical, no bonus
    }

    /// Effective attesters = direct + bonus (when canonical)
    var rollupAttesterCountEffective: UInt64 {
        // Raw already includes bonus when canonical
        return rollupAttesterCountRaw
    }

    // MARK: - Totals

    var totalAttesterCount: UInt64 {
        bonusAttesterCount + rollupAttesterCountDirect
    }

    // MARK: - Percentages

    var bonusSupplyPercentage: Double {
        guard totalSupply > 0 else { return 0 }
        return (bonusSupply / totalSupply) * 100
    }

    var rollupSupplyDirectPercentage: Double {
        guard totalSupply > 0 else { return 0 }
        return (rollupSupplyDirect / totalSupply) * 100
    }

    var rollupSupplyEffectivePercentage: Double {
        guard totalSupply > 0 else { return 0 }
        return (rollupSupplyEffective / totalSupply) * 100
    }

    var bonusAttesterPercentage: Double {
        guard totalAttesterCount > 0 else { return 0 }
        return (Double(bonusAttesterCount) / Double(totalAttesterCount)) * 100
    }

    var rollupAttesterDirectPercentage: Double {
        guard totalAttesterCount > 0 else { return 0 }
        return (Double(rollupAttesterCountDirect) / Double(totalAttesterCount)) * 100
    }

    // MARK: - Formatting

    var formattedTotalSupply: String {
        formatLargeNumber(totalSupply)
    }

    var formattedBonusSupply: String {
        formatLargeNumber(bonusSupply)
    }

    var formattedRollupSupplyDirect: String {
        formatLargeNumber(rollupSupplyDirect)
    }

    var formattedRollupSupplyEffective: String {
        formatLargeNumber(rollupSupplyEffective)
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

    // MARK: - APY

    /// Estimated APY based on yearly rewards distributed across attesters
    /// APY = (yearlyRewards / totalAttesters) / activationThreshold * 100
    var estimatedAPY: Double {
        guard rollupAttesterCountEffective > 0, activationThreshold > 0 else { return 0 }
        let rewardsPerAttester = RollupData.yearlyRewardBudget / Double(rollupAttesterCountEffective)
        return (rewardsPerAttester / activationThreshold) * 100
    }

    var formattedActivationThreshold: String {
        formatLargeNumber(activationThreshold)
    }
}

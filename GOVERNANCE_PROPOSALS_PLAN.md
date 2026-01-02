# Governance Proposals Implementation Plan

## Overview

This document outlines the plan to expand the governance contract wrapper to support fetching and displaying detailed proposal data from the `getProposal(uint256)` function.

## Background

Currently, the `Governance.swift` contract wrapper only supports:
- `proposalCount()` - returns the number of proposals
- `totalPowerNow()` - returns total voting power

We need to add support for `getProposal(uint256)` which returns a complex struct containing:
- Proposal state (Pending, Active, Queued, Executable, Rejected, Executed, Droppable, Dropped, Expired)
- Voting data (yea/nay ballot counts)
- Configuration parameters (quorum, voting delays, grace period, etc.)
- Timing information (creation timestamp, state transition times)
- Metadata (proposer, payload address)

## Solidity Contract Structures

```solidity
struct Proposal {
  ProposalConfiguration config;
  ProposalState cachedState;
  IPayload payload;
  address proposer;
  Timestamp creation;
  Ballot summedBallot;
}

struct Ballot {
  uint256 yea;
  uint256 nay;
}

enum ProposalState {
  Pending,
  Active,
  Queued,
  Executable,
  Rejected,
  Executed,
  Droppable,
  Dropped,
  Expired
}

struct ProposalConfiguration {
  Timestamp votingDelay;
  Timestamp votingDuration;
  Timestamp executionDelay;
  Timestamp gracePeriod;
  uint256 quorum;
  uint256 requiredYeaMargin;
  uint256 minimumVotes;
}
```

## Key Objectives

1. **Fetch and decode proposal data** including state, ballot counts, timestamps, and configuration
2. **Calculate timing** for when the next state transition occurs
3. **Compute voting metrics** like quorum achievement and yea margin
4. **Integrate into the monitoring service** so proposals can be displayed in the UI
5. **Create UI components** to visualize proposal voting with progress bars (similar to signal chart style)

## Configuration Decisions

- **Which proposals to monitor**: Configurable via specific proposal IDs, defaulting to most recent N proposals
- **Timestamp handling**: Convert Solidity `uint256` timestamps to Swift `Date` objects
- **UI location**: New dedicated section in menu bar view (separate from existing governance section)
- **Widgets**: Not a priority (focus on menu bar app)
- **Notifications**: Nice to have, not essential for initial implementation
- **Payload**: Display address only, no need to decode payload data
- **Percentage display**: Either format acceptable (percentages or absolute numbers)

## Implementation Phases

### Phase 1: Core Data Models

**File: `Shared/Models/ProposalData.swift` (NEW)**

Create Swift structs to mirror the Solidity structures:

```swift
import Foundation

// MARK: - Main Proposal Data
struct ProposalData: Codable, Equatable, Identifiable {
    let proposalId: UInt64
    let state: ProposalState
    let config: ProposalConfiguration
    let payload: String  // Address
    let proposer: String  // Address
    let creation: Date
    let ballot: Ballot
    
    var id: UInt64 { proposalId }
    
    // MARK: - Computed Properties
    
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
        let requiredVotes = (config.quorum / 100.0) * totalPower
        return totalVotes >= requiredVotes
    }
    
    func isMarginMet(totalPower: Double) -> Bool {
        let requiredMargin = (config.requiredYeaMargin / 100.0) * totalPower
        return ballot.yea >= requiredMargin
    }
    
    func isMinimumVotesMet() -> Bool {
        return totalVotes >= config.minimumVotes
    }
    
    // Calculate when next state change occurs
    var nextStateChangeTime: Date? {
        switch state {
        case .pending:
            return creation.addingTimeInterval(config.votingDelay)
        case .active:
            return creation.addingTimeInterval(config.votingDelay + config.votingDuration)
        case .queued:
            // Would need additional data to know when queued
            return nil
        case .executable:
            // Would need additional data to know when became executable
            return nil
        default:
            return nil // Terminal states
        }
    }
    
    var formattedProposer: String {
        guard proposer.count > 10 else { return proposer }
        return String(proposer.prefix(6)) + "..." + String(proposer.suffix(4))
    }
    
    var formattedPayload: String {
        guard payload.count > 10 else { return payload }
        return String(payload.prefix(6)) + "..." + String(payload.suffix(4))
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
    let quorum: Double          // Percentage (0-100)
    let requiredYeaMargin: Double  // Percentage (0-100)
    let minimumVotes: Double
}
```

### Phase 2: ABI Decoding Extensions

**File: `App/EthClient.swift` (MODIFY)**

Add these new parsing functions to the `ABI` enum:

```swift
// Parse uint256 at a specific byte offset (for large numbers that fit in UInt64)
static func parseUint256(_ hex: String, byteOffset: Int) -> UInt64 {
    let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
    let charOffset = byteOffset * 2
    guard cleaned.count >= charOffset + 64 else { return 0 }
    
    let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
    let endIndex = cleaned.index(startIndex, offsetBy: 64)
    let slice = String(cleaned[startIndex..<endIndex])
    
    // Take last 16 hex chars for UInt64
    let truncated = slice.count > 16 ? String(slice.suffix(16)) : slice
    return UInt64(truncated, radix: 16) ?? 0
}

// Parse uint256 as Double at a specific byte offset
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

// Parse uint8 (for enums)
static func parseUint8(_ hex: String, byteOffset: Int) -> UInt8 {
    let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
    let charOffset = byteOffset * 2
    guard cleaned.count >= charOffset + 64 else { return 0 }
    
    let startIndex = cleaned.index(cleaned.startIndex, offsetBy: charOffset)
    let endIndex = cleaned.index(startIndex, offsetBy: 64)
    let slice = String(cleaned[startIndex..<endIndex])
    
    // Take last 2 hex chars for UInt8
    let truncated = slice.count > 2 ? String(slice.suffix(2)) : slice
    return UInt8(truncated, radix: 16) ?? 0
}

// Parse timestamp to Date
static func parseTimestamp(_ hex: String, byteOffset: Int) -> Date {
    let timestamp = parseUint256(hex, byteOffset: byteOffset)
    return Date(timeIntervalSince1970: TimeInterval(timestamp))
}
```

### Phase 3: Governance Contract Expansion

**File: `App/Contracts/Governance.swift` (MODIFY)**

Function selector: `0xc7f758a8` for `getProposal(uint256)`

```swift
import Foundation

struct Governance {
    let client: EthClient
    let address: String

    private enum Selectors {
        static let proposalCount = "0xda35c664"
        static let totalPowerNow = "0x7f514e78"
        static let getProposal = "0xc7f758a8"  // NEW
    }

    // MARK: - Existing Methods
    
    func getProposalCount() async throws -> UInt64 {
        let result = try await client.call(to: address, data: Selectors.proposalCount)
        return ABI.parseUint256(result)
    }

    func getTotalPowerNow() async throws -> Double {
        let result = try await client.call(to: address, data: Selectors.totalPowerNow)
        return ABI.parseUint256AsDouble(result, decimals: 18)
    }
    
    // MARK: - New Methods
    
    func getProposal(proposalId: UInt64) async throws -> ProposalData {
        let calldata = Selectors.getProposal + ABI.encodeUint256(proposalId)
        let result = try await client.call(to: address, data: calldata)
        return decodeProposal(result, proposalId: proposalId)
    }
    
    // MARK: - Decoding
    
    private func decodeProposal(_ hex: String, proposalId: UInt64) -> ProposalData {
        // Response structure (each field is 32 bytes):
        // Bytes 0-223:   ProposalConfiguration (7 fields × 32 bytes)
        //   0: votingDelay (uint256)
        //   32: votingDuration (uint256)
        //   64: executionDelay (uint256)
        //   96: gracePeriod (uint256)
        //   128: quorum (uint256)
        //   160: requiredYeaMargin (uint256)
        //   192: minimumVotes (uint256)
        // Byte 224:      ProposalState (uint8 padded to 32 bytes)
        // Byte 256:      IPayload address
        // Byte 288:      proposer address
        // Byte 320:      creation timestamp
        // Bytes 352-383: Ballot (yea, nay)
        //   352: yea (uint256)
        //   384: nay (uint256)
        
        let config = ProposalConfiguration(
            votingDelay: TimeInterval(ABI.parseUint256(hex, byteOffset: 0)),
            votingDuration: TimeInterval(ABI.parseUint256(hex, byteOffset: 32)),
            executionDelay: TimeInterval(ABI.parseUint256(hex, byteOffset: 64)),
            gracePeriod: TimeInterval(ABI.parseUint256(hex, byteOffset: 96)),
            quorum: ABI.parseUint256AsDouble(hex, byteOffset: 128, decimals: 18) * 100.0,  // Convert to percentage
            requiredYeaMargin: ABI.parseUint256AsDouble(hex, byteOffset: 160, decimals: 18) * 100.0,
            minimumVotes: ABI.parseUint256AsDouble(hex, byteOffset: 192, decimals: 18)
        )
        
        let stateRaw = ABI.parseUint8(hex, byteOffset: 224)
        let state = ProposalState(rawValue: stateRaw) ?? .pending
        
        let payload = ABI.parseAddress(hex, byteOffset: 256)
        let proposer = ABI.parseAddress(hex, byteOffset: 288)
        let creation = ABI.parseTimestamp(hex, byteOffset: 320)
        
        let ballot = Ballot(
            yea: ABI.parseUint256AsDouble(hex, byteOffset: 352, decimals: 18),
            nay: ABI.parseUint256AsDouble(hex, byteOffset: 384, decimals: 18)
        )
        
        return ProposalData(
            proposalId: proposalId,
            state: state,
            config: config,
            payload: payload,
            proposer: proposer,
            creation: creation,
            ballot: ballot
        )
    }
}
```

**Note**: All numeric fields use 18 decimals. Quorum and requiredYeaMargin are assumed to be stored as fractions (0.0-1.0) and converted to percentages (0-100) for display.

### Phase 4: Update Data Models

**File: `Shared/Models/GovernanceData.swift` (MODIFY)**

```swift
import Foundation

struct GovernanceData: Codable, Equatable {
    let proposalCount: UInt64
    let totalPower: Double
    let proposals: [ProposalData]  // NEW

    var formattedTotalPower: String {
        formatLargeNumber(totalPower)
    }
    
    // Get active proposals (non-terminal states)
    var activeProposals: [ProposalData] {
        proposals.filter { !$0.state.isTerminal }
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
```

**File: `Shared/Models/Config.swift` (MODIFY)**

Add configuration options:

```swift
struct Config: Codable, Equatable {
    // ... existing fields ...
    
    // NEW: Proposal monitoring configuration
    var monitoredProposalIds: [UInt64]  // Specific proposal IDs to monitor (empty = auto)
    var maxProposalsToDisplay: Int      // Max number of recent proposals to show
    var notifyOnProposalStateChange: Bool
    var notifyOnProposalQuorumReached: Bool
    
    // Update default
    static let `default` = Config(
        // ... existing defaults ...
        monitoredProposalIds: [],
        maxProposalsToDisplay: 5,
        notifyOnProposalStateChange: false,  // Nice to have, default off
        notifyOnProposalQuorumReached: false
    )
}
```

**File: `Shared/Models/MonitorState.swift` (MODIFY)**

Add proposal state tracking:

```swift
struct MonitorState: Codable, Equatable {
    // ... existing fields ...
    
    // NEW: Track proposal states for notifications
    var notifiedProposalStates: [UInt64: ProposalState]
    
    // Update placeholder
    static let placeholder = MonitorState(
        // ... existing placeholders ...
        notifiedProposalStates: [:]
    )
}
```

### Phase 5: Service Integration

**File: `App/MonitorService.swift` (MODIFY)**

Update the `fetchGovernanceData()` method:

```swift
private func fetchGovernanceData() async throws -> GovernanceData {
    let proposalCount = try await governance.getProposalCount()
    let totalPower = try await governance.getTotalPowerNow()
    
    // Determine which proposals to fetch
    let proposalsToFetch = determineProposalsToFetch(proposalCount: proposalCount)
    
    // Fetch proposals in parallel for better performance
    var proposals: [ProposalData] = []
    for proposalId in proposalsToFetch {
        do {
            let proposal = try await governance.getProposal(proposalId: proposalId)
            proposals.append(proposal)
        } catch {
            // Skip proposals that fail to fetch
            print("Failed to fetch proposal \(proposalId): \(error)")
            continue
        }
    }
    
    return GovernanceData(
        proposalCount: proposalCount,
        totalPower: totalPower,
        proposals: proposals
    )
}

private func determineProposalsToFetch(proposalCount: UInt64) -> [UInt64] {
    guard proposalCount > 0 else { return [] }
    
    // If specific IDs are configured, use those
    if !config.monitoredProposalIds.isEmpty {
        return config.monitoredProposalIds.filter { $0 < proposalCount }
    }
    
    // Otherwise, fetch the latest N proposals
    let maxToFetch = min(UInt64(config.maxProposalsToDisplay), proposalCount)
    let startId = proposalCount - maxToFetch
    return Array(startId..<proposalCount).reversed()  // Newest first
}
```

### Phase 6: UI Components

**File: `Shared/Views/ProposalsView.swift` (NEW)**

Create a view similar to `RoundsTableView` with expandable rows showing:
- Proposal ID and state badge
- Horizontal voting bar (green for yea, red for nay, with quorum threshold line)
- Vote counts and quorum indicator
- Expandable details: proposer, payload (with link), creation date, next state change time
- Requirements status: quorum met, margin met, minimum votes met

See detailed implementation in the code section below.

**File: `App/MenuBarView.swift` (MODIFY)**

Add a new section after the Governance Proposer section:

```swift
// Around line 58, after the Governance Proposer section
Divider()

// Section 3: Governance Proposals (NEW)
if let governanceData = currentState?.governanceData,
   !governanceData.proposals.isEmpty {
    VStack(alignment: .leading, spacing: 8) {
        ProposalsView(
            proposals: governanceData.proposals,
            totalPower: governanceData.totalPower,
            config: config
        )
    }
    .frame(width: 640)  // Full width
    
    Divider()
}
```

### Phase 7: Testing & Validation

**File: `Tests/ContractCallsTests.swift` (MODIFY)**

Add test for proposal decoding:

```swift
func testProposalDecoding() async throws {
    // Create mock hex response with known values
    let mockResponse = "0x..." // TODO: Get actual response from contract
    
    let proposal = governance.decodeProposal(mockResponse, proposalId: 0)
    
    XCTAssertEqual(proposal.state, .active)
    XCTAssertGreaterThan(proposal.ballot.yea, 0)
    // Add more assertions based on known data
}
```

## Implementation Checklist

When ready to implement, follow this order:

- [ ] 1. Create `ProposalData.swift` with all models
- [ ] 2. Add ABI parsing functions to `EthClient.swift`
- [ ] 3. Expand `Governance.swift` with `getProposal()` method
- [ ] 4. Test decoding with real contract data (manual verification)
- [ ] 5. Update `GovernanceData.swift` to include proposals array
- [ ] 6. Update `Config.swift` with proposal monitoring options
- [ ] 7. Update `MonitorState.swift` with proposal state tracking
- [ ] 8. Modify `MonitorService.swift` to fetch proposals
- [ ] 9. Create `ProposalsView.swift` UI component
- [ ] 10. Integrate into `MenuBarView.swift`
- [ ] 11. Test end-to-end with real data
- [ ] 12. Polish: formatting, colors, layout adjustments
- [ ] 13. (Optional) Add notifications for state changes

## Key Technical Considerations

### ABI Decoding Complexity

The `getProposal()` function returns a deeply nested struct. The response will be a continuous hex string where:
- First 7 × 32 bytes = `ProposalConfiguration` (7 uint256 fields)
- Next 32 bytes = `ProposalState` (uint8 padded)
- Next 32 bytes = `IPayload` address
- Next 32 bytes = `proposer` address  
- Next 32 bytes = `creation` timestamp
- Next 2 × 32 bytes = `Ballot` struct (yea, nay)

**Total**: 14 × 32 = 448 bytes (896 hex characters + "0x" prefix)

### Testing Strategy

Before integrating with UI, we should test the decoding with known proposal data from the actual governance contract to ensure offsets are correct.

### Questions to Validate During Implementation

1. **Quorum/Margin Format**: Verify if `quorum` and `requiredYeaMargin` are stored as fractions (0.0-1.0) or percentages (0-100) in the contract
2. **ABI Offsets**: Confirm byte offsets are correct by testing with a known proposal from the contract
3. **State Transitions**: Determine if additional contract calls are needed for exact timing of queued→executable transitions

## UI Design

The proposals view will follow existing patterns:
- Similar layout to `RoundsTableView` with historical data display
- Two-color horizontal bars (green/red) like `SignalChartView` for vote visualization
- Expandable rows for detailed information (similar to current round display)
- Color-coded state badges matching the app's design language
- Clickable links to block explorer for proposer and payload addresses

## Future Enhancements (Optional)

- [ ] Notifications for proposal state changes
- [ ] Notifications when quorum reached
- [ ] Desktop widget showing active proposals
- [ ] Historical voting trend charts
- [ ] Estimated time remaining calculations for active votes
- [ ] Filter/search proposals by state or ID

import SwiftUI

struct ProposalsView: View {
    let proposals: [ProposalData]
    let totalPower: Double
    let config: Config?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if proposals.isEmpty {
                Text("No proposals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(proposals) { proposal in
                    ProposalRowView(
                        proposal: proposal,
                        totalPower: totalPower,
                        config: config
                    )
                    if proposal.id != proposals.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct ProposalRowView: View {
    let proposal: ProposalData
    let totalPower: Double
    let config: Config?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerRow
            if let uri = proposal.uri {
                uriRow(uri: uri)
            }
            phaseTimeline
            votesBar
            statusRow

            if isExpanded {
                expandedDetails
            }
        }
        .padding(.vertical, 4)
    }

    private func uriRow(uri: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.caption2)
                .foregroundColor(.secondary)
            if let url = proposal.uriURL {
                Link(destination: url) {
                    HStack(spacing: 2) {
                        Text(uri)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption2)
                    }
                }
            } else {
                Text(uri)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private var headerRow: some View {
        HStack {
            Text("Proposal #\(proposal.proposalId)")
                .font(.caption)
                .fontWeight(.semibold)

            if let config = config, let url = config.explorerURL(for: proposal.payloadAddress) {
                Link(destination: url) {
                    HStack(spacing: 2) {
                        Text(proposal.payloadAddress)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.blue)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption2)
                    }
                }
                .font(.caption2)
            }

            Spacer()

            if let timeRemaining = proposal.formattedTimeRemaining() {
                Text(timeRemaining)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(proposal.state.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(proposal.state.color.opacity(0.2))
                .foregroundColor(proposal.state.color)
                .cornerRadius(4)

            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geometry in
                let totalDuration = proposal.totalLifecycleDuration
                let pendingFrac = proposal.config.votingDelay / totalDuration
                let activeFrac = proposal.config.votingDuration / totalDuration
                let queuedFrac = proposal.config.executionDelay / totalDuration
                let execFrac = proposal.config.gracePeriod / totalDuration

                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        Text("Pending")
                            .frame(width: geometry.size.width * CGFloat(pendingFrac), alignment: .center)
                            .foregroundColor(proposal.state == .pending ? .orange : .secondary)
                        Text("Active")
                            .frame(width: geometry.size.width * CGFloat(activeFrac), alignment: .center)
                            .foregroundColor(proposal.state == .active ? .blue : .secondary)
                        Text("Queued")
                            .frame(width: geometry.size.width * CGFloat(queuedFrac), alignment: .center)
                            .foregroundColor(proposal.state == .queued ? .purple : .secondary)
                        Text("Exec")
                            .frame(width: geometry.size.width * CGFloat(execFrac), alignment: .center)
                            .foregroundColor(proposal.state == .executable ? .green : .secondary)
                    }
                    .font(.system(size: 8))

                    ZStack(alignment: .leading) {
                        HStack(spacing: 1) {
                            PhaseSegment(
                                width: geometry.size.width * CGFloat(pendingFrac),
                                color: .orange,
                                isActive: proposal.state == .pending,
                                isPast: proposal.state != .pending
                            )
                            PhaseSegment(
                                width: geometry.size.width * CGFloat(activeFrac),
                                color: .blue,
                                isActive: proposal.state == .active,
                                isPast: [.queued, .executable, .executed, .rejected, .expired].contains(proposal.state)
                            )
                            PhaseSegment(
                                width: geometry.size.width * CGFloat(queuedFrac),
                                color: .purple,
                                isActive: proposal.state == .queued,
                                isPast: [.executable, .executed, .expired].contains(proposal.state)
                            )
                            PhaseSegment(
                                width: geometry.size.width * CGFloat(execFrac),
                                color: .green,
                                isActive: proposal.state == .executable,
                                isPast: proposal.state == .executed
                            )
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                        if let nowPosition = nowPositionFraction() {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 10)
                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
                                .offset(x: geometry.size.width * CGFloat(nowPosition) - 1)
                        }
                    }
                    .frame(height: 10)

                    HStack(spacing: 0) {
                        Text(formatShortDate(proposal.creation))
                            .frame(width: geometry.size.width * CGFloat(pendingFrac), alignment: .leading)
                        Text(formatShortDate(proposal.pendingThrough))
                            .frame(width: geometry.size.width * CGFloat(activeFrac), alignment: .leading)
                        Text(formatShortDate(proposal.activeThrough))
                            .frame(width: geometry.size.width * CGFloat(queuedFrac), alignment: .leading)
                        Text(formatShortDate(proposal.queuedThrough))
                            .frame(width: geometry.size.width * CGFloat(execFrac), alignment: .leading)
                    }
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
                }
            }
            .frame(height: 32)
        }
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func nowPositionFraction() -> Double? {
        let now = Date()
        let start = proposal.creation
        let end = proposal.executableThrough

        guard now >= start && now <= end else { return nil }

        let elapsed = now.timeIntervalSince(start)
        let total = end.timeIntervalSince(start)

        guard total > 0 else { return nil }
        return elapsed / total
    }

    private var votesBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))

                    if proposal.totalVotes > 0 {
                        let yeaWidth = geometry.size.width * CGFloat(proposal.yeaPercentage / 100.0)
                        let nayWidth = geometry.size.width * CGFloat(proposal.nayPercentage / 100.0)

                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.green)
                                .frame(width: yeaWidth)
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.red)
                                .frame(width: nayWidth)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            .frame(height: 8)

            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Yea: \(proposal.ballot.formattedYea)")
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("Nay: \(proposal.ballot.formattedNay)")
                }

            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            requirementIndicator(
                label: "Quorum",
                met: proposal.isQuorumMet(totalPower: totalPower),
                detail: String(format: "%.1f%% (need %.0f%%)", proposal.quorumProgress(totalPower: totalPower), proposal.config.quorumPercent)
            )
            requirementIndicator(
                label: "Yea",
                met: proposal.isMarginMet(),
                detail: String(format: "%.1f%% (need >%.0f%%)", proposal.yeaPercentage, proposal.requiredYeaPercent())
            )
            requirementIndicator(
                label: "Min Power",
                met: proposal.isMinimumPowerMet(),
                detail: String(format: "%@ (need %@)", formatPower(proposal.snapshotPower ?? 0), formatPower(proposal.config.minimumVotes))
            )
            Spacer()
        }
    }

    private func formatPower(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func requirementIndicator(label: String, met: Bool, detail: String?) -> some View {
        HStack(spacing: 2) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .secondary)
            Text(label)
            if let detail = detail {
                Text("(\(detail))")
            }
        }
        .font(.caption2)
        .foregroundColor(met ? .green : .secondary)
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()

            if let config = config, let url = config.explorerURL(for: proposal.proposerAddress) {
                HStack {
                    Text("Proposer:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Link(destination: url) {
                        HStack(spacing: 2) {
                            Text(proposal.proposerAddress)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption2)
                        }
                    }
                }
                .font(.caption2)
            } else {
                detailRow(label: "Proposer", value: proposal.formattedProposer)
            }

            if let originalPayload = proposal.originalPayload {
                if let config = config, let url = config.explorerURL(for: originalPayload) {
                    HStack {
                        Text("Original Payload:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Link(destination: url) {
                            HStack(spacing: 2) {
                                Text(originalPayload)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundColor(.blue)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                            }
                        }
                    }
                    .font(.caption2)
                } else {
                    detailRow(label: "Original Payload", value: originalPayload)
                }
            }

            Divider()

            Text("Phase Details")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            phaseDetailRow(
                phase: "Pending",
                color: .orange,
                start: proposal.creation,
                end: proposal.pendingThrough,
                isCurrent: proposal.state == .pending
            )
            phaseDetailRow(
                phase: "Active",
                color: .blue,
                start: proposal.pendingThrough,
                end: proposal.activeThrough,
                isCurrent: proposal.state == .active
            )
            phaseDetailRow(
                phase: "Queued",
                color: .purple,
                start: proposal.activeThrough,
                end: proposal.queuedThrough,
                isCurrent: proposal.state == .queued
            )
            phaseDetailRow(
                phase: "Executable",
                color: .green,
                start: proposal.queuedThrough,
                end: proposal.executableThrough,
                isCurrent: proposal.state == .executable
            )
        }
    }

    private func phaseDetailRow(phase: String, color: Color, start: Date, end: Date, isCurrent: Bool) -> some View {
        HStack {
            Circle()
                .fill(color.opacity(isCurrent ? 1.0 : 0.3))
                .frame(width: 6, height: 6)
            Text(phase)
                .fontWeight(isCurrent ? .semibold : .regular)
            Spacer()
            Text("\(formatDate(start)) - \(formatDate(end))")
                .foregroundColor(.secondary)
        }
        .font(.caption2)
        .foregroundColor(isCurrent ? color : .secondary)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PhaseSegment: View {
    let width: CGFloat
    let color: Color
    let isActive: Bool
    let isPast: Bool

    var body: some View {
        Rectangle()
            .fill(segmentColor)
            .frame(width: max(width, 2))
    }

    private var segmentColor: Color {
        if isActive {
            return color
        } else if isPast {
            return color.opacity(0.4)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

#Preview {
    ProposalsView(
        proposals: [
            ProposalData(
                proposalId: 1,
                state: .executable,
                config: ProposalConfiguration(
                    votingDelay: 3600,
                    votingDuration: 86400,
                    executionDelay: 3600,
                    gracePeriod: 86400,
                    quorumPercent: 10.0,
                    yeaMarginPercent: 60.0,
                    minimumVotes: 1000000
                ),
                payloadAddress: "0x1234567890abcdef1234567890abcdef12345678",
                proposerAddress: "0xabcdef1234567890abcdef1234567890abcdef12",
                creation: Date(),
                ballot: Ballot(yea: 2500000, nay: 500000)
            )
        ],
        totalPower: 10000000,
        config: nil
    )
    .padding()
    .frame(width: 400)
}

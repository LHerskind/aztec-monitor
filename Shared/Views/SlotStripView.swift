import SwiftUI

struct SlotStripView: View {
    let blockSlots: [UInt64]  // Slots where blocks were produced
    let currentSlot: UInt64
    let slotCount: Int = 16   // Fixed number of slots to show

    private var slots: [SlotInfo] {
        let blockSet = Set(blockSlots)
        let startSlot = currentSlot >= UInt64(slotCount) ? currentSlot - UInt64(slotCount - 1) : 0
        let latestBlockSlot = blockSlots.first

        return (startSlot...currentSlot).map { slot in
            SlotInfo(
                slot: slot,
                hasBlock: blockSet.contains(slot),
                isLatest: slot == latestBlockSlot
            )
        }
    }

    private var blocksProduced: Int {
        slots.filter { $0.hasBlock }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with summary
            HStack {
                Text("Last \(slotCount) Slots:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(blocksProduced)/\(slotCount) slots")
                    .font(.caption2)
                    .foregroundColor(blocksProduced == slotCount ? .green : .orange)
            }

            // Slot strip with borders
            HStack(spacing: 2) {
                ForEach(slots) { slotInfo in
                    SlotCell(info: slotInfo)
                }
            }
            .padding(2)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            .frame(height: 16)
        }
    }
}

struct SlotInfo: Identifiable {
    let slot: UInt64
    let hasBlock: Bool
    let isLatest: Bool

    var id: UInt64 { slot }
}

struct SlotCell: View {
    let info: SlotInfo

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(minWidth: 6, maxWidth: 16, minHeight: 10)
    }

    private var cellColor: Color {
        if !info.hasBlock {
            return Color.gray.opacity(0.3)
        } else if info.isLatest {
            return Color.green
        } else {
            return Color.blue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // All slots filled
        SlotStripView(
            blockSlots: Array(95...110).map { UInt64($0) },
            currentSlot: 110
        )

        // Some missed slots
        SlotStripView(
            blockSlots: [110, 109, 107, 106, 104, 103, 101, 99, 97],
            currentSlot: 110
        )

        // Very sparse
        SlotStripView(
            blockSlots: [110, 100, 95],
            currentSlot: 110
        )
    }
    .padding()
    .frame(width: 300)
}

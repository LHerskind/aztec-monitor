import SwiftUI
import WidgetKit

struct AztecWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: RoundEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct AztecWidget: Widget {
    let kind: String = "AztecWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AztecWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Aztec Governance")
        .description("Monitor governance round status")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

#Preview(as: .systemMedium) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

#Preview(as: .systemLarge) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

import SwiftUI
import WidgetKit

struct AztecWidget: Widget {
    let kind: String = "AztecWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AztecWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Aztec Governance")
        .description("Monitor governance round status")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AztecWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: RoundEntry

    var body: some View {
        switch widgetFamily {
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemMedium) {
    AztecWidget()
} timeline: {
    RoundEntry.preview
}

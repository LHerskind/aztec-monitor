import SwiftUI
import WidgetKit

struct RollupWidget: Widget {
    let kind: String = "RollupWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RollupWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Aztec Rollup")
        .description("Monitor rollup block production and timing")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    RollupWidget()
} timeline: {
    RoundEntry.preview
}

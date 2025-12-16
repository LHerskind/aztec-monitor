import SwiftUI
import WidgetKit

struct SignalChartWidget: Widget {
    let kind: String = "SignalChartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ChartWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Governance Signals Chart")
        .description("Signal count history for governance rounds")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    SignalChartWidget()
} timeline: {
    RoundEntry.preview
}

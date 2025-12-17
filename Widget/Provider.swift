import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> RoundEntry {
        RoundEntry(date: Date(), state: nil, config: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoundEntry) -> Void) {
        let entry = RoundEntry(date: Date(), state: MonitorState.load(), config: Config.load())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoundEntry>) -> Void) {
        let config = Config.load()
        let state = MonitorState.load()

        var entry = RoundEntry(date: Date(), state: state, config: config)
        entry.debugPath = MonitorState.appGroupID
        entry.stateFileExists = state != nil

        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: config.pollIntervalMinutes,
            to: Date()
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

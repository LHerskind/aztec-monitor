import WidgetKit
import SwiftUI

@main
struct AztecWidgetBundle: WidgetBundle {
    var body: some Widget {
        AztecWidget()
        SignalChartWidget()
    }
}

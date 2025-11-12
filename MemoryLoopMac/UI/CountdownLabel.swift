import SwiftUI
import Combine

struct CountdownLabel: View {
    let toDate: Date
    @State private var now: Date = .init()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(remainingText)
            .monospacedDigit()
            .onReceive(timer) { _ in now = Date() }
    }

    private var remainingText: String {
        let remain = max(0, Int(toDate.timeIntervalSince(now)))
        let h = remain / 3600
        let m = (remain % 3600) / 60
        let s = remain % 60
        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}

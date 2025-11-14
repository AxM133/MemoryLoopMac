import SwiftUI
import Combine

struct CountdownLabelView: View {
    /// Время, когда должно сработать напоминание
    let dueDate: Date
    /// Полная длина этапа в секундах (для правой части "• 1 мин")
    let stageSeconds: Int

    @State private var now: Date = .now

    /// Таймер, который тикает каждую секунду и обновляет `now`
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Сколько секунд осталось до dueDate, не даём уйти в минус
    private var remainingSeconds: Int {
        max(0, Int(dueDate.timeIntervalSince(now)))
    }

    /// Строка "33s" или "1 мин 5s" для оставшегося времени
    private var remainingString: String {
        let sec = remainingSeconds
        if sec >= 60 {
            let m = sec / 60
            let s = sec % 60
            if s > 0 {
                return "\(m) мин \(s)s"
            } else {
                return "\(m) мин"
            }
        } else {
            return "\(sec)s"
        }
    }

    /// Строка для полной длины этапа — "10 сек" или "1 мин"
    private var totalString: String {
        let sec = stageSeconds
        if sec >= 60 {
            let m = sec / 60
            return "\(m) мин"
        } else {
            return "\(sec)s"
        }
    }

    var body: some View {
        Text("\(remainingString) • \(totalString)")
            .monospacedDigit()
            .onReceive(timer) { value in
                now = value
            }
    }
}

#Preview {
    CountdownLabelView(
        dueDate: .now.addingTimeInterval(75),
        stageSeconds: 60
    )
}

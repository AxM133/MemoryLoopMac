import SwiftUI

struct MemoryCardView: View {
    let value: String
    let duration: Int
    let onClose: () -> Void

    @State private var remaining: Int

    init(value: String, duration: Int, onClose: @escaping () -> Void) {
        self.value = value
        self.duration = max(1, duration)
        self.onClose = onClose
        _remaining = State(initialValue: max(1, duration))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Запомни")
                .font(.title2.weight(.semibold))

            Text(value)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .padding(.horizontal, 24)

            Text("Сконцентрируйся \(duration >= 5 ? "5–10 секунд" : "несколько секунд"), затем закрой окно.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if remaining > 0 {
                Text("Окно закроется через \(remaining) сек.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Закрыть") {
                onClose()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 320, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        guard remaining > 0 else { return }

        // простой таймер на секундах
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if remaining <= 1 {
                timer.invalidate()
                onClose()
            } else {
                remaining -= 1
            }
        }
    }
}

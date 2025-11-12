import SwiftUI

struct MemoryCardView: View {
    let memo: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Запомни").font(.title3).opacity(0.7)

            Text(memo)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 8)

            Text("Сконцентрируйся 5–10 секунд, затем закрой окно.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Закрыть") { onClose() }
                .keyboardShortcut(.defaultAction)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(minWidth: 420, idealWidth: 440, maxWidth: 460,
               minHeight: 240, idealHeight: 260, maxHeight: 280)
    }
}

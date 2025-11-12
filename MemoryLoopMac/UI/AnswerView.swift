import SwiftUI

struct AnswerView: View {
    @EnvironmentObject var store: MemoryStore
    let memoryId: String
    let onClose: () -> Void

    @State private var answer: String = ""
    @State private var checked: Bool? = nil
    @State private var expected: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Проверка").font(.headline)

            TextField("Введите ответ…", text: $answer)
                .textFieldStyle(.roundedBorder)
                .disabled(checked != nil)

            HStack {
                Spacer()
                Button(checked == nil ? "Отправить" : "Закрыть") {
                    if checked == nil {
                        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let res = store.evaluate(memoryId: memoryId, answer: trimmed) {
                            checked  = res.correct
                            expected = res.expected
                            NotificationManager.shared.sendResultPush(correct: res.correct, expected: res.expected)
                        } else {
                            onClose()
                        }
                    } else {
                        onClose()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }

            if let ok = checked {
                Divider().padding(.vertical, 2)
                if ok {
                    Text("🎉 Верно!").font(.subheadline).bold()
                } else {
                    HStack(spacing: 6) {
                        Text("Неверно.").font(.subheadline).bold()
                        Text("Правильно: \(expected)").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .frame(minWidth: 360, idealWidth: 380, maxWidth: 400,
               minHeight: 160, idealHeight: 190, maxHeight: 210)
    }
}

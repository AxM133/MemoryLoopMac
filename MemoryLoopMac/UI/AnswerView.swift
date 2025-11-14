import SwiftUI

struct AnswerView: View {
    let memoryId: String

    @EnvironmentObject private var store: MemoryStore
    @EnvironmentObject private var windows: WindowService

    @State private var answer: String = ""
    @State private var isChecking: Bool = false
    @State private var checked: Bool? = nil
    @State private var expected: String = ""
    @State private var userAnswer: String = ""

    // фокус для инпута
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Проверка")
                .font(.title3.weight(.semibold))

            // подсказка сверху
            Text(checked == nil
                 ? "Введи то, что запоминал и нажми Enter."
                 : "Результат проверки:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 1) Режим ввода ответа
            if checked == nil {
                TextField("Ответ…", text: $answer)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFieldFocused)
                    .disabled(isChecking)
                    .onSubmit {
                        handleSubmit()
                    }

                HStack(spacing: 12) {
                    Button("Проверить") {
                        handleSubmit()
                    }
                    .keyboardShortcut(.return)   // Enter
                    .buttonStyle(.borderedProminent)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)

                    Button("Закрыть") {
                        windows.closeAnswerSheet()
                    }
                    .keyboardShortcut(.escape)
                }
            }

            // 2) Режим результата
            if let checked = checked {
                Spacer(minLength: 8)

                VStack(alignment: .center, spacing: 12) {
                    // большой стикер
                    Text(checked ? "🎉" : "❌")
                        .font(.system(size: 60))

                    Text(checked ? "Верно!" : "Неверно")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(checked ? Color.primary : Color.red)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Твой ответ:")
                                .fontWeight(.medium)
                            Text(userAnswer)
                                .font(.body.monospaced())
                        }

                        HStack(spacing: 4) {
                            Text("Нужно было вспомнить:")
                                .fontWeight(.medium)
                            Text(expected)
                                .font(.body.monospaced())
                        }
                    }
                    .font(.subheadline)

                    HStack {
                        Spacer()
                        Button("Закрыть") {
                            windows.closeAnswerSheet()
                        }
                        // второй Enter после результата — закрывает окно
                        .keyboardShortcut(.return)
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 380)
        .onAppear {
            // небольшая задержка, чтобы панель успела появиться, и сразу фокус в поле
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }

    // MARK: - Logic

    /// Обработка Enter / кнопки "Проверить"
    /// 1-й Enter — проверка, показ результата
    /// 2-й Enter (когда checked != nil) — закрытие окна
    private func handleSubmit() {
        // если уже показан результат — закрываем окно
        if checked != nil {
            windows.closeAnswerSheet()
            return
        }

        runCheck()
    }

    /// Проверяет ответ и показывает результат (но не закрывает окно)
    private func runCheck() {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isChecking else { return }

        isChecking = true

        if let res = store.evaluate(memoryId: memoryId, answer: trimmed) {
            checked = res.correct
            expected = res.expected
            userAnswer = res.user
        }

        isChecking = false
        isFieldFocused = false           // убираем фокус с поля, так как оно скрыто
    }
}

import SwiftUI

// Синий стиль для главной кнопки
struct PrimaryBlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.blue))
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: MemoryStore
    @EnvironmentObject var windows: WindowService
    @EnvironmentObject var appState: AppState

    @State private var memoText: String = ""
    @State private var stageIndex: Int = 0
    @State private var historyExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text("Новая карточка").font(.headline).padding(.top, 2)

            // Ряд 1: поле + интервал
            HStack(alignment: .center, spacing: 10) {
                TextField("Слово / число…", text: $memoText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 320, maxWidth: .infinity)

                Picker("Интервал", selection: $stageIndex) {
                    ForEach(0..<store.stages.count, id: \.self) { i in
                        Text(store.stages[i].title).tag(i)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }

            // Ряд 2: главная кнопка (полной ширины)
            Button("Запомнить и напомнить") {
                let v = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !v.isEmpty else { return }
                // Создаём запись и сразу показываем карточку (поверх всех окон)
                store.createMemo(v, atStage: stageIndex)
                windows.showCard(text: v)
                memoText = ""
            }
            .buttonStyle(PrimaryBlueButtonStyle())

            // Ряд 3: вспомогательные кнопки
            HStack(spacing: 8) {
                Button("Случ. число") {
                    let v = String(Int.random(in: 1000...999999))
                    store.createMemo(v, atStage: stageIndex)
                    windows.showCard(text: v)
                }
                Button("Случ. слово") {
                    let words = ["Vector","Lambda","Pixel","Matrix","Neuron","Quasar","Photon","Kernel","Falcon","Echo","Atlas"]
                    let v = words.randomElement() ?? "Vector"
                    store.createMemo(v, atStage: stageIndex)
                    windows.showCard(text: v)
                }
            }
            .buttonStyle(.bordered)

            Divider().padding(.vertical, 4)

            // Настройки
            Text("Настройки").font(.headline)

            HStack(spacing: 12) {
                Text("Сопоставление:")
                Picker("", selection: $store.matchMode) {
                    Text("Точное").tag(MatchMode.strict)
                    Text("Левенштейн").tag(MatchMode.fuzzy)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }

            if store.matchMode == .fuzzy {
                HStack(spacing: 12) {
                    Text("Порог:")
                    Slider(value: Binding(get: { store.fuzzyThreshold },
                                          set: { store.fuzzyThreshold = $0 }),
                           in: 0.6...0.95)
                        .frame(width: 220)
                    Text(String(format: "%.2f", store.fuzzyThreshold))
                        .monospacedDigit()
                        .frame(width: 46, alignment: .trailing)
                }
            }

            Divider().padding(.vertical, 4)

            historySection
        }
        .onChange(of: appState.pendingAnswerMemoryId) { _, new in
            if let id = new {
                WindowService.shared.showAnswer(memoryId: id)
                _ = appState.consumePendingAnswerId()
            }
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Memory Loop").font(.title3).bold()
            Text("Запоминай. Проверяй. Усиливай память.")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    // MARK: История
    private var historySection: some View {
        DisclosureGroup(isExpanded: $historyExpanded) {
            if store.items.isEmpty {
                Text("Пока пусто. Создай карточку выше.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.items) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.memo).bold().lineLimit(1).truncationMode(.tail)
                                HStack(spacing: 6) {
                                    Text("Следующее:").foregroundStyle(.secondary)
                                    CountdownLabel(toDate: item.dueAt).foregroundStyle(.secondary)
                                    Text("• \(store.stages[item.stageIndex].title)")
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .font(.caption)
                            }
                            Spacer(minLength: 8)
                            Text(item.correct == nil ? "—" : (item.correct! ? "✅" : "❌"))
                                .font(.title3)
                                .frame(width: 26)
                        }
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.vertical, 4)
            }
        } label: {
            HStack {
                Text("История").font(.headline)
                Spacer()
                Text(historyExpanded ? "Скрыть" : "Показать")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

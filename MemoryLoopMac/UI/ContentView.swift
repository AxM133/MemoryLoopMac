import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject private var store: MemoryStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var windows: WindowService

    @State private var memoText: String = ""
    @State private var selectedStageIndex: Int = 0
    @State private var historyExpanded: Bool = false

    // тикер для обновления истории раз в секунду
    @State private var timeTick: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            Divider()

            newCardSection

            Divider()

            settingsSection

            Divider()

            historySection
        }
        .onChange(of: appState.pendingAnswerMemoryId) { _, newValue in
            guard let id = newValue else { return }
            DispatchQueue.main.async {
                _ = appState.consumePendingAnswer()
                windows.showAnswerSheet(memoryId: id)
            }
        }
        // глобальный таймер, чтобы история тикала
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            timeTick &+= 1
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Memory Loop")
                .font(.title2.weight(.bold))
            Text("Запоминай. Проверяй. Усиливай память.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var newCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Новая карточка")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Слово / число / факт…", text: $memoText)
                    .textFieldStyle(.roundedBorder)

                Picker("Интервал", selection: $selectedStageIndex) {
                    ForEach(store.stages.indices, id: \.self) { i in
                        Text(store.stages[i].title).tag(i)
                    }
                }
                .frame(width: 90)
            }

            HStack(spacing: 8) {
                Button("Случ. число") {
                    memoText = String(Int.random(in: 10...999_999))
                }

                Button("Случ. слово") {
                    memoText = ["orbit", "memory", "focus", "neuron", "vector"].randomElement() ?? "memory"
                }

                Spacer()

                Button("Запомнить и напомнить") {
                    startMemorize()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Сопоставление:")
                    .font(.subheadline)

                HStack {
                    Picker("", selection: $store.matchMode) {
                        Text("Точное").tag(MatchMode.strict)
                        Text("Левенштейн").tag(MatchMode.fuzzy)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)

                    Spacer()
                }
            }

            if store.matchMode == .fuzzy {
                HStack {
                    Text("Порог:")
                        .font(.subheadline)
                    Slider(value: $store.fuzzyThreshold, in: 0.5...0.95)
                    Text(String(format: "%.2f", store.fuzzyThreshold))
                        .font(.caption)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Toggle(isOn: $store.autoCycleDefault) {
                Text("Увеличивать интервал и повторять до 3 успешных попыток")
            }
            .toggleStyle(.switch)
            .font(.subheadline)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("История")
                    .font(.headline)
                Spacer()
            }

            DisclosureGroup(isExpanded: $historyExpanded) {
                if store.items.isEmpty {
                    Text("Пока нет карточек.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.items) { item in
                            historyRow(for: item, tick: timeTick)
                                .id(item.id)
                        }
                    }
                    .padding(.top, 6)
                }
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("История")
                        .font(.subheadline)
                    Spacer()
                    Text(historyExpanded ? "Скрыть" : "Показать")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - History row

    private func historyRow(for item: MemoryItem, tick: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.memo)
                    .font(.body)

                let due = item.dueAt
                if let stage = store.stages[safe: item.stageIndex] {

                    let secondsLeft = max(0, Int(due.timeIntervalSince(Date())))
                    let total = stage.seconds

                    HStack(spacing: 4) {
                        Text("Следующее:")
                        Text("\(secondsLeft)s • \(total >= 60 ? "\(total / 60) мин" : "\(total)s")")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            statusIcon(for: item)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    @ViewBuilder
    private func statusIcon(for item: MemoryItem) -> some View {
        if item.isFinished {
            if item.correct == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        } else {
            Image(systemName: "minus.circle")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func startMemorize() {
        let trimmed = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let stageIndex = max(0, min(selectedStageIndex, store.stages.count - 1))
        let duration = store.stages[stageIndex].seconds

        store.createMemo(trimmed, atStage: stageIndex, autoCycle: store.autoCycleDefault)
        windows.showMemorizeCard(text: trimmed, duration: duration)

        memoText = ""
    }
}

// MARK: - Safe index helper

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        (indices.contains(index)) ? self[index] : nil
    }
}

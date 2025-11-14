import Foundation
import Combine

@MainActor
final class MemoryStore: ObservableObject {

    static let shared = MemoryStore()

    @Published private(set) var items: [MemoryItem] = []

    @Published var stages: [SRSStage] = [
        .init(title: "10 сек", seconds: 10),
        .init(title: "1 мин", seconds: 60),
        .init(title: "10 мин", seconds: 600)
    ]

    @Published var matchMode: MatchMode = .fuzzy
    @Published var fuzzyThreshold: Double = 0.82

    @Published var autoCycleDefault: Bool = true

    private let storageKey  = "memory_items_store_v1"
    private let settingsKey = "memory_settings_store_v1"

    private init() {
        load()
    }

    // MARK: - Создание

    func createMemo(_ memo: String, atStage index: Int, autoCycle: Bool? = nil) {
        let idx = max(0, min(index, stages.count - 1))
        let now = Date()
        let due = now.addingTimeInterval(TimeInterval(stages[idx].seconds))
        let id  = UUID().uuidString
        let auto = autoCycle ?? autoCycleDefault

        let item = MemoryItem(
            id: id,
            memo: memo,
            createdAt: now,
            stageIndex: idx,
            dueAt: due,
            answeredAt: nil,
            userAnswer: nil,
            correct: nil,
            autoCycle: auto,
            correctStreak: 0,
            wrongCount: 0,
            isFinished: !auto
        )

        items.insert(item, at: 0)
        save()

        Task {
            await NotificationManager.shared.removeAll(for: id)
            await NotificationManager.shared.scheduleReminder(memoryId: id, dueAt: due)
        }
    }

    // MARK: - Оценка ответа

    @discardableResult
    func evaluate(memoryId: String, answer: String)
    -> (correct: Bool, expected: String, user: String)? {

        guard let idx = items.firstIndex(where: { $0.id == memoryId }) else { return nil }

        var item = items[idx]
        let expected = item.memo
        let ok = isCorrect(answer: answer, expected: expected)

        item.answeredAt = Date()
        item.userAnswer = answer
        item.correct    = ok

        if item.autoCycle {
            if ok {
                item.correctStreak += 1
            } else {
                item.wrongCount += 1
                item.correctStreak = 0
            }

            if item.correctStreak >= 3 {
                item.isFinished = true
            }

            if item.wrongCount >= 2 {
                item.isFinished = true
                item.correct = false
            }

            if !item.isFinished {
                item.stageIndex = min(item.stageIndex + 1, stages.count - 1)
                item.dueAt = Date().addingTimeInterval(
                    TimeInterval(stages[item.stageIndex].seconds)
                )
            }
        } else {
            item.isFinished = true
        }

        items[idx] = item
        save()

        Task {
            await NotificationManager.shared.removeAll(for: item.id)

            if !item.isFinished {
                await NotificationManager.shared.scheduleReminder(
                    memoryId: item.id,
                    dueAt: item.dueAt
                )
            }
        }

        return (ok, expected, answer)
    }

    // MARK: - Сопоставление

    private func isCorrect(answer a: String, expected b: String) -> Bool {
        let notDigits = CharacterSet.decimalDigits.inverted
        if a.rangeOfCharacter(from: notDigits) == nil &&
            b.rangeOfCharacter(from: notDigits) == nil {

            return a.trimmingCharacters(in: .whitespacesAndNewlines) ==
                   b.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        switch matchMode {
        case .strict:
            return Fuzzy.normalized(a) == Fuzzy.normalized(b)
        case .fuzzy:
            return Fuzzy.similar(a, b, threshold: fuzzyThreshold)
        }
    }

    // MARK: - Сохранение / загрузка

    private struct SettingsBlob: Codable {
        var stages: [SRSStage]
        var mode: MatchMode
        var thr: Double
        var auto: Bool
    }

    private func save() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601

        if let data = try? enc.encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }

        let blob = SettingsBlob(
            stages: stages,
            mode: matchMode,
            thr: fuzzyThreshold,
            auto: autoCycleDefault
        )

        if let data = try? enc.encode(blob) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func load() {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let arr = try? dec.decode([MemoryItem].self, from: data) {
            items = arr
        }

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let blob = try? dec.decode(SettingsBlob.self, from: data) {
            stages = blob.stages
            matchMode = blob.mode
            fuzzyThreshold = blob.thr
            autoCycleDefault = blob.auto
        }
    }
}

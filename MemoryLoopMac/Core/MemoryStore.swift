import Foundation
import Combine

@MainActor
final class MemoryStore: ObservableObject {
    static let shared = MemoryStore()

    @Published private(set) var items: [MemoryItem] = []
    @Published var stages: [SRSStage] = [
        .init(title: "10 сек", seconds: 10),
        .init(title: "1 мин",  seconds: 60),
        .init(title: "10 мин", seconds: 600),
        .init(title: "1 час",  seconds: 3600),
        .init(title: "1 день", seconds: 86400)
    ]
    @Published var matchMode: MatchMode = .fuzzy
    @Published var fuzzyThreshold: Double = 0.82

    private let storageKey  = "memory_items_v2"
    private let settingsKey = "memory_settings_v2"

    private init() { load() }

    // Создание карточки
    func createMemo(_ memo: String, atStage index: Int) {
        let idx = max(0, min(index, stages.count - 1))
        let id  = UUID().uuidString
        let now = Date()
        let due = now.addingTimeInterval(TimeInterval(stages[idx].seconds))

        let item = MemoryItem(
            id: id, memo: memo, createdAt: now,
            stageIndex: idx, dueAt: due,
            answeredAt: nil, userAnswer: nil, correct: nil
        )
        items.insert(item, at: 0)
        save()

        Task {
            // На всякий случай чистим и pending, и delivered (хотя для нового id их нет)
            await NotificationManager.shared.removeAll(for: id)
            try? await NotificationManager.shared.scheduleReminder(memoryId: id, dueAt: due)
        }
    }

    /// Проверка ответа и пересчёт следующей ступени. Возвращает результат для UI/пуша.
    @discardableResult
    func evaluate(memoryId: String, answer: String) -> (correct: Bool, expected: String)? {
        guard let i = items.firstIndex(where: { $0.id == memoryId }) else { return nil }
        let expected = items[i].memo
        let ok = isCorrect(answer: answer, expected: expected)

        var m = items[i]
        m.answeredAt = Date()
        m.userAnswer = answer
        m.correct    = ok

        // Движение по стадиям
        if ok {
            m.stageIndex = min(m.stageIndex + 1, stages.count - 1)
        } else {
            m.stageIndex = max(m.stageIndex - 1, 0)
        }
        m.dueAt = Date().addingTimeInterval(TimeInterval(stages[m.stageIndex].seconds))
        items[i] = m
        save()

        // Полная очистка старых уведомлений + назначение ровно одного нового
        Task {
            await NotificationManager.shared.removeAll(for: m.id)
            try? await NotificationManager.shared.scheduleReminder(memoryId: m.id, dueAt: m.dueAt)
        }

        return (ok, expected)
    }

    // MARK: - helpers

    private func isCorrect(answer a: String, expected b: String) -> Bool {
        // Числа сравниваем строго как строки из цифр
        let notDigits = CharacterSet.decimalDigits.inverted
        if a.rangeOfCharacter(from: notDigits) == nil && b.rangeOfCharacter(from: notDigits) == nil {
            return a.trimmingCharacters(in: .whitespacesAndNewlines) ==
                   b.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Иначе режимы strict/fuzzy
        switch matchMode {
        case .strict:
            return Fuzzy.normalized(a) == Fuzzy.normalized(b)
        case .fuzzy:
            return Fuzzy.similar(a, b, threshold: fuzzyThreshold)
        }
    }

    private func save() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        let settings = SettingsBlob(stages: stages, mode: matchMode, thr: fuzzyThreshold)
        if let data = try? enc.encode(settings) {
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
           let s = try? dec.decode(SettingsBlob.self, from: data) {
            stages = s.stages
            matchMode = s.mode
            fuzzyThreshold = s.thr
        }
    }

    private struct SettingsBlob: Codable {
        let stages: [SRSStage]
        let mode: MatchMode
        let thr: Double
    }
}

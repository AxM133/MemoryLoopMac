import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    private static let categoryId   = "MEMORY_REMINDER"
    private static let actionAnswer = "ANSWER_TEXT"
    private func requestId(for memoryId: String) -> String { "rem-\(memoryId)" }

    func registerCategories() {
        let answer = UNTextInputNotificationAction(
            identifier: Self.actionAnswer,
            title: "Ответить",
            options: [.authenticationRequired],
            textInputButtonTitle: "Отправить",
            textInputPlaceholder: "Введите значение"
        )
        let cat = UNNotificationCategory(
            identifier: Self.categoryId,
            actions: [answer],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Удалить pending + delivered по memoryId
    func removeAll(for memoryId: String) async {
        let center = UNUserNotificationCenter.current()
        let prefix = requestId(for: memoryId)

        let pending = await center.pendingNotificationRequests()
        let pIDs = pending.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
        if !pIDs.isEmpty { center.removePendingNotificationRequests(withIdentifiers: pIDs) }

        let delivered = await withCheckedContinuation { (cont: CheckedContinuation<[UNNotification], Never>) in
            center.getDeliveredNotifications { cont.resume(returning: $0) }
        }
        let dIDs = delivered.map { $0.request }.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
        if !dIDs.isEmpty { center.removeDeliveredNotifications(withIdentifiers: dIDs) }
    }

    func scheduleReminder(memoryId: String, dueAt: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Memory Loop"
        content.body  = "Пора проверить память. Введите значение."
        content.sound = .default
        content.categoryIdentifier = Self.categoryId
        content.userInfo = ["memoryId": memoryId]

        let identifier = requestId(for: memoryId) + "-\(Int(dueAt.timeIntervalSince1970))"
        let sec = max(5, dueAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: sec, repeats: false)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }

    func sendResultPush(correct: Bool, expected: String) {
        let content = UNMutableNotificationContent()
        content.title = correct ? "Верно 🎉" : "Ошибка"
        content.body  = correct ? "Ты вспомнил правильно." : "Правильное значение: \(expected)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let req = UNNotificationRequest(identifier: "result-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func handleResponse(_ response: UNNotificationResponse) {
        guard let id = response.notification.request.content.userInfo["memoryId"] as? String else { return }
        switch response.actionIdentifier {
        case Self.actionAnswer:
            if let r = response as? UNTextInputNotificationResponse {
                let ans = r.userText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let res = MemoryStore.shared.evaluate(memoryId: id, answer: ans) {
                    sendResultPush(correct: res.correct, expected: res.expected)
                }
            }
        case UNNotificationDefaultActionIdentifier:
            WindowService.shared.showAnswer(memoryId: id)
        default:
            break
        }
    }
}

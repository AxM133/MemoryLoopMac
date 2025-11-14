import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()
    private override init() {
        super.init()
    }

    // идентификаторы
    private static let categoryId      = "MEMORY_REMINDER"
    private static let actionAnswerId  = "ANSWER_TEXT"
    private static let userInfoKeyId   = "memoryId"

    // MARK: - Регистрация

    func registerCategories() {
        let answer = UNTextInputNotificationAction(
            identifier: Self.actionAnswerId,
            title: "Ответить",
            options: [.authenticationRequired],
            textInputButtonTitle: "Отправить",
            textInputPlaceholder: "Введите значение"
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryId,
            actions: [answer],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    // MARK: - Планирование напоминания

    func scheduleReminder(memoryId: String, dueAt: Date) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Memory Loop"
        content.body  = "Что ты запоминал?"
        content.categoryIdentifier = Self.categoryId
        content.userInfo = [Self.userInfoKeyId: memoryId]

        let interval = max(1, dueAt.timeIntervalSinceNow)
        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        let request = UNNotificationRequest(
            identifier: "mem-\(memoryId)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("scheduleReminder error: \(error)")
        }
    }

    /// Удалить все pending/delivered уведомления для конкретного memoryId
    func removeAll(for memoryId: String) async {
        let center = UNUserNotificationCenter.current()

        // pending
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending
            .filter { $0.content.userInfo[Self.userInfoKeyId] as? String == memoryId }
            .map { $0.identifier }

        if !pendingIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        }

        // delivered
        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered
            .filter { $0.request.content.userInfo[Self.userInfoKeyId] as? String == memoryId }
            .map { $0.request.identifier }

        if !deliveredIds.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
        }
    }

    // пуш с результатом (опционально)
    func sendResultPush(correct: Bool, expected: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = correct ? "Верно" : "Почти"
        content.body  = correct
            ? "Ты правильно вспомнил: \(expected)"
            : "Правильный ответ: \(expected)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "result-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request, withCompletionHandler: nil)
    }

    // MARK: - Обработка ответа на уведомление

    func handleResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let id = userInfo[Self.userInfoKeyId] as? String else { return }

        switch response.actionIdentifier {

        // Пользователь нажал кнопку "Ответить" прямо в баннере
        case Self.actionAnswerId:
            if let textResp = response as? UNTextInputNotificationResponse {
                let answer = textResp.userText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !answer.isEmpty else { return }

                if let res = MemoryStore.shared.evaluate(memoryId: id, answer: answer) {
                    sendResultPush(correct: res.correct, expected: res.expected)
                }
            }

        // Пользователь просто нажал по уведомлению (открыть)
        case UNNotificationDefaultActionIdentifier:
            // СРАЗУ открываем окно проверки
            Task { @MainActor in
                WindowService.shared.showAnswerSheet(memoryId: id)
            }

        default:
            break
        }
    }
}

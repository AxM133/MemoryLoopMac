import SwiftUI
import AppKit
import Combine

@MainActor
final class WindowService: ObservableObject {
    static let shared = WindowService()
    private init() {}

    private var cardWindow: NSWindow?
    private var answerWindow: NSWindow?

    // MARK: - Card

    func showCard(text: String) {
        closeCard()

        // Контент
        let root = MemoryCardView(memo: text) { [weak self] in self?.closeCard() }
            .environmentObject(MemoryStore.shared)
            .environmentObject(AppState.shared)

        let host = NSHostingController(rootView: root)

        // Окно
        let panel = NSPanel(contentViewController: host)
        panel.title = "Запомни"
        panel.styleMask = [.titled, .closable, .hudWindow, .utilityWindow]
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        panel.setFrame(NSRect(x: 0, y: 0, width: 520, height: 340), display: true)
        panel.center()

        // ВАЖНО: активируем приложение и поднимаем окно наверх
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        cardWindow = panel
    }

    func closeCard() {
        cardWindow?.close()
        cardWindow = nil
    }

    // MARK: - Answer

    func showAnswer(memoryId: String) {
        // Чтобы не всплывали две панели: карточку закрываем
        closeCard()
        closeAnswer()

        let root = AnswerView(memoryId: memoryId) { [weak self] in self?.closeAnswer() }
            .environmentObject(MemoryStore.shared)
            .environmentObject(AppState.shared)

        let host = NSHostingController(rootView: root)

        let panel = NSPanel(contentViewController: host)
        panel.title = "Проверка"
        panel.styleMask = [.titled, .closable, .hudWindow, .utilityWindow]
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        panel.setFrame(NSRect(x: 0, y: 0, width: 460, height: 260), display: true)
        panel.center()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        answerWindow = panel
    }

    func closeAnswer() {
        answerWindow?.close()
        answerWindow = nil
    }
}

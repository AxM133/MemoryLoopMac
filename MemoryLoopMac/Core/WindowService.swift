import SwiftUI
import AppKit
import Combine

@MainActor
final class WindowService: ObservableObject {

    static let shared = WindowService()
    private init() {}

    // Окна
    private var memorizeWindow: NSWindow?
    private var answerWindow: NSWindow?

    // MARK: - MemorizeCard (окно для запоминания)

    func showMemorizeCard(text: String, duration: Int) {
        closeMemorizeCard()

        let root = MemoryCardView(value: text, duration: duration) {
            self.closeMemorizeCard()
        }
        let host = NSHostingController(rootView: root)

        // размер окна
        let width: CGFloat = 300
        let height: CGFloat = 300
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        // создаём панель
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = host
        panel.title = "Запомни"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]   // без .canJoinAllSpaces

        // позиция — нижний левый угол
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let x = frame.minX + 20
            let y = frame.minY + 20
            panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        memorizeWindow = panel
    }

    func closeMemorizeCard() {
        memorizeWindow?.orderOut(nil)
        memorizeWindow = nil
    }

    // MARK: - Answer Sheet (окно проверки)

    func showAnswerSheet(memoryId: String) {
        closeMemorizeCard()
        closeAnswerSheet()

        // ВАЖНО: сюда прокидываем MemoryStore.shared и WindowService
        let root = AnswerView(memoryId: memoryId)
            .environmentObject(MemoryStore.shared)
            .environmentObject(self)

        let host = NSHostingController(rootView: root)

        let width: CGFloat = 360
        let height: CGFloat = 300
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = host
        panel.title = "Проверка"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]   // тоже без .canJoinAllSpaces

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        answerWindow = panel
    }

    func closeAnswerSheet() {
        answerWindow?.orderOut(nil)
        answerWindow = nil
    }
}

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var pendingAnswerMemoryId: String? = nil

    func setPendingAnswer(id: String) {
        pendingAnswerMemoryId = id
    }

    @discardableResult
    func consumePendingAnswer() -> String? {
        let v = pendingAnswerMemoryId
        pendingAnswerMemoryId = nil
        return v
    }
}

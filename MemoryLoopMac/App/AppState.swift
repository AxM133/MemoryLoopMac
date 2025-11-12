import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    private init() {}

    @Published var pendingAnswerMemoryId: String? = nil

    func openAnswer(for memoryId: String) { pendingAnswerMemoryId = memoryId }
    func consumePendingAnswerId() -> String? {
        defer { pendingAnswerMemoryId = nil }
        return pendingAnswerMemoryId
    }
}

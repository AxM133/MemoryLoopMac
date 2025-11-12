import Foundation

struct MemoryItem: Identifiable, Codable, Equatable {
    let id: String
    let memo: String
    let createdAt: Date
    var stageIndex: Int            // индекс в расписании SRS
    var dueAt: Date
    var answeredAt: Date?
    var userAnswer: String?
    var correct: Bool?
}

struct SRSStage: Codable, Equatable {
    let title: String
    let seconds: Int
}

enum MatchMode: String, Codable {
    case strict, fuzzy
}

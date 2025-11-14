import Foundation

struct SRSStage: Codable, Hashable {
    var title: String
    var seconds: Int
}

struct MemoryItem: Identifiable, Codable {
    let id: String
    let memo: String
    let createdAt: Date

    var stageIndex: Int
    var dueAt: Date

    var answeredAt: Date?
    var userAnswer: String?
    var correct: Bool?

    var autoCycle: Bool
    var correctStreak: Int
    var wrongCount: Int
    var isFinished: Bool

    init(
        id: String,
        memo: String,
        createdAt: Date,
        stageIndex: Int,
        dueAt: Date,
        answeredAt: Date?,
        userAnswer: String?,
        correct: Bool?,
        autoCycle: Bool,
        correctStreak: Int,
        wrongCount: Int,
        isFinished: Bool
    ) {
        self.id = id
        self.memo = memo
        self.createdAt = createdAt
        self.stageIndex = stageIndex
        self.dueAt = dueAt
        self.answeredAt = answeredAt
        self.userAnswer = userAnswer
        self.correct = correct
        self.autoCycle = autoCycle
        self.correctStreak = correctStreak
        self.wrongCount = wrongCount
        self.isFinished = isFinished
    }

    enum CodingKeys: String, CodingKey {
        case id, memo, createdAt, stageIndex, dueAt
        case answeredAt, userAnswer, correct
        case autoCycle, correctStreak, wrongCount, isFinished
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id         = try c.decode(String.self, forKey: .id)
        memo       = try c.decode(String.self, forKey: .memo)
        createdAt  = try c.decode(Date.self, forKey: .createdAt)
        stageIndex = try c.decode(Int.self, forKey: .stageIndex)
        dueAt      = try c.decode(Date.self, forKey: .dueAt)

        answeredAt = try? c.decode(Date.self, forKey: .answeredAt)
        userAnswer = try? c.decode(String.self, forKey: .userAnswer)
        correct    = try? c.decode(Bool.self, forKey: .correct)

        autoCycle     = (try? c.decode(Bool.self, forKey: .autoCycle)) ?? false
        correctStreak = (try? c.decode(Int.self, forKey: .correctStreak)) ?? 0
        wrongCount    = (try? c.decode(Int.self, forKey: .wrongCount)) ?? 0
        isFinished    = (try? c.decode(Bool.self, forKey: .isFinished)) ?? !autoCycle
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encode(memo, forKey: .memo)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(stageIndex, forKey: .stageIndex)
        try c.encode(dueAt, forKey: .dueAt)

        try c.encodeIfPresent(answeredAt, forKey: .answeredAt)
        try c.encodeIfPresent(userAnswer, forKey: .userAnswer)
        try c.encodeIfPresent(correct, forKey: .correct)

        try c.encode(autoCycle, forKey: .autoCycle)
        try c.encode(correctStreak, forKey: .correctStreak)
        try c.encode(wrongCount, forKey: .wrongCount)
        try c.encode(isFinished, forKey: .isFinished)
    }
}

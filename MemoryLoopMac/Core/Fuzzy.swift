import Foundation

enum MatchMode: String, Codable {
    case strict
    case fuzzy
}

struct Fuzzy {

    static func normalized(_ s: String) -> String {
        s
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func distance(_ aRaw: String, _ bRaw: String) -> Int {
        let a = Array(normalized(aRaw))
        let b = Array(normalized(bRaw))
        let n = a.count
        let m = b.count
        if n == 0 { return m }
        if m == 0 { return n }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)

        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1,
                    dp[i][j - 1] + 1,
                    dp[i - 1][j - 1] + cost
                )
            }
        }

        return dp[n][m]
    }

    static func similar(_ a: String, _ b: String, threshold: Double) -> Bool {
        let la = max(1, normalized(a).count)
        let lb = max(1, normalized(b).count)
        let maxLen = max(la, lb)
        let d = distance(a, b)
        let score = 1.0 - (Double(d) / Double(maxLen))
        return score >= threshold
    }
}

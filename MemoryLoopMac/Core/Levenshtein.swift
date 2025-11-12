import Foundation

enum Fuzzy {
    static func normalized(_ s: String) -> String {
        s.lowercased()
         .folding(options: .diacriticInsensitive, locale: .current)
         .replacingOccurrences(of: "[^a-z0-9а-яё]", with: " ", options: .regularExpression)
         .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func distance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a), bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var prev = Array(0...bChars.count)
        var curr = Array(repeating: 0, count: bChars.count + 1)

        for (i, aCh) in aChars.enumerated() {
            curr[0] = i + 1
            for (j, bCh) in bChars.enumerated() {
                let cost = (aCh == bCh) ? 0 : 1
                curr[j+1] = min(
                    prev[j+1] + 1,      // deletion
                    curr[j] + 1,        // insertion
                    prev[j] + cost      // substitution
                )
            }
            swap(&prev, &curr)
        }
        return prev[bChars.count]
    }

    /// true если схожесть >= threshold (0.0...1.0)
    static func similar(_ a: String, _ b: String, threshold: Double = 0.8) -> Bool {
        let na = normalized(a), nb = normalized(b)
        if na.isEmpty || nb.isEmpty { return false }
        let d = distance(na, nb)
        let maxLen = max(na.count, nb.count)
        let sim = 1.0 - Double(d) / Double(maxLen)
        return sim >= threshold
    }
}

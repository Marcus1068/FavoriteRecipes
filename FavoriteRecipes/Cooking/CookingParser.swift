import Foundation

/// Splits a recipe's free text into the lines shown in cooking mode.
enum CookingParser {
    /// "1. ", "2) ", "3: " or a bullet at the start of a line.
    private static let stepMarker = /^\s*(?:\d+\s*[.):]|[-•*])\s*/
    private static let bulletMarker = /^\s*[-•*]\s+/

    /// One entry per non-empty line, without numbering or bullets.
    static func steps(from text: String?) -> [String] {
        lines(of: text, removing: stepMarker)
    }

    /// One entry per non-empty line, without bullets. Leading quantities such as "4 Eggs" are kept.
    static func ingredients(from text: String?) -> [String] {
        lines(of: text, removing: bulletMarker)
    }

    private static func lines(of text: String?, removing marker: some RegexComponent) -> [String] {
        (text ?? "")
            .split(whereSeparator: \.isNewline)
            .map { $0.replacing(marker, with: "", maxReplacements: 1) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

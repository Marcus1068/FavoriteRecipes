import Foundation

/// Cleans up tag text: trims, drops empties and duplicates (ignoring case and accents).
enum TagList {
    /// Splits "quick, kids ,Quick" into ["quick", "kids"].
    static func parse(_ text: String) -> [String] {
        normalize(text.split(whereSeparator: { $0 == "," || $0.isNewline }).map(String.init))
    }

    /// Trims every tag, removes empty ones and duplicates, and keeps the first spelling of each.
    static func normalize(_ tags: [String]) -> [String] {
        var seen: [String] = []
        var result: [String] = []
        for tag in tags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard !trimmed.isEmpty, !seen.contains(key) else { continue }
            seen.append(key)
            result.append(trimmed)
        }
        return result
    }

    /// All tags used by the recipes, sorted, without duplicates.
    static func all(in recipes: [Recipe]) -> [String] {
        normalize(recipes.flatMap(\.tags)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}

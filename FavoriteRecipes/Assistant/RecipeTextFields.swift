import Foundation

/// The parts of a recipe that the cleanup step reads and corrects.
struct RecipeTextFields: Sendable {
    var name: String
    /// One entry per line of the ingredients text.
    var ingredients: [String]
    /// One entry per line of the preparation text.
    var steps: [String]
}

extension RecipeTextFields {
    /// Non-empty, trimmed lines of a multi-line text.
    static func lines(of text: String?) -> [String] {
        (text ?? "")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

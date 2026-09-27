import Foundation

extension Recipe {
    /// Plain-text version of the recipe for sharing via Messages, Mail, Notes, etc.
    var shareText: String {
        var parts = [displayName]

        if let ingredients = ingredientsText?.trimmingCharacters(in: .whitespacesAndNewlines), !ingredients.isEmpty {
            parts.append(String(localized: .ingredients) + ":\n" + ingredients)
        }
        if let instructions = instructions?.trimmingCharacters(in: .whitespacesAndNewlines), !instructions.isEmpty {
            parts.append(String(localized: .instructions) + ":\n" + instructions)
        }
        if let notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            parts.append(String(localized: .notes) + ":\n" + notes)
        }
        if let sourceURL {
            parts.append(String(localized: .source) + ": " + sourceURL.absoluteString)
        }
        return parts.joined(separator: "\n\n")
    }
}

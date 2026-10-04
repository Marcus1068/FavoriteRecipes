import Foundation
import FoundationModels

/// Uses the on-device Apple Intelligence model to turn raw OCR text into a
/// structured recipe. Everything stays on the device.
enum RecipeAssistant {

    /// False on devices without Apple Intelligence, or while it is turned off or downloading.
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// The model's context window is small; longer text is cut to keep room for the answer.
    private static let maxInputCharacters = 6_000

    static func structure(_ text: String) async throws -> RecipeSuggestion {
        let session = LanguageModelSession(instructions: instructions)
        let prompt = "Organize this recipe text:\n\n" + String(text.prefix(maxInputCharacters))
        return try await session.respond(to: prompt, generating: RecipeSuggestion.self).content
    }

    /// Fixes typos and OCR slips in the recipe text without adding or removing anything.
    /// Throws `CleanupError.tooLong` instead of cutting the text, so nothing is lost.
    static func cleanUp(_ fields: RecipeTextFields) async throws -> RecipeTextFields {
        let ingredients = fields.ingredients.joined(separator: "\n")
        let steps = fields.steps.joined(separator: "\n")
        guard fields.name.count + ingredients.count + steps.count <= maxInputCharacters else {
            throw CleanupError.tooLong
        }
        let session = LanguageModelSession(instructions: cleanupInstructions)
        let prompt = """
            Title:
            \(fields.name)

            Ingredients (one per line):
            \(ingredients)

            Preparation (one per line):
            \(steps)
            """
        let response = try await session.respond(to: prompt, generating: RecipeCleanupResponse.self).content
        return RecipeTextFields(name: response.name, ingredients: response.ingredients, steps: response.steps)
    }

    enum CleanupError: LocalizedError {
        case tooLong

        var errorDescription: String? {
            String(localized: .cleanUpTooLong)
        }
    }

    private static var instructions: String {
        withLocale([
            "You organize recipe text that was read from a photo or PDF with OCR.",
            "Fix obvious OCR mistakes, but never invent ingredients, quantities or steps.",
            "Keep the language of the original text; do not translate."
        ])
    }

    private static var cleanupInstructions: String {
        withLocale([
            "You correct spelling mistakes, typos and obvious OCR errors in a recipe.",
            "Change as little as possible. Never add, remove, reorder or invent ingredients, quantities or steps.",
            "Return exactly one entry per input line, in the same order, and keep numbering and quantities as they are.",
            "Keep the language of the original text; do not translate.",
            "For the title: remove stray words or numbers that clearly do not belong and fix typos. "
                + "Keep the title unchanged if it is already fine. If it is empty, write a short title from the ingredients."
        ])
    }

    /// Adds the locale line Apple recommends for non-US locales.
    private static func withLocale(_ lines: [String]) -> String {
        var lines = lines
        let locale = Locale.current
        if !Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            lines.insert("The person's locale is \(locale.identifier).", at: 0)
        }
        return lines.joined(separator: "\n")
    }
}

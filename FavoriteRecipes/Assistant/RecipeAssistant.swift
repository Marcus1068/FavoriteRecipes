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

    private static var instructions: String {
        var lines = [
            "You organize recipe text that was read from a photo or PDF with OCR.",
            "Fix obvious OCR mistakes, but never invent ingredients, quantities or steps.",
            "Keep the language of the original text; do not translate."
        ]
        let locale = Locale.current
        if !Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            // Exact phrase recommended by Apple for non-US locales.
            lines.insert("The person's locale is \(locale.identifier).", at: 0)
        }
        return lines.joined(separator: "\n")
    }
}

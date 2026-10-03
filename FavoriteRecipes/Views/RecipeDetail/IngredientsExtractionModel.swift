import Foundation
import Observation

/// Reads text from an ingredients photo or PDF and, when Apple Intelligence is
/// available, organizes it into ingredients and steps.
///
/// The text readers and the assistant are injected so the flow can be tested
/// without Vision, PDFKit or the on-device language model.
@MainActor
@Observable
final class IngredientsExtractionModel {
    /// Progress text while text is being read or organized; nil when idle.
    private(set) var message: LocalizedStringResource?
    /// Shown when a photo or PDF could not be loaded, or no text could be read from it.
    var error: LocalizedStringResource?

    private let imageText: (Data) async -> String?
    private let pdfText: (Data) async -> String?
    private let isAssistantAvailable: () -> Bool
    private let organize: (String) async throws -> RecipeSuggestion

    init(
        imageText: @escaping (Data) async -> String? = { await TextExtractor.text(fromImageData: $0) },
        pdfText: @escaping (Data) async -> String? = { await TextExtractor.text(fromPDFData: $0) },
        isAssistantAvailable: @escaping () -> Bool = { RecipeAssistant.isAvailable },
        organize: @escaping (String) async throws -> RecipeSuggestion = { try await RecipeAssistant.structure($0) }
    ) {
        self.imageText = imageText
        self.pdfText = pdfText
        self.isAssistantAvailable = isAssistantAvailable
        self.organize = organize
    }

    /// Reads text from the photo and stores it as the recipe's ingredients text.
    func extract(fromImageData data: Data, into recipe: Recipe, isNew: Bool) async {
        await extract(into: recipe, isNew: isNew, failure: .noTextRecognizedInPhoto) {
            await imageText(data)
        }
    }

    /// Reads text from the PDF and stores it as the recipe's ingredients text.
    func extract(fromPDFData data: Data, into recipe: Recipe, isNew: Bool) async {
        await extract(into: recipe, isNew: isNew, failure: .noTextFoundInPDF) {
            await pdfText(data)
        }
    }

    private func extract(
        into recipe: Recipe,
        isNew: Bool,
        failure: LocalizedStringResource,
        readText: () async -> String?
    ) async {
        error = nil
        message = .extractingText
        defer { message = nil }

        guard let text = await readText() else {
            error = failure
            return
        }
        recipe.ingredientsText = text
        recipe.ingredientsType = .text

        guard isAssistantAvailable() else { return }
        message = .organizingRecipe
        // Best effort: if the model fails, the raw text is already in place.
        if let suggestion = try? await organize(text) {
            recipe.applySuggestion(
                name: suggestion.name,
                category: suggestion.category.recipeCategory,
                ingredients: suggestion.ingredients,
                steps: suggestion.steps,
                updatingCategory: isNew
            )
        }
    }
}

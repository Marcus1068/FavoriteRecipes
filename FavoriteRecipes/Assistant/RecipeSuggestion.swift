import FoundationModels

/// Structured recipe produced by the on-device language model from OCR text.
@Generable
struct RecipeSuggestion {
    @Guide(description: "A short title for the recipe, in the language of the recipe text")
    var name: String

    @Guide(description: "The category that fits the recipe best")
    var category: SuggestedCategory

    @Guide(description: "Each ingredient with its quantity, one per entry, in the original language")
    var ingredients: [String]

    @Guide(description: "The preparation steps in order, one per entry, without numbering. Empty if the text has none.")
    var steps: [String]
}

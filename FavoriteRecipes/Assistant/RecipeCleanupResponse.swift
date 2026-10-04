import FoundationModels

/// Corrected recipe text produced by the on-device language model.
@Generable
struct RecipeCleanupResponse {
    @Guide(description: "The recipe title with typos and stray text removed; unchanged if it is already fine")
    var name: String

    @Guide(description: "The ingredient lines with spelling mistakes fixed, one entry per input line, in the same order")
    var ingredients: [String]

    @Guide(description: "The preparation lines with spelling mistakes fixed, one entry per input line, in the same order")
    var steps: [String]
}

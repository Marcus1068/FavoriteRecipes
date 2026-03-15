import SwiftUI
import UniformTypeIdentifiers

/// Sendable value snapshot of a recipe's ingredients.
///
/// Used as the `item:` for `ShareLink` so the extraction (OCR / PDF parsing)
/// is performed lazily inside the async Transferable export closure — only
/// when the user actually picks a share destination.  This works natively on
/// all platforms: iOS, iPadOS, and Mac Catalyst.
struct RecipeIngredients: Transferable, Sendable {
    let recipeName:           String
    let ingredientsType:      IngredientsType
    let ingredientsText:      String?
    let ingredientsImageData: Data?
    let ingredientsPDFData:   Data?

    init(from recipe: Recipe) {
        recipeName           = recipe.name.isEmpty ? "Recipe" : recipe.name
        ingredientsType      = recipe.ingredientsType
        ingredientsText      = recipe.ingredientsText
        ingredientsImageData = recipe.ingredientsImageData
        ingredientsPDFData   = recipe.ingredientsPDFData
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { item in
            let text = await TextExtractor.extract(
                type:      item.ingredientsType,
                text:      item.ingredientsText,
                imageData: item.ingredientsImageData,
                pdfData:   item.ingredientsPDFData
            )
            return text.data(using: .utf8) ?? Data()
        }
    }
}

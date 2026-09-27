import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID = UUID()
    var name: String = ""
    var category: RecipeCategory = RecipeCategory.meat
    @Attribute(.externalStorage) var recipeImageData: Data? = nil
    var isFavorite: Bool = false
    var ingredientsType: IngredientsType = IngredientsType.text
    @Attribute(.externalStorage) var ingredientsImageData: Data? = nil
    @Attribute(.externalStorage) var ingredientsPDFData: Data? = nil
    var ingredientsText: String? = nil
    var createdAt: Date = Date()

    // Added with the recipe details feature. All optional or defaulted so
    // existing stores migrate automatically and CloudKit accepts the schema.
    var instructions: String? = nil
    var servings: Int? = nil
    var prepMinutes: Int? = nil
    var cookMinutes: Int? = nil
    var sourceURLString: String? = nil
    var notes: String? = nil
    /// 0 = not rated, otherwise 1…5 stars.
    var rating: Int = 0

    init(
        name: String = "",
        category: RecipeCategory = .meat,
        isFavorite: Bool = false
    ) {
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
    }
}

extension Recipe {
    /// Whether the user has entered anything worth keeping.
    /// Used to decide if an unsaved draft may be discarded without asking.
    var hasContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || recipeImageData != nil
            || ingredientsImageData != nil
            || ingredientsPDFData != nil
            || ingredientsText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || instructions?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// The name to show, falling back to a localized placeholder.
    var displayName: String {
        name.isEmpty ? String(localized: .untitledRecipe) : name
    }

    /// The source link, if the stored string is a valid http(s) URL.
    var sourceURL: URL? {
        guard let sourceURLString,
              let url = URL(string: sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    /// Whether `text` matches the name, ingredients, instructions or notes.
    func matches(searchText text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return [name, ingredientsText, instructions, notes]
            .compactMap(\.self)
            .contains { $0.localizedStandardContains(query) }
    }
}

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

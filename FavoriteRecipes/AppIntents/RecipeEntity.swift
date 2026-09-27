import AppIntents
import CoreSpotlight

/// A recipe as seen by Siri, Shortcuts and Spotlight.
struct RecipeEntity: IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Recipe")
    static let defaultQuery = RecipeEntityQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Category")
    var categoryName: String

    /// Ingredients and preparation, used as Spotlight's searchable description.
    let details: String?

    init(recipe: Recipe) {
        id = recipe.id
        details = [recipe.ingredientsText, recipe.instructions]
            .compactMap(\.self)
            .joined(separator: "\n")
        name = recipe.displayName
        categoryName = String(localized: recipe.category.localizedName)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(categoryName)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = name
        attributes.contentDescription = details
        attributes.keywords = [categoryName]
        return attributes
    }
}

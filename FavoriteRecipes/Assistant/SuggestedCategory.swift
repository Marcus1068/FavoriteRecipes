import FoundationModels

/// Categories the language model may choose from; mirrors `RecipeCategory`.
@Generable
enum SuggestedCategory {
    case meat, noodles, fish, vegetarian, vegan, cake, cookies, soup, drinks

    var recipeCategory: RecipeCategory {
        switch self {
        case .meat:       .meat
        case .noodles:    .noodles
        case .fish:       .fish
        case .vegetarian: .vegetarian
        case .vegan:      .vegan
        case .cake:       .cake
        case .cookies:    .cookies
        case .soup:       .soup
        case .drinks:     .drinks
        }
    }
}

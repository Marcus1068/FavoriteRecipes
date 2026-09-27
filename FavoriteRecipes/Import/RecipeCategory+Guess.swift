import Foundation

extension RecipeCategory {
    /// Keywords (English and German) that suggest a category, checked in order.
    /// More specific categories come first so "vegan cake" becomes cake, not vegan.
    private static let keywords: [(RecipeCategory, [String])] = [
        (.drinks, ["drink", "cocktail", "smoothie", "lemonade", "punch", "getränk", "saft", "limonade", "bowle"]),
        (.cookies, ["cookie", "biscuit", "keks", "plätzchen", "cracker"]),
        (.cake, ["cake", "torte", "kuchen", "muffin", "cupcake", "brownie", "cheesecake", "tarte"]),
        (.soup, ["soup", "stew", "chowder", "broth", "suppe", "eintopf", "brühe", "ramen"]),
        (.noodles, ["pasta", "noodle", "spaghetti", "lasagna", "lasagne", "nudel", "penne", "tagliatelle",
                    "risotto", "pad thai", "spätzle"]),
        (.fish, ["fish", "salmon", "tuna", "shrimp", "prawn", "seafood", "fisch", "lachs", "thunfisch",
                 "garnele", "meeresfrüchte", "sea bass", "dorade"]),
        (.vegan, ["vegan"]),
        (.vegetarian, ["vegetarian", "vegetarisch", "veggie", "salad", "salat"]),
        (.meat, ["beef", "pork", "chicken", "lamb", "steak", "bacon", "sausage", "rindfleisch", "rinder", "schwein",
                 "hähnchen",
                 "huhn", "lamm", "wurst", "hackfleisch", "fleisch", "meat", "turkey", "puten"])
    ]

    /// Best guess from category hints first, then the recipe name. Nil if nothing matches.
    static func guess(hints: [String], name: String) -> RecipeCategory? {
        for text in [hints.joined(separator: " "), name] {
            let lowered = text.lowercased()
            if let match = keywords.first(where: { _, words in words.contains { lowered.contains($0) } }) {
                return match.0
            }
        }
        return nil
    }
}

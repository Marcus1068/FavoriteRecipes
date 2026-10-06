import Foundation

/// One ingredient line split into amount, unit and name, e.g. "400 g spaghetti".
/// The recipe keeps its text as written; this is only a reading of it.
struct Ingredient: Codable, Equatable {
    /// The line as it was written.
    var original: String
    /// nil when the line has no amount, e.g. "Salt".
    var amount: Double?
    /// The upper end of a range such as "2-3".
    var amountHigh: Double?
    /// A unit the app can convert.
    var unit: IngredientUnit?
    /// The unit as the recipe wrote it ("EL", "Gramm"); dropped when the unit is converted.
    var unitText: String?
    /// A unit word the app cannot convert (clove, pinch, ...), kept as written.
    var otherUnit: String?
    /// What the ingredient is, e.g. "spaghetti" or "garlic, minced".
    var name: String

    var hasAmount: Bool { amount != nil }

    /// The name without preparation notes ("garlic, minced" becomes "garlic"), lower case and without accents,
    /// so the same ingredient from different recipes is recognized.
    var shoppingKey: String {
        var base = name
        if let cut = base.firstIndex(where: { $0 == "," || $0 == "(" }) {
            base = String(base[..<cut])
        }
        return base
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

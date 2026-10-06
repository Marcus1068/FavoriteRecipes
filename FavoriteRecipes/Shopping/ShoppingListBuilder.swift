import Foundation

/// Merges the ingredients of several recipes into one shopping list:
/// the same ingredient is added up when its amounts can be added (grams with ounces, millilitres with cups, counts with counts).
enum ShoppingListBuilder {

    static func items(from recipes: [ShoppingRecipe], locale: Locale = .current) -> [ShoppingItem] {
        var order: [String] = []
        var groups: [String: Group] = [:]

        for recipe in recipes {
            for ingredient in recipe.ingredients {
                let key = Self.groupKey(for: ingredient)
                if groups[key] == nil {
                    order.append(key)
                    groups[key] = Group(first: ingredient)
                }
                groups[key]?.add(ingredient)
            }
        }
        return order.compactMap { key in
            groups[key].map { ShoppingItem(id: key, text: $0.text(locale: locale)) }
        }
    }

    /// Ingredients with the same name and the same kind of unit end up in one group.
    static func groupKey(for ingredient: Ingredient) -> String {
        let kind: String
        if let unit = ingredient.unit {
            kind = unit.kind.rawValue
        } else if let other = ingredient.otherUnit {
            kind = "other:" + IngredientUnit.canonicalCountingWord(other)
        } else {
            kind = ingredient.hasAmount ? "count" : "none"
        }
        return ingredient.shoppingKey + "|" + kind
    }

    private struct Group {
        let first: Ingredient
        private var total = 0.0
        private var totalHigh = 0.0
        private var hasRange = false
        private var hasAmount = false
        private var usesImperial: Bool
        /// The counting words used for this ingredient ("clove", "cloves"), to write the right one for the total.
        private var countingWords: [String] = []

        init(first: Ingredient) {
            self.first = first
            usesImperial = first.unit?.isImperial ?? false
        }

        mutating func add(_ ingredient: Ingredient) {
            if let word = ingredient.otherUnit, !countingWords.contains(word) { countingWords.append(word) }
            guard let amount = ingredient.amount else { return }
            hasAmount = true
            let factor = ingredient.unit?.baseAmount ?? 1
            total += amount * factor
            totalHigh += (ingredient.amountHigh ?? amount) * factor
            if ingredient.amountHigh != nil { hasRange = true }
        }

        func text(locale: Locale) -> String {
            let name = displayName
            guard hasAmount else { return name }

            var result = Ingredient(original: "", amount: total, amountHigh: hasRange ? totalHigh : nil,
                                    unit: first.unit, unitText: first.unitText, otherUnit: first.otherUnit, name: name)
            if let unit = first.unit {
                // Show metric sums in g/kg or ml/l and imperial sums in oz/lb or cups, whichever the first recipe used.
                let system: UnitSystem = usesImperial ? .imperial : .metric
                let (amount, best) = Ingredient.best(base: total, kind: unit.kind, system: system)
                result.amount = amount
                result.amountHigh = hasRange ? totalHigh / best.baseAmount : nil
                result.unit = best
                result.unitText = nil
            }
            if first.otherUnit != nil {
                // One of something uses the shortest form ("clove"), more of it the longest ("cloves").
                let isSingle = total == 1 && !hasRange
                result.otherUnit = (isSingle ? countingWords.min { $0.count < $1.count } : countingWords.max { $0.count < $1.count })
                    ?? first.otherUnit
            }
            return result.text(adjusted: true, locale: locale)
        }

        /// The ingredient's name without preparation notes ("garlic, minced" becomes "garlic").
        private var displayName: String {
            var base = first.name
            if let cut = base.firstIndex(where: { $0 == "," || $0 == "(" }) {
                base = String(base[..<cut])
            }
            let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? first.name : trimmed
        }
    }
}

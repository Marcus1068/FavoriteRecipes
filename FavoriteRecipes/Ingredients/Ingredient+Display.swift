import Foundation

extension Ingredient {

    /// This ingredient for a different number of servings.
    func scaled(by factor: Double) -> Ingredient {
        guard factor != 1, let amount else { return self }
        var copy = self
        copy.amount = amount * factor
        copy.amountHigh = amountHigh.map { $0 * factor }
        return copy
    }

    /// This ingredient in the units of a system. Only measured units are converted;
    /// counted things ("2 cloves", "4 eggs") and lines without an amount stay as they are.
    func converted(to system: UnitSystem) -> Ingredient {
        guard system != .original, let amount, let unit else { return self }
        let wantsConversion = (system == .metric && unit.isImperial) || (system == .imperial && unit.isMetric)
        guard wantsConversion else { return self }

        let base = amount * unit.baseAmount
        let (newAmount, newUnit) = Self.best(base: base, kind: unit.kind, system: system)
        var copy = self
        copy.amount = newAmount
        copy.unit = newUnit
        copy.unitText = nil
        if let high = amountHigh {
            copy.amountHigh = high * unit.baseAmount / newUnit.baseAmount
        }
        return copy
    }

    /// The most readable unit for an amount, e.g. 1500 g is shown as 1.5 kg and 500 g as 17.6 oz.
    static func best(base: Double, kind: IngredientUnit.Kind, system: UnitSystem) -> (Double, IngredientUnit) {
        switch (kind, system) {
        case (.mass, .metric):
            base >= 1_000 ? (base / 1_000, .kilogram) : (base, .gram)
        case (.volume, .metric):
            base >= 1_000 ? (base / 1_000, .liter) : (base, .milliliter)
        case (.mass, _):
            base >= 453.592 ? (base / 453.592, .pound) : (base / 28.349_5, .ounce)
        case (.volume, _):
            if base >= 59 { (base / 240, .cup) } else if base >= 14 { (base / 15, .tablespoon) } else { (base / 5, .teaspoon) }
        }
    }

    /// The line as text, with amounts rounded the way a cook would measure them.
    /// `adjusted` is true after scaling or converting, when exact values like 187.5 g are rounded to 190 g.
    func text(adjusted: Bool, locale: Locale = .current) -> String {
        guard let amount else { return original }
        let amountText = AmountFormat.string(amount, unit: unit, adjusted: adjusted, locale: locale)
        var parts = [amountText]
        if let high = amountHigh {
            parts[0] += "–" + AmountFormat.string(high, unit: unit, adjusted: adjusted, locale: locale)
        }
        if let unit {
            // Keep the written unit if it was not converted ("EL" stays "EL"), otherwise use the symbol.
            parts.append(unitWord(for: unit, shownAmount: AmountFormat.shownValue(amount, unit: unit, adjusted: adjusted)))
        } else if let otherUnit {
            parts.append(otherUnit)
        }
        if !name.isEmpty { parts.append(name) }
        return parts.joined(separator: " ")
    }

    /// The unit word to show: as written, or the symbol after a conversion. "cup" follows the shown amount.
    private func unitWord(for unit: IngredientUnit, shownAmount: Double) -> String {
        let written = unitText?.lowercased()
        if unit == .cup, written == nil || written == "cup" || written == "cups" {
            return shownAmount <= 1 && amountHigh == nil ? "cup" : "cups"
        }
        return unitText ?? unit.symbol
    }

    /// Scaled and converted, as text. An unchanged ingredient is shown exactly as written.
    func display(factor: Double, system: UnitSystem, locale: Locale = .current) -> String {
        let result = scaled(by: factor).converted(to: system)
        if factor == 1, result.unit == unit { return original }
        return result.text(adjusted: true, locale: locale)
    }
}

/// Formats amounts as people write them: "1½", "250", "2.5".
enum AmountFormat {
    private static let fractions: [(value: Double, text: String)] = [
        (0, ""), (0.125, "⅛"), (0.25, "¼"), (1.0 / 3, "⅓"), (0.5, "½"), (2.0 / 3, "⅔"), (0.75, "¾"), (0.875, "⅞"), (1, "")
    ]

    /// The number that `string` displays, after rounding to quarters or to cooking amounts.
    static func shownValue(_ value: Double, unit: IngredientUnit?, adjusted: Bool) -> Double {
        let usesFractions = unit == nil || unit == .cup || unit == .tablespoon || unit == .teaspoon
        if usesFractions { return adjusted && unit != nil ? roundedToMeasure(value) : value }
        return adjusted ? roundedForCooking(value, unit: unit) : value
    }

    static func string(_ value: Double, unit: IngredientUnit?, adjusted: Bool, locale: Locale = .current) -> String {
        // Metric amounts are shown as decimals, everything else (cups, spoons, counted things) as fractions.
        let usesFractions = unit == nil || unit == .cup || unit == .tablespoon || unit == .teaspoon
        if usesFractions {
            // Spoons and cups are measured in quarters (eighths for tiny amounts), not in 4.17 cups.
            let measured = adjusted && unit != nil ? roundedToMeasure(value) : value
            if let text = fractionText(measured, locale: locale) { return text }
        }

        let rounded = adjusted ? roundedForCooking(value, unit: unit) : value
        return rounded.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }

    private static func roundedToMeasure(_ value: Double) -> Double {
        let step = value < 0.5 ? 8.0 : 4.0
        return max(1 / step, (value * step).rounded() / step)
    }

    /// 1.5 → "1½", 0.25 → "¼", 3 → "3". Nil when the value is not close to a common fraction.
    private static func fractionText(_ value: Double, locale: Locale) -> String? {
        guard value >= 0 else { return nil }
        var whole = value.rounded(.down)
        let part = value - whole
        guard let match = fractions.min(by: { abs($0.value - part) < abs($1.value - part) }),
              abs(match.value - part) < 0.04 else { return nil }
        if match.value == 1 { whole += 1 }
        let wholeText = whole.formatted(.number.precision(.fractionLength(0)).locale(locale))
        if whole == 0 { return match.text.isEmpty ? "0" : match.text }
        return match.text.isEmpty ? wholeText : wholeText + match.text
    }

    /// 187.5 g → 190 g, 36 g → 36 g, 2.34 oz → 2.3 oz.
    private static func roundedForCooking(_ value: Double, unit: IngredientUnit?) -> Double {
        switch unit {
        case .gram, .milliliter:
            if value >= 100 { return (value / 5).rounded() * 5 }
            if value >= 10 { return value.rounded() }
            return (value * 10).rounded() / 10
        case .kilogram, .liter:
            return (value * 100).rounded() / 100
        default:
            return (value * 10).rounded() / 10
        }
    }
}

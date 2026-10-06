import Foundation

/// A measuring unit the app can convert between.
enum IngredientUnit: String, Codable, CaseIterable {
    case gram, kilogram, milliliter, liter, deciliter, centiliter
    case ounce, pound, fluidOunce, cup, tablespoon, teaspoon

    /// What the unit measures. Only units of the same kind can be added up or converted.
    enum Kind: String, Codable {
        case mass, volume
    }

    var kind: Kind {
        switch self {
        case .gram, .kilogram, .ounce, .pound: .mass
        default: .volume
        }
    }

    /// The size in grams (mass) or millilitres (volume). A cup is the US cup of 240 ml.
    var baseAmount: Double {
        switch self {
        case .gram:       1
        case .kilogram:   1_000
        case .ounce:      28.349_5
        case .pound:      453.592
        case .milliliter: 1
        case .liter:      1_000
        case .deciliter:  100
        case .centiliter: 10
        case .fluidOunce: 29.573_5
        case .cup:        240
        case .tablespoon: 15
        case .teaspoon:   5
        }
    }

    /// Units from the metric system. The tablespoon and teaspoon belong to both systems.
    var isMetric: Bool {
        switch self {
        case .gram, .kilogram, .milliliter, .liter, .deciliter, .centiliter: true
        default: false
        }
    }

    var isImperial: Bool {
        switch self {
        case .ounce, .pound, .fluidOunce, .cup: true
        default: false
        }
    }

    /// Short written form used when a unit is shown after a conversion.
    var symbol: String {
        switch self {
        case .gram:       "g"
        case .kilogram:   "kg"
        case .milliliter: "ml"
        case .liter:      "l"
        case .deciliter:  "dl"
        case .centiliter: "cl"
        case .ounce:      "oz"
        case .pound:      "lb"
        case .fluidOunce: "fl oz"
        case .cup:        "cup"
        case .tablespoon: "tbsp"
        case .teaspoon:   "tsp"
        }
    }

    /// Recognizes written units in English and German, e.g. "g", "Gramm", "EL", "tablespoons".
    init?(word: String) {
        let key = word.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        switch key {
        case "g", "gr", "gram", "grams", "gramm":                  self = .gram
        case "kg", "kilo", "kilos", "kilogram", "kilogramm":       self = .kilogram
        case "ml", "milliliter", "millilitre", "milliliters":      self = .milliliter
        case "l", "liter", "litre", "liters", "litres":            self = .liter
        case "dl", "deziliter", "deciliter":                       self = .deciliter
        case "cl", "zentiliter", "centiliter":                     self = .centiliter
        case "oz", "ounce", "ounces":                              self = .ounce
        case "lb", "lbs", "pound", "pounds":                       self = .pound
        case "floz", "fl-oz":                                      self = .fluidOunce
        case "cup", "cups", "tasse", "tassen":                     self = .cup
        case "tbsp", "tbs", "tablespoon", "tablespoons", "el", "esslöffel", "essloeffel": self = .tablespoon
        case "tsp", "teaspoon", "teaspoons", "tl", "teelöffel", "teeloeffel":             self = .teaspoon
        default: return nil
        }
    }

    /// "cloves" and "clove" (or "Zehen" and "Zehe") are the same counting word.
    static func canonicalCountingWord(_ word: String) -> String {
        let lowered = word.lowercased()
        // The shortest form that is a known counting word: "cloves" -> "clove", "Zehen" -> "zehe".
        let shorter = [String(lowered.dropLast(2)), String(lowered.dropLast(1))]
        return shorter.first { countingWords.contains($0) } ?? lowered
    }

    /// Words for things counted rather than measured; they are kept as written.
    static let countingWords: Set<String> = [
        "clove", "cloves", "zehe", "zehen", "pinch", "pinches", "prise", "prisen",
        "can", "cans", "tin", "tins", "dose", "dosen", "bunch", "bunches", "bund",
        "slice", "slices", "scheibe", "scheiben", "piece", "pieces", "stück", "stk",
        "sprig", "sprigs", "zweig", "zweige", "packet", "packets", "pack", "package", "packages",
        "päckchen", "pkg", "head", "heads", "kopf", "stalk", "stalks", "stange", "stangen",
        "handful", "handvoll", "dash", "dashes", "spritzer", "knob", "bottle", "flasche"
    ]
}

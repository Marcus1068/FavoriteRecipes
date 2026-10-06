import Foundation

/// Reads ingredient lines like "400 g spaghetti", "1½ cups flour" or "2 EL Öl" into amount, unit and name.
/// Lines that do not start with an amount (e.g. "Salt and pepper") keep their text as the name.
enum IngredientParser {

    static func parse(_ line: String) -> Ingredient {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var rest = Substring(trimmed)
        rest = rest.drop { $0 == "-" || $0 == "•" || $0 == "*" || $0 == " " }
        rest = skipApproximation(rest)

        guard let first = readAmount(rest) else {
            return Ingredient(original: trimmed, name: String(rest))
        }
        let amount = first.value
        var amountHigh: Double?
        rest = first.rest

        if let range = readRange(rest) {
            // "10-5" is not a range; only a larger second number is kept.
            if range.value > amount { amountHigh = range.value }
            rest = range.rest
        }

        let unitReading = readUnit(rest)
        rest = unitReading.rest
        let name = String(rest).trimmingCharacters(in: .whitespacesAndNewlines)
            .removingLeadingWord("of").removingLeadingWord("von")

        return Ingredient(
            original: trimmed,
            amount: amount,
            amountHigh: amountHigh,
            unit: unitReading.unit,
            unitText: unitReading.unitText,
            otherUnit: unitReading.otherUnit,
            name: name
        )
    }

    /// Parses every non-empty line of a text.
    static func parseLines(_ text: String?) -> [Ingredient] {
        CookingParser.ingredients(from: text).map(parse)
    }

    // MARK: - Reading pieces

    private static let vulgarFractions: [Character: Double] = [
        "½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 1.0 / 3, "⅔": 2.0 / 3, "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
    ]

    /// Skips "ca.", "circa", "about", "approx." in front of an amount.
    private static func skipApproximation(_ text: Substring) -> Substring {
        let lowered = text.lowercased()
        for word in ["circa ", "ca. ", "ca ", "about ", "approx. ", "approx ", "etwa ", "ungefähr "] where lowered.hasPrefix(word) {
            return text.dropFirst(word.count)
        }
        return text
    }

    /// Reads a number: "4", "1,5", "½", "1½", "1/2", "1 1/2" or "1 ½".
    private static func readAmount(_ text: Substring) -> (value: Double, rest: Substring)? {
        guard let first = text.first else { return nil }

        if let fraction = vulgarFractions[first] {
            return (fraction, text.dropFirst())
        }
        guard first.isASCII, first.isNumber else { return nil }

        var rest = text
        let whole = readDigits(&rest)
        var value = Double(whole) ?? 0

        // Decimal part: "1,5" or "1.5" (only when digits follow).
        if let sign = rest.first, sign == "," || sign == ".", let after = rest.dropFirst().first, after.isASCII, after.isNumber {
            rest = rest.dropFirst()
            let decimals = readDigits(&rest)
            value = Double("\(whole).\(decimals)") ?? value
            return (value, rest)
        }
        // "1/2"
        if rest.first == "/", let denominator = readFractionDenominator(rest.dropFirst()), denominator.value > 0 {
            return (value / denominator.value, denominator.rest)
        }
        // "1½"
        if let next = rest.first, let fraction = vulgarFractions[next] {
            return (value + fraction, rest.dropFirst())
        }
        // "1 1/2" or "1 ½"
        let afterSpaces = rest.drop { $0 == " " }
        if afterSpaces.count < rest.count {
            if let next = afterSpaces.first, let fraction = vulgarFractions[next] {
                return (value + fraction, afterSpaces.dropFirst())
            }
            var probe = afterSpaces
            if let numerator = readDigitsIfAny(&probe), probe.first == "/",
               let denominator = readFractionDenominator(probe.dropFirst()), denominator.value > 0 {
                return (value + Double(numerator) / denominator.value, denominator.rest)
            }
        }
        return (value, rest)
    }

    private static func readFractionDenominator(_ text: Substring) -> (value: Double, rest: Substring)? {
        var rest = text
        guard let digits = readDigitsIfAny(&rest) else { return nil }
        return (Double(digits), rest)
    }

    private static func readDigits(_ text: inout Substring) -> String {
        let digits = text.prefix { $0.isASCII && $0.isNumber }
        text = text.dropFirst(digits.count)
        return String(digits)
    }

    private static func readDigitsIfAny(_ text: inout Substring) -> Int? {
        let digits = readDigits(&text)
        return digits.isEmpty ? nil : Int(digits)
    }

    /// Reads the second half of "2-3", "2 – 3", "2 to 3" or "2 bis 3".
    private static func readRange(_ text: Substring) -> (value: Double, rest: Substring)? {
        var rest = text.drop { $0 == " " }
        if rest.first == "-" || rest.first == "–" || rest.first == "—" {
            rest = rest.dropFirst()
        } else if rest.lowercased().hasPrefix("to ") {
            rest = rest.dropFirst(3)
        } else if rest.lowercased().hasPrefix("bis ") {
            rest = rest.dropFirst(4)
        } else {
            return nil
        }
        rest = rest.drop { $0 == " " }
        return readAmount(rest)
    }

    /// Reads the unit word after an amount ("g", "tbsp", "cloves"), also when attached as in "400g".
    private static func readUnit(_ text: Substring) -> (unit: IngredientUnit?, unitText: String?, otherUnit: String?, rest: Substring) {
        let afterSpaces = text.drop { $0 == " " }
        let word = afterSpaces.prefix { $0.isLetter || $0 == "." }
        guard !word.isEmpty else { return (nil, nil, nil, afterSpaces) }
        var rest = afterSpaces.dropFirst(word.count)

        // "fl oz" is two words.
        if word.lowercased() == "fl" {
            let next = rest.drop { $0 == " " }
            let second = next.prefix { $0.isLetter || $0 == "." }
            if second.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) == "oz" {
                return (.fluidOunce, "fl oz", nil, next.dropFirst(second.count))
            }
        }
        if let unit = IngredientUnit(word: String(word)) {
            return (unit, String(word).trimmingCharacters(in: CharacterSet(charactersIn: ".")), nil, rest)
        }
        let lowered = word.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if IngredientUnit.countingWords.contains(lowered) {
            return (nil, nil, String(word).trimmingCharacters(in: CharacterSet(charactersIn: ".")), rest)
        }
        return (nil, nil, nil, afterSpaces)
    }
}

private extension String {
    func removingLeadingWord(_ word: String) -> String {
        let prefix = word + " "
        return lowercased().hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}

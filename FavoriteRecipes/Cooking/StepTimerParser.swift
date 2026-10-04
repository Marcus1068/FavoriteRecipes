import Foundation

/// A duration found in a preparation step, e.g. "10 Minuten" or "1 hour 30 minutes".
struct StepTimerSuggestion: Equatable, Identifiable {
    /// Length of the timer.
    let seconds: Int
    /// The text of the step that mentions it, used for the button.
    let text: String
    var id: String { "\(text)-\(seconds)" }
}

/// Finds durations in step text so a timer can be started with one tap.
/// Understands German and English, decimals ("1,5 Stunden"), fractions ("½ hour"),
/// ranges ("10-15 min", the shorter time is used) and combinations ("1 Stunde 30 Minuten").
enum StepTimerParser {
    private enum Unit: Int {
        case second = 1, minute = 60, hour = 3_600

        init?(_ word: String) {
            switch word.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) {
            case "sek", "sekunde", "sekunden", "sec", "secs", "second", "seconds":
                self = .second
            case "min", "mins", "minute", "minuten", "minutes":
                self = .minute
            case "std", "stunde", "stunden", "h", "hr", "hrs", "hour", "hours":
                self = .hour
            default:
                return nil
            }
        }
    }

    private struct Match {
        let range: Range<String.Index>
        let seconds: Int
        let unit: Unit?
    }

    /// A number with an optional fraction: "10", "1,5", "½", "1½".
    private static let number = #"\d+(?:[.,]\d+)?[½¼¾]?|[½¼¾]"#
    private static let unit = #"sekunden?|sek\.?|secs?|seconds?|minuten|minute|minutes|mins?\.?|stunden?|std\.?|hours?|hrs?|h"#

    private static let numeric = try? Regex(
        #"(?<first>\#(number))(?:\s*(?:-|–|bis|to)\s*\#(number))?\s*(?<unit>\#(unit))(?![\p{L}])"#
    ).ignoresCase()

    /// Phrases without a number, with their length in seconds.
    private static let phrases: [(pattern: String, seconds: Int)] = [
        (#"anderthalb\s+stunden?"#, 5_400),
        (#"eine\s+halbe\s+stunde|halbe\s+stunde|half\s+an\s+hour|half\s+hour"#, 1_800),
        (#"eine\s+viertelstunde|viertelstunde|eine\s+viertel\s+stunde|quarter\s+of\s+an\s+hour"#, 900),
        (#"eine\s+stunde|one\s+hour|an\s+hour"#, 3_600),
        (#"eine\s+minute|one\s+minute"#, 60),
    ]

    /// Timers longer than this are ignored; they are almost always "overnight" or "rest" hints.
    static let longestSeconds = 24 * 3_600

    static func suggestions(in text: String) -> [StepTimerSuggestion] {
        var matches = numericMatches(in: text) + phraseMatches(in: text)
        matches.sort { $0.range.lowerBound < $1.range.lowerBound }
        matches = dropOverlaps(matches)
        matches = mergeCombinations(matches, in: text)

        return matches.compactMap { match in
            guard match.seconds > 0, match.seconds <= longestSeconds else { return nil }
            return StepTimerSuggestion(seconds: match.seconds, text: String(text[match.range]))
        }
    }

    // MARK: - Finding matches

    private static func numericMatches(in text: String) -> [Match] {
        guard let numeric else { return [] }
        return text.matches(of: numeric).compactMap { match in
            guard let first = match.output["first"]?.substring,
                  let unitWord = match.output["unit"]?.substring,
                  let unit = Unit(String(unitWord)),
                  let value = value(of: String(first))
            else { return nil }
            return Match(range: match.range, seconds: Int((value * Double(unit.rawValue)).rounded()), unit: unit)
        }
    }

    private static func phraseMatches(in text: String) -> [Match] {
        phrases.flatMap { phrase -> [Match] in
            guard let regex = try? Regex(phrase.pattern).ignoresCase() else { return [] }
            return text.matches(of: regex).map { Match(range: $0.range, seconds: phrase.seconds, unit: nil) }
        }
    }

    /// "1,5" → 1.5, "½" → 0.5, "1½" → 1.5.
    private static func value(of text: String) -> Double? {
        let fractions: [Character: Double] = ["½": 0.5, "¼": 0.25, "¾": 0.75]
        var digits = text
        var fraction = 0.0
        if let last = digits.last, let part = fractions[last] {
            fraction = part
            digits.removeLast()
        }
        if digits.isEmpty { return fraction }
        guard let base = Double(digits.replacing(",", with: ".")) else { return nil }
        return base + fraction
    }

    /// When two matches overlap (e.g. "eine halbe Stunde" and "eine Stunde"), keep the earlier, longer one.
    private static func dropOverlaps(_ matches: [Match]) -> [Match] {
        var result: [Match] = []
        for match in matches {
            if let last = result.last, match.range.lowerBound < last.range.upperBound { continue }
            result.append(match)
        }
        return result
    }

    /// Joins "1 Stunde 30 Minuten" and "1 hour and 30 minutes" into one timer.
    private static func mergeCombinations(_ matches: [Match], in text: String) -> [Match] {
        var result: [Match] = []
        for match in matches {
            if let last = result.last,
               let lastUnit = last.unit, let unit = match.unit, lastUnit.rawValue > unit.rawValue,
               isJoiner(text[last.range.upperBound..<match.range.lowerBound]) {
                result[result.count - 1] = Match(
                    range: last.range.lowerBound..<match.range.upperBound,
                    seconds: last.seconds + match.seconds,
                    unit: unit
                )
            } else {
                result.append(match)
            }
        }
        return result
    }

    private static func isJoiner(_ gap: Substring) -> Bool {
        let cleaned = gap.lowercased().trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ",")))
        return cleaned.isEmpty || cleaned == "und" || cleaned == "and"
    }
}

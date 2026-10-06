import Foundation

/// Which units ingredient amounts are shown in.
enum UnitSystem: String, CaseIterable, Identifiable {
    /// As written in the recipe.
    case original, metric, imperial

    var id: Self { self }

    var localizedName: LocalizedStringResource {
        switch self {
        case .original: .unitsAsWritten
        case .metric:   .unitsMetric
        case .imperial: .unitsImperial
        }
    }
}

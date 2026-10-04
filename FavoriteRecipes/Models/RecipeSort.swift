import Foundation

/// How recipes are ordered in the carousel and list.
enum RecipeSort: String, CaseIterable, Identifiable {
    case newest, oldest, name, rating, recentlyCooked

    var id: Self { self }

    var localizedName: LocalizedStringResource {
        switch self {
        case .newest:         .sortNewest
        case .oldest:         .sortOldest
        case .name:           .sortName
        case .rating:         .sortRating
        case .recentlyCooked: .sortRecentlyCooked
        }
    }

    var icon: String {
        switch self {
        case .newest, .oldest: "calendar"
        case .name:            "textformat"
        case .rating:          "star"
        case .recentlyCooked:  "frying.pan"
        }
    }

    /// Returns the recipes in this order. Ties fall back to newest first so the order is stable.
    func sorted(_ recipes: [Recipe]) -> [Recipe] {
        recipes.sorted { a, b in
            switch self {
            case .newest:
                return a.createdAt > b.createdAt
            case .oldest:
                return a.createdAt < b.createdAt
            case .name:
                let order = a.displayName.localizedStandardCompare(b.displayName)
                return order == .orderedSame ? a.createdAt > b.createdAt : order == .orderedAscending
            case .rating:
                return a.rating == b.rating ? a.createdAt > b.createdAt : a.rating > b.rating
            case .recentlyCooked:
                switch (a.lastCookedAt, b.lastCookedAt) {
                case let (x?, y?): return x == y ? a.createdAt > b.createdAt : x > y
                case (_?, nil):    return true
                case (nil, _?):    return false
                case (nil, nil):   return a.createdAt > b.createdAt
                }
            }
        }
    }
}

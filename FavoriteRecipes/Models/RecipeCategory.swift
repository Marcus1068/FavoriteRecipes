import Foundation
import SwiftUI

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    case meat        = "Meat"
    case noodles     = "Noodles"
    case fish        = "Fish"
    case vegetarian  = "Vegetarian"
    case vegan       = "Vegan"
    case cake        = "Cake"
    case cookies     = "Cookies"
    case soup        = "Soup"
    case drinks      = "Drinks"

    var id: Self { self }

    /// Localized display name. `rawValue` is persisted and must not change.
    var localizedName: LocalizedStringResource {
        switch self {
        case .meat:        .categoryMeat
        case .noodles:     .categoryNoodles
        case .fish:        .categoryFish
        case .vegetarian:  .categoryVegetarian
        case .vegan:       .categoryVegan
        case .cake:        .categoryCake
        case .cookies:     .categoryCookies
        case .soup:        .categorySoup
        case .drinks:      .categoryDrinks
        }
    }

    var icon: String {
        switch self {
        case .meat:        "🥩"
        case .noodles:     "🍝"
        case .fish:        "🐟"
        case .vegetarian:  "🥗"
        case .vegan:       "🌱"
        case .cake:        "🎂"
        case .cookies:     "🍪"
        case .soup:        "🍲"
        case .drinks:      "🥤"
        }
    }

    var color: Color {
        switch self {
        case .meat:        .red
        case .noodles:     .orange
        case .fish:        .blue
        case .vegetarian:  .green
        case .vegan:       .mint
        case .cake:        .pink
        case .cookies:     Color(red: 0.72, green: 0.45, blue: 0.20)
        case .soup:        Color(red: 0.85, green: 0.55, blue: 0.15)
        case .drinks:      .teal
        }
    }
}

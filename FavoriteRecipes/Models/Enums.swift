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

enum IngredientsType: String, Codable, CaseIterable {
    case photo = "Photo"
    case pdf   = "PDF"
    case text  = "Text"

    var icon: String {
        switch self {
        case .photo: "camera"
        case .pdf:   "doc.fill"
        case .text:  "text.alignleft"
        }
    }
}

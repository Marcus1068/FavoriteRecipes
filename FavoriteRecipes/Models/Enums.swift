import Foundation
import SwiftUI

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    case meat        = "Meat"
    case noodles     = "Noodles"
    case fish        = "Fish"
    case vegetarian  = "Vegetarian"
    case vegan       = "Vegan"

    var id: Self { self }

    var icon: String {
        switch self {
        case .meat:        "🥩"
        case .noodles:     "🍝"
        case .fish:        "🐟"
        case .vegetarian:  "🥗"
        case .vegan:       "🌱"
        }
    }

    var color: Color {
        switch self {
        case .meat:        .red
        case .noodles:     .orange
        case .fish:        .blue
        case .vegetarian:  .green
        case .vegan:       .mint
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

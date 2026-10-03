import Foundation

enum IngredientsType: String, Codable, CaseIterable {
    case photo = "Photo"
    case pdf   = "PDF"
    case text  = "Text"

    /// Localized display name. `rawValue` is persisted and must not change.
    var localizedName: LocalizedStringResource {
        switch self {
        case .photo: .ingredientsTypePhoto
        case .pdf:   .ingredientsTypePDF
        case .text:  .ingredientsTypeText
        }
    }

    var icon: String {
        switch self {
        case .photo: "camera"
        case .pdf:   "doc.fill"
        case .text:  "text.alignleft"
        }
    }
}

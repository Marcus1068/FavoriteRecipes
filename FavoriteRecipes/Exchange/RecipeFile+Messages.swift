import Foundation

extension RecipeFile.ReadError {
    /// A short explanation for the alert shown when a file cannot be opened.
    var message: LocalizedStringResource {
        switch self {
        case .tooLarge:       .recipeFileTooLarge
        case .unreadable:     .recipeFileCouldNotBeRead
        case .notARecipeFile: .recipeFileUnreadable
        case .newerVersion:   .recipeFileNewerVersion
        }
    }
}

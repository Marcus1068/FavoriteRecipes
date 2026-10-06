import Foundation

/// Something the recipes screen should do, requested from outside it
/// (menu commands, URL links, Shortcuts).
enum AppAction: Equatable {
    case newRecipe
    case importRecipe(address: String?)
    /// A `.favoriterecipe` file that was opened in the app (AirDrop, Messages, Files).
    case openRecipeFile(URL)
}

/// Something the recipes screen should do, requested from outside it
/// (menu commands, URL links, Shortcuts).
enum AppAction: Equatable {
    case newRecipe
    case importRecipe(address: String?)
}

import Foundation
import SwiftData

extension Recipe {
    /// An unsaved copy to start a variation from. It gets a new id and creation date,
    /// is not a favorite and has no rating or cooking history.
    func makeCopy(named copyName: String) -> Recipe {
        let copy = RecipeSnapshot(self).makeRecipe()
        copy.id = UUID()
        copy.name = copyName
        copy.createdAt = .now
        copy.isFavorite = false
        copy.rating = 0
        copy.cookHistoryData = nil
        return copy
    }

    /// Saves a copy named "<name> (copy)" and returns it, e.g. to open it for editing.
    @discardableResult
    func duplicate(in context: ModelContext) -> Recipe {
        let copy = makeCopy(named: String(localized: .copyOfName(displayName)))
        context.insert(copy)
        return copy
    }
}

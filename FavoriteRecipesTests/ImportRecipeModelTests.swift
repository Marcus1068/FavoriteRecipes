import Testing
@testable import FavoriteRecipes

struct ImportRecipeModelTests {
    @Test func cannotImportBlankAddress() {
        let model = ImportRecipeModel()
        model.urlText = "   "
        #expect(model.canImport == false)
    }

    @Test func invalidAddressShowsErrorWithoutNetworkAccess() async {
        let model = ImportRecipeModel()
        model.urlText = "not a url"
        let draft = await model.importRecipe()
        #expect(draft == nil)
        #expect(model.errorMessage == RecipeWebImporter.ImportError.invalidURL.errorDescription)
        #expect(model.isImporting == false)
    }
}

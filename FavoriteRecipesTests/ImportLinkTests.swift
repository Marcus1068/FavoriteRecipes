import Foundation
import Testing
@testable import FavoriteRecipes

struct ImportLinkTests {
    @Test func readsTheRecipeAddress() throws {
        let link = try #require(URL(string: "favoriterecipes://import?url=https%3A%2F%2Fexample.com%2Frecipe%3Fid%3D1"))
        #expect(ImportLink.recipeAddress(in: link) == "https://example.com/recipe?id=1")
    }

    @Test func buildsLinksThatReadBack() throws {
        let address = "https://example.com/a b?x=1&y=2"
        let link = try #require(ImportLink.link(forAddress: address))
        #expect(ImportLink.recipeAddress(in: link) == address)
    }

    @Test func ignoresOtherLinks() throws {
        #expect(ImportLink.recipeAddress(in: try #require(URL(string: "https://example.com"))) == nil)
        #expect(ImportLink.recipeAddress(in: try #require(URL(string: "favoriterecipes://open?url=x"))) == nil)
        #expect(ImportLink.recipeAddress(in: try #require(URL(string: "favoriterecipes://import"))) == nil)
        #expect(ImportLink.recipeAddress(in: try #require(URL(string: "favoriterecipes://import?url="))) == nil)
    }
}

@MainActor
struct ImportRequestTests {
    @Test func requestIsConsumedOnce() {
        let navigation = AppNavigation()
        navigation.selectedTab = .options
        navigation.request(.importRecipe(address: "https://example.com"))
        #expect(navigation.selectedTab == .recipes)
        #expect(navigation.consumeRequestedAction() == .importRecipe(address: "https://example.com"))
        #expect(navigation.consumeRequestedAction() == nil)
    }
}

@MainActor
struct PasteFallbackTests {
    private func model(assistant: Bool, organize: @escaping (String) async throws -> RecipeSuggestion = { _ in throw CancellationError() }) -> ImportRecipeModel {
        ImportRecipeModel(isAssistantAvailable: { assistant }, organize: organize)
    }

    @Test func fallbackIsOfferedOnlyAfterAFailure() async {
        let model = model(assistant: false)
        #expect(!model.offersPasteFallback)
        model.urlText = "not a url"
        _ = await model.importRecipe()
        #expect(model.offersPasteFallback)
    }

    @Test func pastedTextBecomesADraftWithoutAssistant() async {
        let model = model(assistant: false)
        model.urlText = "example.com/recipe"
        model.pastedText = "  400 g pasta\n2 eggs  "
        let draft = await model.draftFromPastedText()
        #expect(draft?.ingredientsText == "400 g pasta\n2 eggs")
        #expect(draft?.ingredientsType == .text)
        #expect(draft?.sourceURLString == "https://example.com/recipe")
        #expect(draft?.name == "")
    }

    @Test func blankPastedTextGivesNoDraft() async {
        let model = model(assistant: false)
        model.pastedText = "  \n "
        #expect(!model.canUsePastedText)
        #expect(await model.draftFromPastedText() == nil)
    }

    @Test func assistantFailureStillKeepsTheText() async {
        let model = model(assistant: true)
        model.pastedText = "some recipe"
        #expect(await model.draftFromPastedText()?.ingredientsText == "some recipe")
    }

    @Test func prefilledAddressEnablesImport() {
        let model = ImportRecipeModel(urlText: "https://example.com/r")
        #expect(model.canImport)
    }
}

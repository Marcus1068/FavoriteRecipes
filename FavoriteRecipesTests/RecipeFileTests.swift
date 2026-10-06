import Foundation
import Testing
@testable import FavoriteRecipes

@MainActor
struct RecipeFileTests {
    private func sampleRecipe() -> Recipe {
        let recipe = Recipe(name: "Spaghetti Carbonara", category: .noodles, isFavorite: true)
        recipe.ingredientsType = .photo
        recipe.ingredientsText = "400 g spaghetti\n4 egg yolks"
        recipe.instructions = "1. Boil\n2. Mix"
        recipe.notes = "Less salt"
        recipe.sourceURLString = "https://example.com/carbonara"
        recipe.servings = 4
        recipe.prepMinutes = 10
        recipe.cookMinutes = 20
        recipe.rating = 5
        recipe.tags = ["weeknight", "italian"]
        recipe.recipeImageData = Data([1, 2, 3])
        recipe.ingredientsImageData = Data([4, 5])
        recipe.markCooked(note: "great")
        return recipe
    }

    @Test func roundTripKeepsTheRecipeContent() throws {
        let original = sampleRecipe()
        let data = try RecipeFile(original).encoded()
        let draft = try RecipeFile.decode(data).makeDraft()

        #expect(draft.name == "Spaghetti Carbonara")
        #expect(draft.category == .noodles)
        #expect(draft.ingredientsType == .photo)
        #expect(draft.ingredientsText == "400 g spaghetti\n4 egg yolks")
        #expect(draft.instructions == "1. Boil\n2. Mix")
        #expect(draft.notes == "Less salt")
        #expect(draft.sourceURLString == "https://example.com/carbonara")
        #expect(draft.servings == 4 && draft.prepMinutes == 10 && draft.cookMinutes == 20)
        #expect(draft.rating == 5)
        #expect(draft.tags == ["weeknight", "italian"])
        #expect(draft.recipeImageData == Data([1, 2, 3]))
        #expect(draft.ingredientsImageData == Data([4, 5]))
    }

    @Test func aDraftIsANewRecipeWithoutPersonalHistory() throws {
        let original = sampleRecipe()
        let draft = try RecipeFile.decode(RecipeFile(original).encoded()).makeDraft()
        #expect(draft.id != original.id)
        #expect(!draft.isFavorite)
        #expect(draft.cookHistory.isEmpty)
    }

    @Test func unknownValuesFallBackToSafeOnes() {
        var file = RecipeFile(sampleRecipe())
        file.category = "Barbecue"
        file.ingredientsType = "Hologram"
        let draft = file.makeDraft()
        #expect(draft.category == .meat)
        #expect(draft.ingredientsType == .text)
    }

    @Test func numbersAreKeptInRange() {
        var file = RecipeFile(sampleRecipe())
        file.rating = 99
        file.servings = -3
        file.prepMinutes = 0
        file.cookMinutes = Int.max
        let draft = file.makeDraft()
        #expect(draft.rating == 5)
        #expect(draft.servings == nil)
        #expect(draft.prepMinutes == nil)
        #expect(draft.cookMinutes == 100_000)

        file.rating = -4
        #expect(file.makeDraft().rating == 0)
    }

    @Test func onlyWebAddressesBecomeTheSourceLink() {
        var file = RecipeFile(sampleRecipe())
        for bad in ["javascript:alert(1)", "file:///etc/passwd", "tel:123", "not a link", "   "] {
            file.sourceURLString = bad
            #expect(file.makeDraft().sourceURLString == nil, "\(bad) must not be kept")
        }
        file.sourceURLString = "http://example.com/a"
        #expect(file.makeDraft().sourceURLString == "http://example.com/a")
    }

    @Test func tagsAreCleanedAndLimited() {
        var file = RecipeFile(sampleRecipe())
        file.tags = ["  Quick ", "quick", "", String(repeating: "x", count: 500)] + (0..<100).map { "tag\($0)" }
        let tags = file.makeDraft().tags
        #expect(tags.first == "Quick")
        #expect(tags.count <= 50)
        #expect(tags.allSatisfy { $0.count <= 60 })
    }

    @Test func blankTextBecomesNil() {
        var file = RecipeFile(sampleRecipe())
        file.ingredientsText = "  \n "
        file.notes = ""
        let draft = file.makeDraft()
        #expect(draft.ingredientsText == nil)
        #expect(draft.notes == nil)
    }

    // MARK: - Refusing bad files

    @Test func refusesFilesThatAreNotRecipes() {
        #expect(throws: RecipeFile.ReadError.notARecipeFile) { try RecipeFile.decode(Data("hello".utf8)) }
        #expect(throws: RecipeFile.ReadError.notARecipeFile) { try RecipeFile.decode(Data("{}".utf8)) }
        #expect(throws: RecipeFile.ReadError.notARecipeFile) { try RecipeFile.decode(Data()) }
    }

    @Test func refusesOtherFormats() throws {
        var file = RecipeFile(sampleRecipe())
        file.format = "SomethingElse"
        #expect(throws: RecipeFile.ReadError.notARecipeFile) { try RecipeFile.decode(try file.encoded()) }
    }

    @Test func refusesFilesFromANewerVersion() throws {
        var file = RecipeFile(sampleRecipe())
        file.version = RecipeFile.currentVersion + 1
        #expect(throws: RecipeFile.ReadError.newerVersion) { try RecipeFile.decode(try file.encoded()) }
    }

    @Test func refusesHugeFiles() {
        let huge = Data(count: RecipeFile.maximumBytes + 1)
        #expect(throws: RecipeFile.ReadError.tooLarge) { try RecipeFile.decode(huge) }
    }

    // MARK: - Files on disk

    @Test func writesAndReadsAFileOnDisk() throws {
        let file = RecipeFile(sampleRecipe())
        let url = try file.writeTemporaryFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(url.pathExtension == "favoriterecipe")
        #expect(url.deletingPathExtension().lastPathComponent == "Spaghetti Carbonara")
        #expect(try RecipeFile.read(from: url) == file)
    }

    @Test func fileNamesAvoidTroublesomeCharacters() {
        var file = RecipeFile(sampleRecipe())
        file.name = "Mom's \"best\": pasta/sauce?"
        let name = file.suggestedFileName
        #expect(!name.contains("/") && !name.contains(":") && !name.contains("?") && !name.contains("\""))
        file.name = "   "
        #expect(file.suggestedFileName == "Recipe")
        file.name = String(repeating: "a", count: 300)
        #expect(file.suggestedFileName.count == 80)
    }

    @Test func readingAMissingFileSaysItCouldNotBeRead() {
        let url = URL(filePath: "/nonexistent/recipe.favoriterecipe")
        #expect(throws: RecipeFile.ReadError.unreadable) { try RecipeFile.read(from: url) }
    }

    @Test func everyErrorHasAMessage() {
        for error in [RecipeFile.ReadError.tooLarge, .unreadable, .notARecipeFile, .newerVersion] {
            #expect(!String(localized: error.message).isEmpty)
        }
    }

    @Test func openingAFileIsARequestForTheRecipesScreen() {
        let navigation = AppNavigation()
        let url = URL(filePath: "/tmp/x.favoriterecipe")
        navigation.request(.openRecipeFile(url))
        #expect(navigation.consumeRequestedAction() == .openRecipeFile(url))
    }
}

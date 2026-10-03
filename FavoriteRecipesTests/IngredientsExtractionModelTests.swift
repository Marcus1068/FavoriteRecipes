import Foundation
import Testing
@testable import FavoriteRecipes

@MainActor
struct IngredientsExtractionModelTests {
    private func model(imageText: String? = nil, pdfText: String? = nil) -> IngredientsExtractionModel {
        IngredientsExtractionModel(
            imageText: { _ in imageText },
            pdfText: { _ in pdfText },
            isAssistantAvailable: { false },
            organize: { _ in throw CancellationError() }
        )
    }

    @Test func storesRecognizedPhotoText() async {
        let recipe = Recipe()
        recipe.ingredientsType = .photo
        let model = model(imageText: "2 eggs")
        await model.extract(fromImageData: Data(), into: recipe, isNew: true)
        #expect(recipe.ingredientsText == "2 eggs")
        #expect(recipe.ingredientsType == .text)
        #expect(model.error == nil)
        #expect(model.message == nil)
    }

    @Test func reportsPhotoWithoutText() async {
        let recipe = Recipe()
        let model = model()
        await model.extract(fromImageData: Data(), into: recipe, isNew: true)
        #expect(model.error != nil)
        #expect(recipe.ingredientsText == nil)
        #expect(model.message == nil)
    }

    @Test func reportsPDFWithoutText() async {
        let recipe = Recipe()
        let model = model()
        await model.extract(fromPDFData: Data(), into: recipe, isNew: false)
        #expect(model.error != nil)
    }

    @Test func clearsEarlierErrorOnSuccess() async {
        let recipe = Recipe()
        let model = model(pdfText: "200 ml milk")
        model.error = .couldNotReadPDF
        await model.extract(fromPDFData: Data(), into: recipe, isNew: false)
        #expect(model.error == nil)
        #expect(recipe.ingredientsText == "200 ml milk")
    }
}

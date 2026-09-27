import Foundation
import UIKit

/// Downloads a recipe web page and turns its schema.org data into a draft `Recipe`.
enum RecipeWebImporter {

    enum ImportError: LocalizedError {
        case invalidURL
        case noRecipeFound
        case download

        var errorDescription: String? {
            switch self {
            case .invalidURL:    String(localized: .importErrorInvalidURL)
            case .noRecipeFound: String(localized: .importErrorNoRecipe)
            case .download:      String(localized: .importErrorDownload)
            }
        }
    }

    /// Accepts "example.com/recipe" as well as full URLs; only http(s) is allowed.
    static func normalizedURL(from input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text), url.host()?.contains(".") == true else { return nil }
        return url
    }

    /// Fetches the page and its main image. Throws `ImportError` on failure.
    static func fetch(from url: URL) async throws -> (recipe: ImportedRecipe, imageData: Data?) {
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let html: String
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw ImportError.download
            }
            // Most pages are UTF-8; fall back to Latin-1 for older sites.
            html = String(bytes: data, encoding: .utf8) ?? String(bytes: data, encoding: .isoLatin1) ?? ""
        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.download
        }

        guard let recipe = SchemaRecipeParser.parse(html: html, pageURL: url) else {
            throw ImportError.noRecipeFound
        }

        // The photo is optional: a failed image download should not fail the import.
        var imageData: Data?
        if let imageURL = recipe.imageURL,
           let (data, _) = try? await URLSession.shared.data(from: imageURL),
           let image = UIImage(data: data) {
            imageData = image.jpegDataFitting()
        }
        return (recipe, imageData)
    }

    /// Builds an unsaved draft; RecipeDetailView inserts it when the user taps Add.
    static func makeDraft(from imported: ImportedRecipe, imageData: Data?) -> Recipe {
        let recipe = Recipe(
            name: imported.name,
            category: RecipeCategory.guess(hints: imported.categoryHints, name: imported.name) ?? .meat
        )
        recipe.recipeImageData = imageData
        recipe.ingredientsType = .text
        recipe.ingredientsText = imported.ingredients.isEmpty ? nil : imported.ingredients.joined(separator: "\n")
        recipe.instructions = Recipe.numberedSteps(imported.instructions)
        recipe.servings = imported.servings
        recipe.prepMinutes = imported.prepMinutes
        recipe.cookMinutes = imported.cookMinutes
        recipe.sourceURLString = imported.sourceURL?.absoluteString
        return recipe
    }
}

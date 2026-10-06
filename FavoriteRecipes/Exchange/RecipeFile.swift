import Foundation

/// The contents of a shared recipe file. Plain values only, so it can be written and read off the main actor.
///
/// A file from someone else is untrusted data: it is read as a draft the user reviews,
/// every value is checked, and nothing in it is ever executed.
nonisolated struct RecipeFile: Codable, Equatable, Sendable {
    static let formatName = "FavoriteRecipes"
    static let currentVersion = 1
    /// Larger files are refused; photos and a PDF make a recipe a few megabytes at most.
    static let maximumBytes = 60 * 1_024 * 1_024

    var format = RecipeFile.formatName
    var version = RecipeFile.currentVersion
    var name: String
    var category: String
    var ingredientsType: String
    var ingredientsText: String?
    var instructions: String?
    var notes: String?
    var sourceURLString: String?
    var servings: Int?
    var prepMinutes: Int?
    var cookMinutes: Int?
    var rating: Int
    var tags: [String]
    var recipeImageData: Data?
    var ingredientsImageData: Data?
    var ingredientsPDFData: Data?

    // MARK: - Writing

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// A file name without characters that cause trouble in file systems.
    var suggestedFileName: String {
        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.controlCharacters)
        let cleaned = name.components(separatedBy: forbidden).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String((cleaned.isEmpty ? "Recipe" : cleaned).prefix(80))
    }

    /// Writes the file to a temporary location for the share sheet.
    func writeTemporaryFile() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: suggestedFileName).appendingPathExtension("favoriterecipe")
        try encoded().write(to: url, options: .atomic)
        return url
    }

    // MARK: - Reading

    enum ReadError: Error, Equatable {
        case tooLarge
        /// The file could not be opened at all, e.g. because it was removed in the meantime.
        case unreadable
        case notARecipeFile
        case newerVersion
    }

    /// Reads and checks the contents of a recipe file.
    static func decode(_ data: Data) throws -> RecipeFile {
        guard data.count <= maximumBytes else { throw ReadError.tooLarge }
        guard let file = try? JSONDecoder().decode(RecipeFile.self, from: data), file.format == formatName else {
            throw ReadError.notARecipeFile
        }
        guard file.version <= currentVersion else { throw ReadError.newerVersion }
        return file
    }

    /// Reads a file from disk, including files outside the app's sandbox.
    static func read(from url: URL) throws -> RecipeFile {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard size <= maximumBytes else { throw ReadError.tooLarge }
        guard let data = try? Data(contentsOf: url) else { throw ReadError.unreadable }
        return try decode(data)
    }
}

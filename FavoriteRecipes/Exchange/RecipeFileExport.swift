import CoreTransferable

/// What the share sheet sends: the recipe as a `.favoriterecipe` file.
nonisolated struct RecipeFileExport: Transferable, Sendable {
    let file: RecipeFile

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .favoriteRecipe) { export in
            SentTransferredFile(try export.file.writeTemporaryFile())
        }
    }
}

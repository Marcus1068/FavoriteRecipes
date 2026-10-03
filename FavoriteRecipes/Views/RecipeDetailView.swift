import SwiftUI
import SwiftData
import PhotosUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe
    /// A new recipe is a draft: it is only inserted into the model context
    /// when the user taps Add, so cancelling leaves nothing behind.
    var isNew = false

    // Photo pickers
    @State private var recipePhotoItem: PhotosPickerItem?
    @State private var ingredientsPhotoItem: PhotosPickerItem?

    // Sheet control
    @State private var showRecipeCamera      = false
    @State private var showIngredientsCamera = false
    @State private var showPDFPicker         = false

    @State private var extraction = IngredientsExtractionModel()

    // Confirmations
    @State private var recipeToDelete: Recipe?
    @State private var showDiscardConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                RecipePhotoSection(
                    recipe: recipe,
                    photoItem: $recipePhotoItem,
                    onTakePhoto: { showRecipeCamera = true }
                )
                RecipeNameSection(recipe: recipe)
                RecipeCategorySection(recipe: recipe)
                RecipeDetailsSection(recipe: recipe)
                RecipeIngredientsSection(
                    recipe: recipe,
                    extractionMessage: extraction.message,
                    extractionError: extraction.error,
                    photoItem: $ingredientsPhotoItem,
                    onTakePhoto: { showIngredientsCamera = true },
                    onChoosePDF: { showPDFPicker = true }
                )
                RecipeTextSection(
                    title: .instructions,
                    systemImage: "list.number",
                    placeholder: .instructionsPlaceholder,
                    text: $recipe.instructions
                )
                RecipeTextSection(
                    title: .notes,
                    systemImage: "note.text",
                    placeholder: .notesPlaceholder,
                    text: $recipe.notes
                )
                RecipeSourceSection(recipe: recipe)
                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            recipeToDelete = recipe
                        } label: {
                            Label(.deleteRecipe, systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(recipe.name.isEmpty ? String(localized: .newRecipe) : recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isNew {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(.cancel, action: cancelDraft)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(.add, action: addDraft)
                            .disabled(!recipe.hasContent)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(.done) { dismiss() }
                    }
                }
            }
            // Swiping a draft away would silently lose what was entered.
            .interactiveDismissDisabled(isNew && recipe.hasContent)
            .confirmationDialog(
                Text(.discardRecipeConfirmTitle),
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button(.discard, role: .destructive) { dismiss() }
                Button(.keepEditing, role: .cancel) {}
            }
            .confirmDeletion(of: $recipeToDelete) { recipe in
                modelContext.delete(recipe)
                dismiss()
            }
            // Camera sheets (unavailable on Mac Catalyst)
#if !targetEnvironment(macCatalyst)
            .sheet(isPresented: $showRecipeCamera) {
                CameraPickerView { data in recipe.recipeImageData = data }
            }
            .sheet(isPresented: $showIngredientsCamera) {
                CameraPickerView { data in
                    recipe.ingredientsImageData = data
                    extractText(fromImageData: data)
                }
            }
#endif
            .fileImporter(isPresented: $showPDFPicker, allowedContentTypes: [.pdf]) { result in
                guard case .success(let url) = result else { return }
                guard let data = Self.readSecurityScoped(url) else {
                    extraction.error = .couldNotReadPDF
                    return
                }
                recipe.ingredientsPDFData = data
                extractText(fromPDFData: data)
            }
            // Photo transfers
            .onChange(of: recipePhotoItem) { _, item in
                guard let item else { return }
                Task {
                    guard let image = await loadImage(from: item) else {
                        extraction.error = .couldNotLoadPhoto
                        return
                    }
                    recipe.recipeImageData = image.jpegDataFitting()
                }
            }
            .onChange(of: ingredientsPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    guard let image = await loadImage(from: item) else {
                        extraction.error = .couldNotLoadPhoto
                        return
                    }
                    guard let data = image.jpegDataFitting() else {
                        extraction.error = .couldNotLoadPhoto
                        return
                    }
                    recipe.ingredientsImageData = data
                    extractText(fromImageData: data)
                }
            }
        }
    }

    // MARK: - Draft handling

    private func addDraft() {
        modelContext.insert(recipe)
        dismiss()
    }

    private func cancelDraft() {
        if recipe.hasContent {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    // MARK: - File import

    /// Loads the picked photo; nil when the transfer fails or the data isn't an image.
    private func loadImage(from item: PhotosPickerItem) async -> UIImage? {
        guard let raw = try? await item.loadTransferable(type: Data.self) else { return nil }
        return UIImage(data: raw)
    }

    /// Reads a file picked with `fileImporter`, which is outside the sandbox.
    private static func readSecurityScoped(_ url: URL) -> Data? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        return try? Data(contentsOf: url)
    }

    // MARK: - Text extraction

    private func extractText(fromImageData data: Data) {
        Task { await extraction.extract(fromImageData: data, into: recipe, isNew: isNew) }
    }

    private func extractText(fromPDFData data: Data) {
        Task { await extraction.extract(fromPDFData: data, into: recipe, isNew: isNew) }
    }
}

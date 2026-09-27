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

    // Text extraction state
    @State private var extractionMessage: LocalizedStringResource?
    @State private var extractionError: LocalizedStringResource?

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
                    extractionMessage: extractionMessage,
                    extractionError: extractionError,
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
                    extractAndStoreText(imageData: data)
                }
            }
#endif
            .fileImporter(isPresented: $showPDFPicker, allowedContentTypes: [.pdf]) { result in
                guard case .success(let url) = result, let data = Self.readSecurityScoped(url) else { return }
                recipe.ingredientsPDFData = data
                extractAndStoreText(pdfData: data)
            }
            // Photo transfers
            .onChange(of: recipePhotoItem) { _, item in
                Task {
                    if let raw = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: raw) {
                        recipe.recipeImageData = image.jpegDataFitting()
                    }
                }
            }
            .onChange(of: ingredientsPhotoItem) { _, item in
                Task {
                    if let raw  = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: raw) {
                        let data = image.jpegDataFitting()
                        recipe.ingredientsImageData = data
                        extractAndStoreText(imageData: data)
                    }
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

    /// Reads a file picked with `fileImporter`, which is outside the sandbox.
    private static func readSecurityScoped(_ url: URL) -> Data? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        return try? Data(contentsOf: url)
    }

    // MARK: - Text extraction

    /// Reads text from the photo or PDF, stores it as the ingredients text and
    /// switches to the text tab so it can be checked. When Apple Intelligence is
    /// available, the text is then organized into ingredients and steps.
    private func extractAndStoreText(imageData: Data? = nil, pdfData: Data? = nil) {
        extractionError = nil
        extractionMessage = .extractingText
        Task {
            defer { extractionMessage = nil }

            let text: String?
            if let imageData {
                text = await TextExtractor.text(fromImageData: imageData)
            } else if let pdfData {
                text = await TextExtractor.text(fromPDFData: pdfData)
            } else {
                text = nil
            }
            guard let text else {
                extractionError = imageData != nil ? .noTextRecognizedInPhoto : .noTextFoundInPDF
                return
            }

            recipe.ingredientsText = text
            recipe.ingredientsType = .text

            guard RecipeAssistant.isAvailable else { return }
            extractionMessage = .organizingRecipe
            // Best effort: if the model fails, the raw text is already in place.
            if let suggestion = try? await RecipeAssistant.structure(text) {
                recipe.applySuggestion(
                    name: suggestion.name,
                    category: suggestion.category.recipeCategory,
                    ingredients: suggestion.ingredients,
                    steps: suggestion.steps,
                    updatingCategory: isNew
                )
            }
        }
    }
}

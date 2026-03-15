import SwiftUI
import SwiftData
import PhotosUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var recipe: Recipe

    // Photo pickers
    @State private var recipePhotoItem: PhotosPickerItem?
    @State private var ingredientsPhotoItem: PhotosPickerItem?

    // Sheet control
    @State private var showRecipeCamera = false
    @State private var showIngredientsCamera = false
    @State private var showPDFPicker = false

    var body: some View {
        NavigationStack {
            Form {
                recipePhotoSection
                nameSection
                categorySection
                ingredientsSection
                deleteSection
            }
            .navigationTitle(recipe.name.isEmpty ? "New Recipe" : recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            // Camera sheets
            .sheet(isPresented: $showRecipeCamera) {
                CameraPickerView { data in recipe.recipeImageData = data }
            }
            .sheet(isPresented: $showIngredientsCamera) {
                CameraPickerView { data in recipe.ingredientsImageData = data }
            }
            // PDF picker
            .sheet(isPresented: $showPDFPicker) {
                DocumentPicker { data in
                    recipe.ingredientsPDFData = data
                    showPDFPicker = false
                }
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
                    if let raw = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: raw) {
                        recipe.ingredientsImageData = image.jpegDataFitting()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var recipePhotoSection: some View {
        Section {
            if let data = recipe.recipeImageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)
                Button(role: .destructive) {
                    recipe.recipeImageData = nil
                } label: {
                    Label("Remove Photo", systemImage: "xmark.circle")
                }
            }
            PhotosPicker(selection: $recipePhotoItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            #if !targetEnvironment(macCatalyst)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showRecipeCamera = true } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            #endif
        } header: {
            Label("Recipe Photo", systemImage: "camera.fill")
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Enter recipe name…", text: $recipe.name)
        } header: {
            Label("Name", systemImage: "textformat")
        }
    }

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $recipe.category) {
                ForEach(RecipeCategory.allCases) { cat in
                    HStack {
                        Text(cat.icon)
                        Text(cat.rawValue)
                    }
                    .tag(cat)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        } header: {
            Label("Category", systemImage: "tag.fill")
        }
    }

    private var ingredientsSection: some View {
        Section {
            Picker("Type", selection: $recipe.ingredientsType) {
                ForEach(IngredientsType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)

            switch recipe.ingredientsType {
            case .photo:  ingredientsPhotoContent
            case .pdf:    ingredientsPDFContent
            case .text:   ingredientsTextContent
            }
        } header: {
            Label("Ingredients", systemImage: "list.bullet")
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                modelContext.delete(recipe)
                dismiss()
            } label: {
                Label("Delete Recipe", systemImage: "trash")
            }
        }
    }

    // MARK: - Ingredients Content

    @ViewBuilder
    private var ingredientsPhotoContent: some View {
        if let data = recipe.ingredientsImageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity)
            Button(role: .destructive) {
                recipe.ingredientsImageData = nil
            } label: {
                Label("Remove Photo", systemImage: "xmark.circle")
            }
        }
        PhotosPicker(selection: $ingredientsPhotoItem, matching: .images) {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        #if !targetEnvironment(macCatalyst)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button { showIngredientsCamera = true } label: {
                Label("Take Photo", systemImage: "camera")
            }
        }
        #endif
    }

    @ViewBuilder
    private var ingredientsPDFContent: some View {
        if let data = recipe.ingredientsPDFData {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PDF Loaded")
                        .font(.headline)
                    Text("\(data.count / 1024) KB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Button(role: .destructive) {
                recipe.ingredientsPDFData = nil
            } label: {
                Label("Remove PDF", systemImage: "xmark.circle")
            }
        }
        Button { showPDFPicker = true } label: {
            Label(
                recipe.ingredientsPDFData == nil ? "Choose PDF" : "Replace PDF",
                systemImage: "doc.badge.plus"
            )
        }
    }

    @ViewBuilder
    private var ingredientsTextContent: some View {
        ZStack(alignment: .topLeading) {
            if (recipe.ingredientsText ?? "").isEmpty {
                Text("Enter ingredients here…")
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: Binding(
                get: { recipe.ingredientsText ?? "" },
                set: { recipe.ingredientsText = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 150)
        }
    }
}

import SwiftUI
import SwiftData

struct OptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]

    @State private var showConfirmGenerate = false
    @State private var showConfirmDelete   = false
    @State private var generationDone      = false
    @AppStorage("inspireMeIncludesFavorites") private var inspireIncludesFavorites = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: Inspire Me
                Section {
                    Toggle(isOn: $inspireIncludesFavorites) {
                        Label(.inspireMeIncludesFavorites, systemImage: "heart")
                    }
                } header: {
                    Label(.inspireMe, systemImage: "sparkles")
                } footer: {
                    Text(.inspireMeFooter)
                }

                // MARK: Sample Data (developer tool: needs sample images in the asset catalog)
                #if DEBUG
                Section {
                    Button {
                        showConfirmGenerate = true
                    } label: {
                        Label(.generateSampleRecipes, systemImage: "wand.and.stars")
                    }
                    .confirmationDialog(
                        Text(.generateSampleRecipesConfirmTitle),
                        isPresented: $showConfirmGenerate,
                        titleVisibility: .visible
                    ) {
                        Button(.generate) {
                            SampleDataGenerator.generate(in: modelContext)
                            generationDone = true
                        }
                        Button(.cancel, role: .cancel) {}
                    } message: {
                        Text(.generateSampleRecipesConfirmMessage)
                    }
                } header: {
                    Label(.sampleData, systemImage: "doc.badge.plus")
                } footer: {
                    Text(.sampleDataFooter)
                }
                #endif

                // MARK: Data
                Section {
                    Button(role: .destructive) {
                        showConfirmDelete = true
                    } label: {
                        Label(.deleteAllRecipes, systemImage: "trash")
                    }
                    .confirmationDialog(
                        Text(.deleteAllRecipesConfirmTitle),
                        isPresented: $showConfirmDelete,
                        titleVisibility: .visible
                    ) {
                        Button(.deleteAll, role: .destructive) {
                            recipes.forEach { modelContext.delete($0) }
                        }
                        Button(.cancel, role: .cancel) {}
                    } message: {
                        Text(.deleteAllRecipesConfirmMessage(recipes.count))
                    }
                    .disabled(recipes.isEmpty)
                } header: {
                    Label(.data, systemImage: "externaldrive")
                }

                // MARK: Stats
                Section {
                    LabeledContent(.totalRecipes, value: recipes.count, format: .number)
                    LabeledContent(.favorites, value: recipes.filter(\.isFavorite).count, format: .number)
                    ForEach(RecipeCategory.allCases) { cat in
                        LabeledContent(cat.localizedName) {
                            Text(recipes.filter { $0.category == cat }.count, format: .number)
                                .foregroundStyle(cat.color)
                        }
                    }
                } header: {
                    Label(.statistics, systemImage: "chart.bar")
                }
            }
            .navigationTitle(.options)
            .alert(.sampleRecipesGeneratedTitle, isPresented: $generationDone) {
                Button(.ok, role: .cancel) {}
            } message: {
                Text(.sampleRecipesGeneratedMessage)
            }
        }
    }
}

#Preview {
    OptionsView()
        .modelContainer(for: Recipe.self, inMemory: true)
}

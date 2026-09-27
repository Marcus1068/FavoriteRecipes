import SwiftUI
import SwiftData

struct OptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]

    @State private var showConfirmGenerate = false
    @State private var showConfirmDelete   = false
    @State private var generationDone      = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: Sample Data
                Section {
                    // Generate
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

                    // Delete all
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

                } header: {
                    Label(.sampleData, systemImage: "doc.badge.plus")
                } footer: {
                    Text(.sampleDataFooter)
                }

                // MARK: Stats
                Section {
                    LabeledContent(.totalRecipes, value: "\(recipes.count)")
                    LabeledContent(.favorites, value: "\(recipes.filter { $0.isFavorite }.count)")
                    ForEach(RecipeCategory.allCases) { cat in
                        LabeledContent(cat.localizedName) {
                            Text("\(recipes.filter { $0.category == cat }.count)")
                                .foregroundStyle(cat.color)
                        }
                    }
                } header: {
                    Label(.statistics, systemImage: "chart.bar")
                }

                // MARK: Placeholder
                Section {
                    Label(.moreOptionsComingSoon, systemImage: "gear.circle")
                        .foregroundStyle(.secondary)
                } header: {
                    Label(.general, systemImage: "gear")
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

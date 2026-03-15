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
                        Label("Generate Sample Recipes", systemImage: "wand.and.stars")
                    }
                    .confirmationDialog(
                        "Generate 12 sample recipes?",
                        isPresented: $showConfirmGenerate,
                        titleVisibility: .visible
                    ) {
                        Button("Generate") {
                            SampleDataGenerator.generate(in: modelContext)
                            generationDone = true
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Existing recipes with the same name are skipped. You can edit or delete them afterwards.")
                    }

                    // Delete all
                    Button(role: .destructive) {
                        showConfirmDelete = true
                    } label: {
                        Label("Delete All Recipes", systemImage: "trash")
                    }
                    .confirmationDialog(
                        "Delete all recipes?",
                        isPresented: $showConfirmDelete,
                        titleVisibility: .visible
                    ) {
                        Button("Delete All", role: .destructive) {
                            recipes.forEach { modelContext.delete($0) }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently remove all \(recipes.count) recipe(s).")
                    }

                } header: {
                    Label("Sample Data", systemImage: "doc.badge.plus")
                } footer: {
                    Text("Sample photos must be added to the asset catalog imagesets (e.g. sample_carbonara) before generation. Recipe names, categories and ingredients can be edited afterwards.")
                }

                // MARK: Stats
                Section {
                    LabeledContent("Total recipes", value: "\(recipes.count)")
                    LabeledContent("Favourites",    value: "\(recipes.filter { $0.isFavorite }.count)")
                    ForEach(RecipeCategory.allCases) { cat in
                        LabeledContent(cat.rawValue) {
                            Text("\(recipes.filter { $0.category == cat }.count)")
                                .foregroundStyle(cat.color)
                        }
                    }
                } header: {
                    Label("Statistics", systemImage: "chart.bar")
                }

                // MARK: Placeholder
                Section {
                    Label("More options coming soon…", systemImage: "gear.circle")
                        .foregroundStyle(.secondary)
                } header: {
                    Label("General", systemImage: "gear")
                }
            }
            .navigationTitle("Options")
            .alert("Sample recipes generated!", isPresented: $generationDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("12 sample recipes were added. Tap any recipe card to edit its details.")
            }
        }
    }
}

#Preview {
    OptionsView()
        .modelContainer(for: Recipe.self, inMemory: true)
}

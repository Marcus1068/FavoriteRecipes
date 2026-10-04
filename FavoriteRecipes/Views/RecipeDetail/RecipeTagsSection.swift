import SwiftUI

/// Tags for a recipe: existing ones as removable chips, plus a field to add more.
struct RecipeTagsSection: View {
    @Bindable var recipe: Recipe
    /// Tags already used elsewhere, offered as one-tap suggestions.
    let knownTags: [String]

    @State private var newTag = ""

    private var suggestions: [String] {
        knownTags.filter { known in
            !recipe.tags.contains { $0.localizedCaseInsensitiveCompare(known) == .orderedSame }
        }
    }

    var body: some View {
        Section {
            if !recipe.tags.isEmpty {
                FlowLayout {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Button(tag, systemImage: "xmark.circle.fill", action: { remove(tag) })
                            .labelStyle(.titleAndIcon)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                            .accessibilityLabel(Text(.removeTagLabel(tag)))
                    }
                }
            }

            TextField(.addTagPlaceholder, text: $newTag)
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit { add(newTag) }

            if !suggestions.isEmpty {
                FlowLayout {
                    ForEach(suggestions, id: \.self) { tag in
                        Button(tag, systemImage: "plus", action: { add(tag) })
                            .labelStyle(.titleAndIcon)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                            .accessibilityLabel(Text(.addTagLabel(tag)))
                    }
                }
            }
        } header: {
            Label(.tags, systemImage: "number")
        }
    }

    private func add(_ text: String) {
        recipe.tags = TagList.normalize(recipe.tags + TagList.parse(text))
        newTag = ""
    }

    private func remove(_ tag: String) {
        recipe.tags.removeAll { $0 == tag }
    }
}

import SwiftUI

/// Toolbar menu for the sort order, minimum rating and tag filter.
struct SortFilterMenu: View {
    @Binding var filter: RecipeFilter
    let availableTags: [String]

    var body: some View {
        Menu {
            Section(.sortBy) {
                Picker(.sortBy, selection: $filter.sort) {
                    ForEach(RecipeSort.allCases) { sort in
                        Label(sort.localizedName, systemImage: sort.icon).tag(sort)
                    }
                }
                .pickerStyle(.inline)
            }

            Section(.minimumRating) {
                Picker(.minimumRating, selection: $filter.minimumRating) {
                    Text(.anyRating).tag(0)
                    ForEach(1...5, id: \.self) { stars in
                        Text(.ratingAtLeast(stars)).tag(stars)
                    }
                }
                .pickerStyle(.inline)
            }

            if !availableTags.isEmpty {
                Section(.tag) {
                    Picker(.tag, selection: $filter.tag) {
                        Text(.anyTag).tag(String?.none)
                        ForEach(availableTags, id: \.self) { tag in
                            Text(tag).tag(String?.some(tag))
                        }
                    }
                    .pickerStyle(.inline)
                }
            }

            if filter.hasExtraFilters {
                Button(.resetFilters, systemImage: "xmark.circle") {
                    filter.minimumRating = 0
                    filter.tag = nil
                }
            }
        } label: {
            Label(.sortAndFilter, systemImage: filter.hasExtraFilters
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
    }
}

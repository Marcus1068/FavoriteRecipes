import SwiftUI

/// The shopping tab: ticked items, the recipes behind them, and ways to take the list to the shop.
struct ShoppingListView: View {
    @Environment(ShoppingStore.self) private var store
    @State private var showClearConfirmation = false
    @State private var reminderMessage: LocalizedStringResource?

    /// Replaceable so tests can run without the Reminders app.
    var reminders: any RemindersExporting = RemindersExporter()

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    ContentUnavailableView {
                        Label(.shoppingListEmptyTitle, systemImage: "cart")
                    } description: {
                        Text(.shoppingListEmptyMessage)
                    }
                } else {
                    List {
                        Section {
                            ForEach(store.items) { item in
                                ShoppingItemRow(item: item, isChecked: store.isChecked(item)) {
                                    store.toggle(item)
                                }
                            }
                        } header: {
                            Text(.shoppingItems)
                        }

                        Section {
                            ForEach(store.recipes) { recipe in
                                ShoppingRecipeRow(recipe: recipe)
                                    .swipeActions {
                                        Button(.shoppingRemoveRecipe, systemImage: "trash", role: .destructive) {
                                            store.remove(recipe)
                                        }
                                    }
                            }
                        } header: {
                            Text(.shoppingRecipes)
                        }
                    }
                }
            }
            .navigationTitle(.shoppingListTitle)
            .toolbar {
                if !store.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            ShareLink(item: store.shareText) {
                                Label(.shoppingShare, systemImage: "square.and.arrow.up")
                            }
                            Button(.shoppingSendToReminders, systemImage: "checklist", action: sendToReminders)
                                .accessibilityIdentifier("shopping.reminders")
                            Divider()
                            Button(.shoppingClearChecked, systemImage: "checkmark.circle", action: store.clearChecked)
                                .accessibilityIdentifier("shopping.clearChecked")
                            Button(.shoppingClearAll, systemImage: "trash", role: .destructive) {
                                showClearConfirmation = true
                            }
                            .accessibilityIdentifier("shopping.clearAll")
                        } label: {
                            Label(.shoppingListTitle, systemImage: "ellipsis.circle")
                        }
                        .accessibilityIdentifier("shopping.menu")
                    }
                }
            }
            .confirmationDialog(.shoppingClearAllConfirm, isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button(.shoppingClearAll, role: .destructive, action: store.clearAll)
                    .accessibilityIdentifier("shopping.confirmClearAll")
            }
            .alert(
                Text(reminderMessage ?? .remindersAdded),
                isPresented: Binding(get: { reminderMessage != nil }, set: { if !$0 { reminderMessage = nil } })
            ) {}
        }
    }

    private func sendToReminders() {
        let items = store.openItemTexts
        Task {
            do {
                try await reminders.add(items: items, listName: String(localized: .shoppingListTitle))
                reminderMessage = .remindersAdded
            } catch RemindersError.accessDenied {
                reminderMessage = .remindersDenied
            } catch {
                reminderMessage = .remindersFailed
            }
        }
    }
}

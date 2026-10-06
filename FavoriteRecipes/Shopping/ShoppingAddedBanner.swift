import SwiftUI

/// "Added to the shopping list" banner at the top of the screen. It hides itself after a few seconds.
struct ShoppingAddedBanner: View {
    let store: ShoppingStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let title = store.lastAddedTitle {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.addedToShoppingList).font(.subheadline.bold())
                        Text(title).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                    }
                } icon: {
                    Image(systemName: "cart.badge.plus")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .padding(.horizontal)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .accessibilityIdentifier("shoppingAddedBanner")
            }
            Spacer()
        }
        .animation(.default, value: store.lastAddedTitle)
        .task(id: store.addedCount) {
            guard store.lastAddedTitle != nil else { return }
            AccessibilityNotification.Announcement(String(localized: .addedToShoppingList)).post()
            try? await Task.sleep(for: .seconds(3))
            store.dismissAddedNotice()
        }
        .allowsHitTesting(false)
    }
}

import SwiftUI

/// Reports a presented screen to `AppNavigation` and closes it when something else
/// (an import link, Siri, Spotlight) needs the recipes screen.
///
/// A screen that holds unsaved work is `isProtected`: it stays open, and the request waits
/// until the user closes it.
struct PresentationTracking: ViewModifier {
    let isProtected: Bool

    @Environment(AppNavigation.self) private var navigation
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .onAppear { navigation.presentationStarted() }
            .onDisappear { navigation.presentationEnded() }
            .onChange(of: navigation.requestedAction) { _, action in
                if action != nil, !isProtected { dismiss() }
            }
            .onChange(of: navigation.pendingRecipeID) { _, id in
                if id != nil, !isProtected { dismiss() }
            }
    }
}

extension View {
    /// See `PresentationTracking`.
    func tracksPresentation(isProtected: Bool = false) -> some View {
        modifier(PresentationTracking(isProtected: isProtected))
    }
}

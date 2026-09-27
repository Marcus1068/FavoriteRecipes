import UIKit
import SwiftUI

// MARK: - UIView subclass

/// A clear, non-interactive UIView that holds first-responder status and
/// routes left/right arrow key presses to SwiftUI callbacks.
///
/// Why UIViewRepresentable / pressesBegan instead of SwiftUI onKeyPress or
/// keyboardShortcut:
///
/// • onKeyPress requires the view to hold UIKit first-responder focus.
///   GeometryReader (the root of CarouselView) cannot become first responder,
///   so events never arrive regardless of @FocusState configuration.
///
/// • keyboardShortcut(.leftArrow, modifiers:[]) creates a UIKeyCommand that
///   in theory doesn't need focus, but SwiftUI collapses zero-sized host views
///   on Mac Catalyst and strips them from the effective responder chain.
///
/// pressesBegan is the lowest-level UIKit mechanism — reliable on both
/// Mac Catalyst and iPad with a hardware keyboard.
final class ArrowKeyView: UIView {
    var onLeft: (() -> Void)?
    var onRight: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            // Defer to next run-loop so SwiftUI's layout pass finishes first.
            DispatchQueue.main.async { [weak self] in
                self?.becomeFirstResponder()
            }
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            switch press.key?.keyCode {
            case .keyboardLeftArrow:
                onLeft?()
                handled = true
            case .keyboardRightArrow:
                onRight?()
                handled = true
            default:
                break
            }
        }
        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }}

// MARK: - SwiftUI wrapper

/// Drop into any view hierarchy. The view is transparent and non-interactive
/// by pointer/touch. It acquires and re-acquires UIKit first-responder status
/// automatically.
///
/// Place it as an .overlay on the content area that should respond to arrows.
/// updateUIView is called on every SwiftUI state change (e.g. sheet dismiss),
/// which is where we re-acquire first responder after a modal closes.
struct KeyboardNavigationHandler: UIViewRepresentable {
    let onLeft: () -> Void
    let onRight: () -> Void

    func makeUIView(context: Context) -> ArrowKeyView {
        let view = ArrowKeyView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false // pass touches through
        view.onLeft = onLeft
        view.onRight = onRight
        return view
    }

    func updateUIView(_ uiView: ArrowKeyView, context: Context) {
        // Always refresh closures so they capture the latest state values.
        uiView.onLeft = onLeft
        uiView.onRight = onRight

        // Re-acquire first responder after state transitions (e.g. sheet
        // dismiss sets newRecipe = nil → SwiftUI re-renders → updateUIView).
        if !uiView.isFirstResponder, uiView.window != nil {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
    }
}

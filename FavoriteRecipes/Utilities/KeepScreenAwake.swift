import SwiftUI

extension View {
    /// Stops the screen from dimming and locking while this view is on screen.
    func keepScreenAwake() -> some View {
        onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

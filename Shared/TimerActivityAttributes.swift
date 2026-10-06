import Foundation

#if !targetEnvironment(macCatalyst)
import ActivityKit

/// Describes a timer shown as a Live Activity on the lock screen and in the Dynamic Island.
/// This file is part of both the app and the widget extension.
nonisolated struct TimerActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        /// When the timer ends. The countdown is drawn by the system from this date, so the app does not update it every second.
        var endDate: Date
        /// True once the time is up.
        var isFinished: Bool
    }

    /// The timer's id, to match the activity to a timer.
    var timerID: UUID
    /// What the timer is for, e.g. the recipe name.
    var title: String
}
#endif

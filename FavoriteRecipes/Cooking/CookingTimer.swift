import Foundation

/// A running kitchen timer.
struct CookingTimer: Identifiable, Equatable {
    let id: UUID
    /// What the timer is for, e.g. "Mushroom Risotto · 10 min".
    var title: String
    var endDate: Date
}

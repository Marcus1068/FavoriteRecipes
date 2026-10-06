import EventKit
import Foundation

/// Puts shopping items into the Reminders app.
protocol RemindersExporting {
    func add(items: [String], listName: String) async throws
}

enum RemindersError: Error, Equatable {
    case accessDenied
    case noList
}

/// Adds the items to a Reminders list of its own. The app needs full access to Reminders to do that,
/// but it only ever creates reminders in that list and never reads the user's existing ones.
struct RemindersExporter: RemindersExporting {
    func add(items: [String], listName: String) async throws {
        let store = EKEventStore()
        guard try await store.requestFullAccessToReminders() else { throw RemindersError.accessDenied }
        let list = try shoppingList(named: listName, in: store)

        for item in items {
            let reminder = EKReminder(eventStore: store)
            reminder.title = item
            reminder.calendar = list
            try store.save(reminder, commit: false)
        }
        try store.commit()
    }

    /// The app's own list, created the first time.
    private func shoppingList(named name: String, in store: EKEventStore) throws -> EKCalendar {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == name }) {
            return existing
        }
        guard let source = store.defaultCalendarForNewReminders()?.source ?? store.sources.first(where: { $0.sourceType == .local }) else {
            throw RemindersError.noList
        }
        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = name
        list.source = source
        try store.saveCalendar(list, commit: true)
        return list
    }
}

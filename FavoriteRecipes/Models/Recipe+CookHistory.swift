import Foundation

extension Recipe {
    /// Every recorded time this recipe was cooked, oldest first.
    var cookHistory: [CookEntry] {
        get {
            guard let cookHistoryData else { return [] }
            return (try? JSONDecoder().decode([CookEntry].self, from: cookHistoryData)) ?? []
        }
        set {
            cookHistoryData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }

    var cookedCount: Int { cookHistory.count }

    var lastCookedAt: Date? { cookHistory.map(\.date).max() }

    /// Records that the recipe was cooked. A blank note is not stored.
    func markCooked(on date: Date = .now, note: String? = nil) {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        cookHistory.append(CookEntry(date: date, note: trimmed?.isEmpty == false ? trimmed : nil))
    }

    func removeCookEntry(_ entry: CookEntry) {
        cookHistory.removeAll { $0.id == entry.id }
    }
}

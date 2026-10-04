import Foundation

/// One time a recipe was cooked, with an optional note ("less salt next time").
struct CookEntry: Codable, Equatable, Identifiable {
    var id = UUID()
    var date: Date
    var note: String?
}

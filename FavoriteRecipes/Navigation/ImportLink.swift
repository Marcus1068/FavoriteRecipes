import Foundation

/// Links that open the web import: `favoriterecipes://import?url=https://example.com/recipe`.
/// Used by Shortcuts and other apps to hand a recipe page to this app.
enum ImportLink {
    static let scheme = "favoriterecipes"

    /// The recipe address inside an import link, or nil if the link is something else.
    static func recipeAddress(in link: URL) -> String? {
        guard link.scheme?.lowercased() == scheme, link.host()?.lowercased() == "import",
              let items = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems,
              let address = items.first(where: { $0.name == "url" })?.value?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty
        else { return nil }
        return address
    }

    /// Builds an import link for a recipe address.
    static func link(forAddress address: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "url", value: address)]
        return components.url
    }
}

import Foundation

/// Extracts a schema.org `Recipe` from the JSON-LD blocks of an HTML page.
///
/// Most recipe sites embed this data for search engines, which makes it far
/// more reliable than scraping the visible page. Pure logic, no networking.
nonisolated enum SchemaRecipeParser {

    /// Returns the first recipe found in the page, or nil if there is none.
    static func parse(html: String, pageURL: URL? = nil) -> ImportedRecipe? {
        for block in jsonLDBlocks(in: html) {
            guard let data = block.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
                  let object = findRecipeObject(in: json)
            else { continue }
            return makeRecipe(from: object, pageURL: pageURL, nodes: nodesByID(in: json))
        }
        return nil
    }

    // MARK: - Locating the recipe

    static func jsonLDBlocks(in html: String) -> [String] {
        let pattern = /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>(?<body>[\s\S]*?)<\/script>/
            .ignoresCase()
        return html.matches(of: pattern).map { String($0.output.body) }
    }

    /// Walks objects, arrays and `@graph` containers looking for `@type: Recipe`.
    static func findRecipeObject(in json: Any) -> [String: Any]? {
        if let array = json as? [Any] {
            return array.lazy.compactMap(findRecipeObject(in:)).first
        }
        guard let object = json as? [String: Any] else { return nil }
        if isRecipe(object["@type"]) { return object }
        if let graph = object["@graph"] { return findRecipeObject(in: graph) }
        if let main = object["mainEntity"] { return findRecipeObject(in: main) }
        return nil
    }

    /// Every object with an `@id`, so references like `{"@id": "…#primaryimage"}` can be resolved.
    static func nodesByID(in json: Any) -> [String: [String: Any]] {
        var nodes: [String: [String: Any]] = [:]
        func collect(_ value: Any) {
            if let array = value as? [Any] {
                array.forEach(collect)
            } else if let object = value as? [String: Any] {
                if let id = object["@id"] as? String, object.count > 1 { nodes[id] = object }
                object.values.forEach(collect)
            }
        }
        collect(json)
        return nodes
    }

    private static func isRecipe(_ type: Any?) -> Bool {
        if let type = type as? String { return type.caseInsensitiveCompare("Recipe") == .orderedSame }
        if let types = type as? [Any] { return types.contains { isRecipe($0) } }
        return false
    }

    // MARK: - Mapping fields

    static func makeRecipe(
        from object: [String: Any],
        pageURL: URL?,
        nodes: [String: [String: Any]] = [:]
    ) -> ImportedRecipe {
        var recipe = ImportedRecipe()
        recipe.name = cleanText(object["name"] as? String ?? "")
        recipe.ingredients = strings(object["recipeIngredient"] ?? object["ingredients"]).map(cleanText)
            .filter { !$0.isEmpty }
        recipe.instructions = instructionSteps(object["recipeInstructions"]).map(cleanText)
            .filter { !$0.isEmpty }
        recipe.servings = firstInteger(in: object["recipeYield"])
        recipe.prepMinutes = (object["prepTime"] as? String).flatMap(minutes(fromISO8601:))
        recipe.cookMinutes = (object["cookTime"] as? String).flatMap(minutes(fromISO8601:))
        if recipe.prepMinutes == nil, recipe.cookMinutes == nil {
            recipe.cookMinutes = (object["totalTime"] as? String).flatMap(minutes(fromISO8601:))
        }
        recipe.imageURL = imageURL(object["image"] ?? object["thumbnailUrl"], relativeTo: pageURL, nodes: nodes)
        recipe.sourceURL = pageURL
        recipe.categoryHints = ["recipeCategory", "recipeCuisine", "keywords"]
            .flatMap { strings(object[$0]) }
            .map(cleanText)
        return recipe
    }

    /// Accepts a string, an array of strings, or a comma-separated string.
    static func strings(_ value: Any?) -> [String] {
        switch value {
        case let string as String:
            return [string]
        case let array as [Any]:
            return array.flatMap { strings($0) }
        default:
            return []
        }
    }

    /// `recipeInstructions` may be text, [text], [HowToStep] or [HowToSection].
    static func instructionSteps(_ value: Any?) -> [String] {
        switch value {
        case let string as String:
            return string.split(whereSeparator: \.isNewline).map(String.init)
        case let array as [Any]:
            return array.flatMap { instructionSteps($0) }
        case let object as [String: Any]:
            if let items = object["itemListElement"] {
                return instructionSteps(items)
            }
            if let text = object["text"] as? String { return [text] }
            if let name = object["name"] as? String { return [name] }
            return []
        default:
            return []
        }
    }

    /// `image` may be a URL string, an array, an `ImageObject` with `url`,
    /// or a reference (`{"@id": …}`) to an `ImageObject` elsewhere in the graph.
    static func imageURL(_ value: Any?, relativeTo base: URL?, nodes: [String: [String: Any]] = [:]) -> URL? {
        switch value {
        case let string as String:
            return URL(string: string, relativeTo: base)?.absoluteURL
        case let array as [Any]:
            return array.lazy.compactMap { imageURL($0, relativeTo: base, nodes: nodes) }.first
        case let object as [String: Any]:
            if let url = object["url"] ?? object["contentUrl"] {
                return imageURL(url, relativeTo: base, nodes: nodes)
            }
            if let id = object["@id"] as? String, let node = nodes[id], node["@id"] as? String == id,
               node["url"] != nil || node["contentUrl"] != nil {
                return imageURL(node, relativeTo: base, nodes: [:])
            }
            return nil
        default:
            return nil
        }
    }

    /// "4 servings", ["4", "4 portions"], 4 → 4
    static func firstInteger(in value: Any?) -> Int? {
        switch value {
        case let number as Int:
            return number > 0 ? number : nil
        case let number as Double:
            return number > 0 ? Int(number) : nil
        case let string as String:
            return string.firstMatch(of: /\d+/).flatMap { Int($0.output) }.flatMap { $0 > 0 ? $0 : nil }
        case let array as [Any]:
            return array.lazy.compactMap(firstInteger(in:)).first
        default:
            return nil
        }
    }

    /// ISO 8601 durations such as "PT1H30M", "PT90M" or "P0DT0H45M" → minutes.
    static func minutes(fromISO8601 text: String) -> Int? {
        let pattern = /^P(?:(?<days>\d+)D)?(?:T(?:(?<hours>\d+)H)?(?:(?<minutes>\d+)M)?(?:\d+(?:\.\d+)?S)?)?$/
        guard let match = text.trimmingCharacters(in: .whitespaces).uppercased().wholeMatch(of: pattern) else {
            return nil
        }
        let days = match.output.days.flatMap { Int($0) } ?? 0
        let hours = match.output.hours.flatMap { Int($0) } ?? 0
        let minutes = match.output.minutes.flatMap { Int($0) } ?? 0
        let total = days * 24 * 60 + hours * 60 + minutes
        return total > 0 ? total : nil
    }

    // MARK: - Text cleanup

    /// Strips tags, decodes common HTML entities and collapses whitespace.
    static func cleanText(_ text: String) -> String {
        var result = text.replacing(/<[^>]+>/, with: " ")
        result = decodeEntities(result)
        result = result.replacing(/[ \t\u{00A0}]+/, with: " ")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func decodeEntities(_ text: String) -> String {
        let named = [
            "&amp;": "&", "&quot;": "\"", "&apos;": "'", "&#39;": "'",
            "&lt;": "<", "&gt;": ">", "&nbsp;": " ", "&frac12;": "½", "&frac14;": "¼", "&frac34;": "¾",
            "&deg;": "°", "&ndash;": "–", "&mdash;": "—", "&hellip;": "…",
            "&auml;": "ä", "&ouml;": "ö", "&uuml;": "ü", "&Auml;": "Ä", "&Ouml;": "Ö", "&Uuml;": "Ü",
            "&szlig;": "ß", "&eacute;": "é", "&egrave;": "è"
        ]
        var result = text
        for (entity, replacement) in named {
            result = result.replacing(entity, with: replacement)
        }
        // Numeric entities: &#8217; and &#x2019;
        result = result.replacing(/&#(?<hex>[xX])?(?<code>[0-9a-fA-F]+);/) { match in
            let radix = match.output.hex == nil ? 10 : 16
            guard let value = UInt32(match.output.code, radix: radix),
                  let scalar = Unicode.Scalar(value)
            else { return String(match.output.0) }
            return String(Character(scalar))
        }
        return result
    }
}

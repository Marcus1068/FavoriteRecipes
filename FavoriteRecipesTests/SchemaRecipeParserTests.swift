import Foundation
import Testing
@testable import FavoriteRecipes

struct SchemaRecipeParserTests {
    private func page(_ jsonLD: String) -> String {
        """
        <html><head>
        <script type="application/ld+json">{"@type": "WebSite", "name": "Example"}</script>
        <script type='application/ld+json'>\(jsonLD)</script>
        </head><body>Hello</body></html>
        """
    }

    @Test func parsesAPlainRecipeObject() throws {
        let html = page("""
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "Mac &amp; Cheese",
          "recipeIngredient": ["200 g macaroni", " 100 g cheddar "],
          "recipeInstructions": "Boil pasta.\\nAdd cheese.",
          "recipeYield": "4 servings",
          "prepTime": "PT15M",
          "cookTime": "PT1H5M",
          "image": "https://example.com/mac.jpg",
          "recipeCategory": "Main course",
          "keywords": "pasta, comfort food"
        }
        """)
        let recipe = try #require(SchemaRecipeParser.parse(html: html, pageURL: URL(string: "https://example.com/r")))
        #expect(recipe.name == "Mac & Cheese")
        #expect(recipe.ingredients == ["200 g macaroni", "100 g cheddar"])
        #expect(recipe.instructions == ["Boil pasta.", "Add cheese."])
        #expect(recipe.servings == 4)
        #expect(recipe.prepMinutes == 15)
        #expect(recipe.cookMinutes == 65)
        #expect(recipe.imageURL == URL(string: "https://example.com/mac.jpg"))
        #expect(recipe.sourceURL == URL(string: "https://example.com/r"))
        #expect(recipe.categoryHints == ["Main course", "pasta, comfort food"])
    }

    @Test func findsRecipeInsideGraphAndResolvesImageReference() throws {
        let html = page("""
        {
          "@context": "https://schema.org",
          "@graph": [
            {"@type": "WebPage", "@id": "https://example.com/r"},
            {"@type": ["Recipe"], "name": "Apfelkuchen",
             "image": {"@id": "https://example.com/r#primaryimage"},
             "recipeInstructions": [
               {"@type": "HowToSection", "name": "Teig", "itemListElement": [
                 {"@type": "HowToStep", "text": "Mehl &amp; Zucker mischen."},
                 {"@type": "HowToStep", "text": "<p>Kneten.</p>"}
               ]},
               {"@type": "HowToStep", "text": "Backen bei 180&#176;C."}
             ],
             "recipeYield": ["12", "12 Stücke"],
             "totalTime": "P0DT1H0M"
            },
            {"@type": "ImageObject", "@id": "https://example.com/r#primaryimage", "url": "/img/kuchen.jpg"}
          ]
        }
        """)
        let recipe = try #require(SchemaRecipeParser.parse(html: html, pageURL: URL(string: "https://example.com/r")))
        #expect(recipe.name == "Apfelkuchen")
        #expect(recipe.instructions == ["Mehl & Zucker mischen.", "Kneten.", "Backen bei 180°C."])
        #expect(recipe.servings == 12)
        #expect(recipe.prepMinutes == nil)
        #expect(recipe.cookMinutes == 60, "totalTime is used when prep and cook time are missing")
        #expect(recipe.imageURL == URL(string: "https://example.com/img/kuchen.jpg"))
    }

    @Test func returnsNilWithoutRecipeData() {
        #expect(SchemaRecipeParser.parse(html: page(#"{"@type": "Article", "name": "News"}"#)) == nil)
        #expect(SchemaRecipeParser.parse(html: "<html><body>No JSON-LD</body></html>") == nil)
    }

    @Test func skipsMalformedJSONBlocks() throws {
        let html = """
        <script type="application/ld+json">{ not json </script>
        <script type="application/ld+json">{"@type": "Recipe", "name": "Soup"}</script>
        """
        #expect(try #require(SchemaRecipeParser.parse(html: html)).name == "Soup")
    }

    @Test(arguments: [
        ("PT30M", 30), ("PT1H", 60), ("PT1H30M", 90), ("P1DT2H", 1_560), ("pt45m", 45), ("PT0M", nil), ("30 min", nil)
    ] as [(String, Int?)])
    func parsesISO8601Durations(text: String, minutes: Int?) {
        #expect(SchemaRecipeParser.minutes(fromISO8601: text) == minutes)
    }

    @Test func decodesNamedAndNumericEntities() {
        #expect(SchemaRecipeParser.cleanText("Caf&eacute; &#x2013; 1&frac12; cups&nbsp;") == "Café – 1½ cups")
    }
}

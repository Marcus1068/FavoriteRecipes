import Foundation
import Testing
@testable import FavoriteRecipes

struct IngredientParserTests {
    private func parse(_ line: String) -> Ingredient { IngredientParser.parse(line) }

    @Test func readsAmountUnitAndName() {
        let result = parse("400 g spaghetti")
        #expect(result.amount == 400)
        #expect(result.unit == .gram)
        #expect(result.name == "spaghetti")
    }

    @Test func readsAttachedUnits() {
        let result = parse("400g Mehl")
        #expect(result.amount == 400 && result.unit == .gram && result.name == "Mehl")
    }

    @Test func readsDecimalsWithCommaOrPoint() {
        #expect(parse("1,5 L Brühe").amount == 1.5)
        #expect(parse("1.2 L warm vegetable stock").amount == 1.2)
        #expect(parse("1,5 L Brühe").unit == .liter)
    }

    @Test func readsFractions() {
        #expect(parse("½ cup sugar").amount == 0.5)
        #expect(parse("1½ cups flour").amount == 1.5)
        #expect(parse("1/2 tsp salt").amount == 0.5)
        #expect(parse("1 1/2 cups milk").amount == 1.5)
        #expect(parse("2 ¼ cups flour").amount == 2.25)
        #expect(parse("1/4 cup oil").unit == .cup)
    }

    @Test func readsGermanSpoonsAndWords() {
        #expect(parse("2 EL Öl").unit == .tablespoon)
        #expect(parse("1 TL Salz").unit == .teaspoon)
        #expect(parse("250 Gramm Zucker").unit == .gram)
        #expect(parse("2 EL Öl").unitText == "EL")
    }

    @Test func readsRanges() {
        let result = parse("2-3 cloves garlic")
        #expect(result.amount == 2 && result.amountHigh == 3)
        #expect(result.otherUnit == "cloves")
        #expect(parse("10 bis 15 g Hefe").amountHigh == 15)
        #expect(parse("10-5 g Hefe").amountHigh == nil)
    }

    @Test func keepsCountedThingsAsOtherUnits() {
        let result = parse("3 cloves garlic, minced")
        #expect(result.amount == 3 && result.unit == nil)
        #expect(result.otherUnit == "cloves")
        #expect(result.name == "garlic, minced")
        #expect(parse("1 Prise Salz").otherUnit == "Prise")
    }

    @Test func countedIngredientsHaveNoUnit() {
        let result = parse("4 eggs")
        #expect(result.amount == 4 && result.unit == nil && result.otherUnit == nil)
        #expect(result.name == "eggs")
    }

    @Test func linesWithoutAnAmountKeepTheirText() {
        let result = parse("Salt and pepper")
        #expect(result.amount == nil)
        #expect(result.name == "Salt and pepper")
        #expect(parse("Saft von 1 Zitrone").amount == nil)
    }

    @Test func skipsBulletsAndApproximations() {
        #expect(parse("- 200 ml milk").amount == 200)
        #expect(parse("• 200 ml milk").unit == .milliliter)
        #expect(parse("ca. 200 g Butter").amount == 200)
        #expect(parse("about 2 cups rice").amount == 2)
    }

    @Test func readsFluidOunces() {
        let result = parse("8 fl oz cream")
        #expect(result.unit == .fluidOunce && result.name == "cream")
    }

    @Test func dropsAConnectingOf() {
        #expect(parse("2 cups of flour").name == "flour")
    }

    @Test func unitWordsThatAreNamesAreNotUnits() {
        // "g" must not swallow the start of a word such as "garlic".
        let result = parse("2 garlic bulbs")
        #expect(result.unit == nil)
        #expect(result.name == "garlic bulbs")
    }

    @Test func parsesAWholeText() {
        let lines = IngredientParser.parseLines("400 g spaghetti\n\n4 egg yolks\nSalt")
        #expect(lines.count == 3)
        #expect(lines.map(\.name) == ["spaghetti", "egg yolks", "Salt"])
        #expect(IngredientParser.parseLines(nil).isEmpty)
    }

    @Test func shoppingKeyIgnoresPreparationAndCase() {
        #expect(parse("3 cloves Garlic, minced").shoppingKey == "garlic")
        #expect(parse("1 Zwiebel (groß)").shoppingKey == "zwiebel")
        #expect(parse("200 g Crème fraîche").shoppingKey == "creme fraiche")
    }
}

struct IngredientDisplayTests {
    private let en = Locale(identifier: "en_US")

    private func show(_ line: String, factor: Double = 1, system: UnitSystem = .original) -> String {
        IngredientParser.parse(line).display(factor: factor, system: system, locale: en)
    }

    @Test func unchangedLinesAreShownAsWritten() {
        #expect(show("400 g spaghetti") == "400 g spaghetti")
        #expect(show("Salt and pepper", factor: 2) == "Salt and pepper")
    }

    @Test func scalesAmounts() {
        #expect(show("400 g spaghetti", factor: 1.5) == "600 g spaghetti")
        #expect(show("4 egg yolks", factor: 2) == "8 egg yolks")
        #expect(show("2 EL Öl", factor: 2) == "4 EL Öl")
    }

    @Test func cupsArePluralForMoreThanOne() {
        #expect(show("1 cup milk", factor: 2) == "2 cups milk")
        #expect(show("2 cups milk", factor: 0.5) == "1 cup milk")
        #expect(show("1 cup milk", factor: 0.5) == "½ cup milk")
        #expect(show("500 ml milk", system: .imperial) == "2 cups milk")
    }

    @Test func scalesToFractions() {
        #expect(show("3 eggs", factor: 0.5) == "1½ eggs")
        #expect(show("1 cup flour", factor: 0.25) == "¼ cup flour")
        #expect(show("1 tsp salt", factor: 1.5) == "1½ tsp salt")
        #expect(show("2 cups milk", factor: 0.75) == "1½ cups milk")
    }

    @Test func roundsToSensibleKitchenAmounts() {
        #expect(show("150 g butter", factor: 1.25) == "190 g butter")
        #expect(show("20 g yeast", factor: 1.1) == "22 g yeast")
        #expect(show("5 g salt", factor: 1.5) == "7.5 g salt")
    }

    @Test func scalesRanges() {
        #expect(show("2-3 cloves garlic", factor: 2) == "4–6 cloves garlic")
    }

    @Test func convertsMetricToImperial() {
        #expect(show("400 g spaghetti", system: .imperial) == "14.1 oz spaghetti")
        #expect(show("500 g flour", system: .imperial) == "1.1 lb flour")
        #expect(show("250 ml milk", system: .imperial) == "1 cup milk")
        #expect(show("1 L stock", system: .imperial) == "4¼ cups stock")
        #expect(show("30 ml oil", system: .imperial) == "2 tbsp oil")
        #expect(show("5 ml vanilla", system: .imperial) == "1 tsp vanilla")
    }

    @Test func convertsImperialToMetric() {
        #expect(show("8 oz cheese", system: .metric) == "225 g cheese")
        #expect(show("2 lb potatoes", system: .metric) == "905 g potatoes")
        #expect(show("1 cup milk", system: .metric) == "240 ml milk")
        #expect(show("5 cups water", system: .metric) == "1.2 l water")
        #expect(show("8 fl oz cream", system: .metric) == "235 ml cream")
    }

    @Test func leavesAlreadyMatchingUnitsAlone() {
        #expect(show("400 g spaghetti", system: .metric) == "400 g spaghetti")
        #expect(show("1 cup milk", system: .imperial) == "1 cup milk")
        #expect(show("2 EL Öl", system: .metric) == "2 EL Öl")
        #expect(show("2 EL Öl", system: .imperial) == "2 EL Öl")
    }

    @Test func doesNotConvertCountedThings() {
        #expect(show("4 eggs", system: .imperial) == "4 eggs")
        #expect(show("3 cloves garlic", system: .metric) == "3 cloves garlic")
    }

    @Test func scalesAndConvertsTogether() {
        #expect(show("200 g flour", factor: 2, system: .imperial) == "14.1 oz flour")
    }

    @Test func convertsRanges() {
        #expect(show("100-200 g flour", system: .imperial) == "3.5–7.1 oz flour")
    }

    @Test func largeMetricAmountsUseBiggerUnits() {
        #expect(show("2 lb flour", factor: 2, system: .metric) == "1.8 kg flour")
    }

    @Test func amountsFormatWithTheLocalDecimalSeparator() {
        let german = Locale(identifier: "de_DE")
        let result = IngredientParser.parse("5 g Salz").display(factor: 1.5, system: .original, locale: german)
        #expect(result == "7,5 g Salz")
    }
}

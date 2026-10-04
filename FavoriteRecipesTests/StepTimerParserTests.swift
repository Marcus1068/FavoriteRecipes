import Testing
@testable import FavoriteRecipes

struct StepTimerParserTests {
    private func seconds(_ text: String) -> [Int] {
        StepTimerParser.suggestions(in: text).map(\.seconds)
    }

    @Test func findsMinutesInEnglishAndGerman() {
        #expect(seconds("Simmer for 10 minutes.") == [600])
        #expect(seconds("10 Minuten köcheln lassen") == [600])
        #expect(seconds("Backen, ca. 25 min.") == [1_500])
        #expect(seconds("Nach 1 Minute wenden") == [60])
    }

    @Test func findsHoursAndSeconds() {
        #expect(seconds("2 h im Ofen garen") == [7_200])
        #expect(seconds("Bake for 2 hours") == [7_200])
        #expect(seconds("30 Sekunden anbraten") == [30])
        #expect(seconds("Sear 45 sec per side") == [45])
    }

    @Test func understandsDecimalsAndFractions() {
        #expect(seconds("1,5 Stunden backen") == [5_400])
        #expect(seconds("Bake 1.5 hours") == [5_400])
        #expect(seconds("½ Stunde ruhen") == [1_800])
        #expect(seconds("1½ hours") == [5_400])
    }

    @Test func understandsWrittenOutDurations() {
        #expect(seconds("eine halbe Stunde ziehen lassen") == [1_800])
        #expect(seconds("Rest for half an hour") == [1_800])
        #expect(seconds("anderthalb Stunden schmoren") == [5_400])
        #expect(seconds("eine Viertelstunde kochen") == [900])
        #expect(seconds("Bake for one hour") == [3_600])
    }

    @Test func usesTheShorterTimeOfARange() {
        #expect(seconds("10-15 Minuten garen") == [600])
        #expect(seconds("Cook 8 to 10 minutes") == [480])
    }

    @Test func joinsHoursAndMinutes() {
        let result = StepTimerParser.suggestions(in: "1 Stunde 30 Minuten backen")
        #expect(result.map(\.seconds) == [5_400])
        #expect(result.first?.text == "1 Stunde 30 Minuten")
        #expect(seconds("1 hour and 30 minutes") == [5_400])
        #expect(seconds("2 min 30 sec") == [150])
    }

    @Test func keepsSeparateDurationsApart() {
        #expect(seconds("10 min köcheln, dann 5 min ruhen") == [600, 300])
    }

    @Test func ignoresThingsThatAreNotDurations() {
        #expect(seconds("Bei 200 °C backen").isEmpty)
        #expect(seconds("3 Eier und 5 Honigkekse").isEmpty)
        #expect(seconds("Minuten später servieren").isEmpty)
        #expect(seconds("").isEmpty)
    }

    @Test func ignoresVeryLongWaits() {
        #expect(seconds("48 Stunden marinieren").isEmpty)
        #expect(seconds("12 Stunden ruhen") == [43_200])
    }

    @Test func caseDoesNotMatter() {
        #expect(seconds("10 MINUTEN") == [600])
    }
}

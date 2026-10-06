import Foundation
import Testing
@testable import FavoriteRecipes

final class FakeNotifier: TimerNotifying {
    private(set) var scheduled: [(id: UUID, title: String, endDate: Date)] = []
    private(set) var cancelled: [UUID] = []

    func schedule(id: UUID, title: String, endDate: Date) async {
        scheduled.append((id, title, endDate))
    }

    func cancel(id: UUID) async {
        cancelled.append(id)
    }
}

/// A clock the tests can move forward.
final class TestClock {
    var date: Date
    init(_ date: Date) { self.date = date }
}

@MainActor
struct TimerCenterTests {
    private let start = Date(timeIntervalSinceReferenceDate: 100_000)

    /// A center whose timers never finish by themselves unless `finishImmediately` is set.
    private func makeCenter(notifier: FakeNotifier, clock: TestClock? = nil, finishImmediately: Bool = false) -> TimerCenter {
        let clock = clock ?? TestClock(start)
        return TimerCenter(
            notifier: notifier,
            now: { clock.date },
            wait: { _ in
                if !finishImmediately { try? await Task.sleep(for: .seconds(3_600)) }
            }
        )
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(80))
    }

    @Test func startsATimerAndSchedulesTheNotification() async {
        let notifier = FakeNotifier()
        let center = makeCenter(notifier: notifier)
        let timer = center.start(seconds: 600, title: "Risotto · 10 min")
        await settle()

        #expect(center.timers == [timer])
        #expect(timer.endDate == start.addingTimeInterval(600))
        #expect(!center.isFinished(timer))
        let scheduled = notifier.scheduled
        #expect(scheduled.count == 1)
        #expect(scheduled.first?.id == timer.id)
        #expect(scheduled.first?.endDate == timer.endDate)
    }

    @Test func removingATimerCancelsItsNotification() async {
        let notifier = FakeNotifier()
        let center = makeCenter(notifier: notifier)
        let timer = center.start(seconds: 60, title: "x")
        center.remove(timer)
        await settle()

        #expect(center.timers.isEmpty)
        #expect(!center.hasTimers)
        #expect(notifier.cancelled == [timer.id])
    }

    @Test func aTimerFinishesWhenItsTimeIsUp() async {
        let center = makeCenter(notifier: FakeNotifier(), finishImmediately: true)
        let timer = center.start(seconds: 5, title: "x")
        await settle()
        #expect(center.isFinished(timer))
        #expect(center.timers.count == 1, "Finished timers stay until dismissed")
    }

    @Test func addingAMinuteExtendsAndRestartsAFinishedTimer() async {
        let notifier = FakeNotifier()
        let clock = TestClock(start)
        let center = makeCenter(notifier: notifier, clock: clock, finishImmediately: true)
        let timer = center.start(seconds: 5, title: "x")
        await settle()
        #expect(center.isFinished(timer))

        // Ten seconds pass; the extra minute counts from now, not from the old end.
        clock.date = start.addingTimeInterval(10)
        center.addMinute(to: timer)
        #expect(center.timers.first?.endDate == start.addingTimeInterval(70))
        await settle()
        #expect(notifier.scheduled.count >= 2)
    }

    @Test func addingAMinuteToARunningTimerKeepsItsRemainingTime() async {
        let center = makeCenter(notifier: FakeNotifier())
        let timer = center.start(seconds: 300, title: "x")
        center.addMinute(to: timer)
        #expect(center.timers.first?.endDate == start.addingTimeInterval(360))
    }

    @Test func severalTimersRunSideBySide() async {
        let center = makeCenter(notifier: FakeNotifier())
        let a = center.start(seconds: 60, title: "a")
        let b = center.start(seconds: 120, title: "b")
        center.remove(a)
        #expect(center.timers == [b])
    }

    @Test func unknownTimersAreIgnored() async {
        let center = makeCenter(notifier: FakeNotifier())
        let other = CookingTimer(id: UUID(), title: "z", endDate: start)
        center.addMinute(to: other)
        center.remove(other)
        #expect(center.timers.isEmpty)
    }
}

@MainActor
struct CookingModelNameTests {
    @Test func modelKnowsTheRecipeName() {
        let recipe = Recipe(name: "Risotto")
        #expect(CookingModel(recipe: recipe).recipeName == "Risotto")
    }
}

final class FakeActivities: TimerActivityManaging {
    private(set) var started: [(id: UUID, title: String, endDate: Date)] = []
    private(set) var updated: [(id: UUID, endDate: Date, isFinished: Bool)] = []
    private(set) var ended: [UUID] = []

    private(set) var orphanCleanups = 0

    func endOrphans() async { orphanCleanups += 1 }
    func start(id: UUID, title: String, endDate: Date) async { started.append((id, title, endDate)) }
    func update(id: UUID, endDate: Date, isFinished: Bool) async { updated.append((id, endDate, isFinished)) }
    func end(id: UUID) async { ended.append(id) }
}

@MainActor
struct TimerLiveActivityTests {
    private let start = Date(timeIntervalSinceReferenceDate: 100_000)

    private func makeCenter(_ activities: FakeActivities, finishImmediately: Bool = false, clock: TestClock? = nil) -> TimerCenter {
        let clock = clock ?? TestClock(start)
        return TimerCenter(
            notifier: FakeNotifier(),
            activities: activities,
            now: { clock.date },
            wait: { _ in
                if !finishImmediately { try? await Task.sleep(for: .seconds(3_600)) }
            }
        )
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(100))
    }

    @Test func startingATimerStartsALiveActivity() async {
        let activities = FakeActivities()
        let center = makeCenter(activities)
        let timer = center.start(seconds: 600, title: "Risotto · 10 min")
        await settle()
        #expect(activities.started.count == 1)
        #expect(activities.started.first?.id == timer.id)
        #expect(activities.started.first?.title == "Risotto · 10 min")
        #expect(activities.started.first?.endDate == start.addingTimeInterval(600))
        #expect(activities.updated.isEmpty)
    }

    @Test func addingAMinuteUpdatesTheActivityInsteadOfStartingAnother() async {
        let activities = FakeActivities()
        let center = makeCenter(activities)
        let timer = center.start(seconds: 300, title: "x")
        await settle()
        center.addMinute(to: timer)
        await settle()
        #expect(activities.started.count == 1)
        #expect(activities.updated.count == 1)
        #expect(activities.updated.first?.endDate == start.addingTimeInterval(360))
        #expect(activities.updated.first?.isFinished == false)
    }

    @Test func aFinishedTimerMarksTheActivityFinished() async {
        let activities = FakeActivities()
        let center = makeCenter(activities, finishImmediately: true)
        let timer = center.start(seconds: 5, title: "x")
        await settle()
        #expect(center.isFinished(timer))
        #expect(activities.updated.contains { $0.id == timer.id && $0.isFinished })
    }

    @Test func extendingAFinishedTimerRestartsTheCountdown() async {
        let activities = FakeActivities()
        let clock = TestClock(start)
        let center = makeCenter(activities, finishImmediately: true, clock: clock)
        let timer = center.start(seconds: 5, title: "x")
        await settle()
        clock.date = start.addingTimeInterval(10)
        center.addMinute(to: timer)
        await settle()
        #expect(activities.started.count == 1)
        #expect(activities.updated.contains { !$0.isFinished && $0.endDate == start.addingTimeInterval(70) })
    }

    @Test func stoppingATimerEndsItsActivity() async {
        let activities = FakeActivities()
        let center = makeCenter(activities)
        let timer = center.start(seconds: 60, title: "x")
        await settle()
        center.remove(timer)
        await settle()
        #expect(activities.ended == [timer.id])
    }

    @Test func eachTimerGetsItsOwnActivity() async {
        let activities = FakeActivities()
        let center = makeCenter(activities)
        let a = center.start(seconds: 60, title: "a")
        let b = center.start(seconds: 120, title: "b")
        await settle()
        #expect(Set(activities.started.map(\.id)) == [a.id, b.id])
        center.remove(a)
        await settle()
        #expect(activities.ended == [a.id])
    }

    @Test func leftoverActivitiesAreCleanedUpOnLaunch() async {
        let activities = FakeActivities()
        let center = makeCenter(activities)
        center.cleanUpLeftoverActivities()
        await settle()
        #expect(activities.orphanCleanups == 1)
        #expect(activities.started.isEmpty)
    }
}

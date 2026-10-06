import Foundation
import Observation

/// Keeps the running timers. It lives for the whole app, so timers keep running
/// after cooking mode is closed.
@MainActor
@Observable
final class TimerCenter {
    private(set) var timers: [CookingTimer] = []
    /// Timers whose time is up; they stay in the list until dismissed.
    private(set) var finishedIDs: Set<UUID> = []

    private let notifier: any TimerNotifying
    private let activities: any TimerActivityManaging
    private let now: () -> Date
    private let wait: (Duration) async -> Void
    private var waiters: [UUID: Task<Void, Never>] = [:]
    /// Timers that already have a Live Activity, so a change updates it instead of starting another.
    private var hasStartedActivity: Set<UUID> = []

    init(
        notifier: any TimerNotifying = LocalTimerNotifier(),
        activities: any TimerActivityManaging = NoTimerActivities.platformDefault,
        now: @escaping () -> Date = { .now },
        wait: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.notifier = notifier
        self.activities = activities
        self.now = now
        self.wait = wait
    }

    var hasTimers: Bool { !timers.isEmpty }

    /// Call once when the app starts: ends Live Activities that belong to timers of an earlier launch.
    func cleanUpLeftoverActivities() {
        let activities = activities
        Task { await activities.endOrphans() }
    }

    func isFinished(_ timer: CookingTimer) -> Bool {
        finishedIDs.contains(timer.id)
    }

    /// Starts a timer and schedules its notification.
    @discardableResult
    func start(seconds: Int, title: String) -> CookingTimer {
        let timer = CookingTimer(id: UUID(), title: title, endDate: now().addingTimeInterval(Double(seconds)))
        timers.append(timer)
        schedule(timer)
        return timer
    }

    /// Adds a minute to a timer, also after it has finished (it starts again).
    func addMinute(to timer: CookingTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        let base = max(timers[index].endDate, now())
        timers[index].endDate = base.addingTimeInterval(60)
        finishedIDs.remove(timer.id)
        schedule(timers[index])
    }

    /// Stops a timer, or removes it once it has finished.
    func remove(_ timer: CookingTimer) {
        waiters[timer.id]?.cancel()
        waiters[timer.id] = nil
        hasStartedActivity.remove(timer.id)
        timers.removeAll { $0.id == timer.id }
        finishedIDs.remove(timer.id)
        let notifier = notifier
        let activities = activities
        Task {
            await notifier.cancel(id: timer.id)
            await activities.end(id: timer.id)
        }
    }

    private func schedule(_ timer: CookingTimer) {
        waiters[timer.id]?.cancel()
        let notifier = notifier
        let activities = activities
        // A timer that already has a Live Activity is updated, not started again.
        let isRestart = hasStartedActivity.contains(timer.id)
        Task {
            await notifier.schedule(id: timer.id, title: timer.title, endDate: timer.endDate)
            if isRestart {
                await activities.update(id: timer.id, endDate: timer.endDate, isFinished: false)
            } else {
                await activities.start(id: timer.id, title: timer.title, endDate: timer.endDate)
            }
        }
        hasStartedActivity.insert(timer.id)

        let remaining = max(0, timer.endDate.timeIntervalSince(now()))
        waiters[timer.id] = Task { [weak self, wait] in
            await wait(.seconds(remaining))
            guard !Task.isCancelled else { return }
            self?.markFinished(timer.id)
        }
    }

    private func markFinished(_ id: UUID) {
        guard timers.contains(where: { $0.id == id }) else { return }
        finishedIDs.insert(id)
        waiters[id] = nil
        if let timer = timers.first(where: { $0.id == id }) {
            let activities = activities
            Task { await activities.update(id: id, endDate: timer.endDate, isFinished: true) }
        }
    }
}

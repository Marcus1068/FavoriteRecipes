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
    private let now: () -> Date
    private let wait: (Duration) async -> Void
    private var waiters: [UUID: Task<Void, Never>] = [:]

    init(
        notifier: any TimerNotifying = LocalTimerNotifier(),
        now: @escaping () -> Date = { .now },
        wait: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.notifier = notifier
        self.now = now
        self.wait = wait
    }

    var hasTimers: Bool { !timers.isEmpty }

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
        timers.removeAll { $0.id == timer.id }
        finishedIDs.remove(timer.id)
        let notifier = notifier
        Task { await notifier.cancel(id: timer.id) }
    }

    private func schedule(_ timer: CookingTimer) {
        waiters[timer.id]?.cancel()
        let notifier = notifier
        Task { await notifier.schedule(id: timer.id, title: timer.title, endDate: timer.endDate) }

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
    }
}

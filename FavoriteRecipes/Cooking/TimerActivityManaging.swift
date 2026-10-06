import Foundation
#if !targetEnvironment(macCatalyst)
import ActivityKit
#endif

/// Shows timers as Live Activities. The timer center talks to this protocol so it can be tested without ActivityKit.
protocol TimerActivityManaging {
    /// Ends Live Activities left over from an earlier launch. Timers do not survive the app being closed,
    /// so an activity that no timer owns would count down forever.
    func endOrphans() async
    func start(id: UUID, title: String, endDate: Date) async
    func update(id: UUID, endDate: Date, isFinished: Bool) async
    func end(id: UUID) async
}

#if !targetEnvironment(macCatalyst)
/// Live Activities on the lock screen and in the Dynamic Island.
/// Does nothing when the user has turned Live Activities off.
final class LiveTimerActivities: TimerActivityManaging {
    private var activities: [UUID: Activity<TimerActivityAttributes>] = [:]

    func endOrphans() async {
        for activity in Activity<TimerActivityAttributes>.activities where activities[activity.attributes.timerID] == nil {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func start(id: UUID, title: String, endDate: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = TimerActivityAttributes.ContentState(endDate: endDate, isFinished: false)
        do {
            activities[id] = try Activity.request(
                attributes: TimerActivityAttributes(timerID: id, title: title),
                content: .init(state: state, staleDate: endDate.addingTimeInterval(60)),
                pushType: nil
            )
        } catch {
            // The timer still works and still notifies; the Live Activity is a bonus.
        }
    }

    func update(id: UUID, endDate: Date, isFinished: Bool) async {
        guard let activity = activities[id] else { return }
        let state = TimerActivityAttributes.ContentState(endDate: endDate, isFinished: isFinished)
        await activity.update(.init(state: state, staleDate: endDate.addingTimeInterval(60)))
    }

    func end(id: UUID) async {
        guard let activity = activities.removeValue(forKey: id) else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}

#endif

/// Used where no Live Activities are available or wanted: Mac, tests and UI tests.
struct NoTimerActivities: TimerActivityManaging {
    func endOrphans() async {}
    func start(id: UUID, title: String, endDate: Date) async {}
    func update(id: UUID, endDate: Date, isFinished: Bool) async {}
    func end(id: UUID) async {}
}

extension NoTimerActivities {
    /// The Live Activities this platform supports.
    static var platformDefault: any TimerActivityManaging {
        #if targetEnvironment(macCatalyst)
        NoTimerActivities()
        #else
        LiveTimerActivities()
        #endif
    }
}

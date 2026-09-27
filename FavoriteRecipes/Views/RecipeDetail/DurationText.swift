import SwiftUI

/// Shows a number of minutes as a localized duration such as "1 hr, 30 min".
struct DurationText: View {
    let minutes: Int?

    var body: some View {
        if let minutes {
            Text(Duration.seconds(minutes * 60), format: .units(allowed: [.hours, .minutes], width: .abbreviated))
        } else {
            Text(.notSet)
        }
    }
}

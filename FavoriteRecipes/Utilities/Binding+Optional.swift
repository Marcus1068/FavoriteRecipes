import SwiftUI

extension Binding where Value == String {
    /// Bridges an optional string to a text control: an empty string is stored as `nil`.
    init(emptyAsNil source: Binding<String?>) {
        self.init(
            get: { source.wrappedValue ?? "" },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

extension Binding where Value == Int {
    /// Bridges an optional number to a stepper: zero is stored as `nil`.
    init(zeroAsNil source: Binding<Int?>) {
        self.init(
            get: { source.wrappedValue ?? 0 },
            set: { source.wrappedValue = $0 == 0 ? nil : $0 }
        )
    }
}

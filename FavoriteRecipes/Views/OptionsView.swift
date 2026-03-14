import SwiftUI

struct OptionsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Options coming soon…", systemImage: "gear.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Options")
        }
    }
}

#Preview {
    OptionsView()
}

import SwiftUI

/// Asks for a recipe web address and hands back an unsaved draft.
struct ImportRecipeView: View {
    let onImport: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var model: ImportRecipeModel

    /// `initialAddress` pre-fills the web address, e.g. when it comes from an import link.
    init(initialAddress: String? = nil, onImport: @escaping (Recipe) -> Void) {
        self.onImport = onImport
        _model = State(initialValue: ImportRecipeModel(urlText: initialAddress ?? ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.sourcePlaceholder, text: $model.urlText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(runImport)
                    PasteButton(payloadType: String.self) { strings in
                        if let first = strings.first { model.urlText = first }
                    }
                } footer: {
                    Text(.importFromWebMessage)
                }

                if let error = model.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                if model.offersPasteFallback {
                    Section {
                        TextField(.pastePageTextPlaceholder, text: $model.pastedText, axis: .vertical)
                            .lineLimit(4...)
                        PasteButton(payloadType: String.self) { strings in
                            if let first = strings.first { model.pastedText = first }
                        }
                        Button(.useThisText, action: usePastedText)
                            .disabled(!model.canUsePastedText)
                    } header: {
                        Text(.pasteFallbackTitle)
                    } footer: {
                        Text(.pasteFallbackMessage)
                    }
                }
            }
            .disabled(model.isImporting)
            .overlay {
                if model.isImporting {
                    ProgressView(.importing)
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
            .task {
                // An address from an import link starts the import right away.
                if model.canImport { runImport() }
            }
            .tracksPresentation()
            .navigationTitle(.importFromWeb)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(.import, action: runImport)
                        .disabled(!model.canImport)
                }
            }
        }
    }

    private func usePastedText() {
        Task {
            if let draft = await model.draftFromPastedText() {
                onImport(draft)
                dismiss()
            }
        }
    }

    private func runImport() {
        guard model.canImport else { return }
        Task {
            if let draft = await model.importRecipe() {
                onImport(draft)
                dismiss()
            }
        }
    }
}

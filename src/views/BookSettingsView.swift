import SwiftUI

struct BookSettingsView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) var dismiss

    // Local copy — committed on Done
    @State private var metadata: BookMetadata

    init(initialMetadata: BookMetadata) {
        _metadata = State(initialValue: initialMetadata)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Info") {
                    LabeledContent("Title") {
                        TextField("My Book", text: $metadata.title)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Author") {
                        TextField("Author Name", text: $metadata.author)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Publisher") {
                        TextField("Publisher", text: $metadata.publisher)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Language") {
                        TextField("en", text: $metadata.language)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Layout & Typography") {
                    Picker("Style Preset", selection: $metadata.preset) {
                        ForEach(StylePreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    Toggle("Enable Drop Caps", isOn: $metadata.enableDropCaps)
                    Toggle("Enable Hyphenation", isOn: $metadata.enableHyphenation)
                }

                Section("Publishing Details") {
                    LabeledContent("ISBN") {
                        TextField("978-...", text: $metadata.isbn)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Genre") {
                        TextField("Fiction", text: $metadata.genre)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Publish Date", selection: $metadata.publishDate, displayedComponents: .date)
                }

                Section("Description") {
                    TextEditor(text: $metadata.description)
                        .frame(minHeight: 80)
                }

                Section("Rights") {
                    LabeledContent("Rights") {
                        TextField("All rights reserved", text: $metadata.rights)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Stats") {
                    LabeledContent("Chapters", value: "\(viewModel.document.chapters.count)")
                    LabeledContent("Words", value: "\(viewModel.wordCount)")
                    LabeledContent("Est. Reading Time", value: "\(viewModel.estimatedReadingMinutes) min")
                }
            }
            .navigationTitle("Book Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updateMetadata(metadata)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BookSettingsView(initialMetadata: BookMetadata())
        .environmentObject(DocumentViewModel())
}

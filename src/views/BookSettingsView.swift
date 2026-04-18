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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // BOOK INFO
                    SettingsSection(title: "BOOK INFO") {
                        VStack(spacing: 12) {
                            LabeledTextField(label: "Title", placeholder: "My Book", text: $metadata.title)
                            LabeledTextField(label: "Author", placeholder: "Author Name", text: $metadata.author)
                            LabeledTextField(label: "Publisher", placeholder: "Publisher", text: $metadata.publisher)
                            LabeledTextField(label: "Language", placeholder: "en", text: $metadata.language)
                        }
                    }

                    // LAYOUT
                    SettingsSection(title: "LAYOUT & TYPOGRAPHY") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Style Preset")
                                Spacer()
                                Picker("", selection: $metadata.preset) {
                                    ForEach(StylePreset.allCases, id: \.self) { preset in
                                        Text(preset.rawValue).tag(preset)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                            
                            Toggle("Enable Drop Caps", isOn: $metadata.enableDropCaps)
                            Toggle("Enable Hyphenation", isOn: $metadata.enableHyphenation)
                        }
                    }

                    // AI LAB
                    SettingsSection(title: "AI LAB (ALPHA)") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Active Model")
                                Spacer()
                                Picker("", selection: $metadata.aiSettings.preferredModel) {
                                    ForEach(AIModel.allCases, id: \.self) { model in
                                        Text(model.rawValue).tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                            
                            if metadata.aiSettings.preferredModel != .none {
                                SecureField("API Key", text: Binding(
                                    get: { UserDefaults.standard.string(forKey: "api_key_\(metadata.aiSettings.preferredModel.rawValue)") ?? "" },
                                    set: { UserDefaults.standard.set($0, forKey: "api_key_\(metadata.aiSettings.preferredModel.rawValue)") }
                                ))
                                .textFieldStyle(.roundedBorder)
                                
                                Stepper("Max Tokens: \(metadata.aiSettings.maxTokens)", value: $metadata.aiSettings.maxTokens, in: 256...16384, step: 256)
                                
                                HStack {
                                    Text("Temperature")
                                    Slider(value: $metadata.aiSettings.temperature, in: 0...1.2)
                                    Text(String(format: "%.1f", metadata.aiSettings.temperature))
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(width: 30)
                                }
                            }
                            
                            Text("Your API keys are stored locally in the macOS keychain. No data is sent unless you explicitly trigger an AI action.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // PUBLISHING
                    SettingsSection(title: "PUBLISHING DETAILS") {
                        VStack(spacing: 12) {
                            LabeledTextField(label: "ISBN", placeholder: "978-...", text: $metadata.isbn)
                            LabeledTextField(label: "Genre", placeholder: "Fiction", text: $metadata.genre)
                            
                            DatePicker("Publish Date", selection: $metadata.publishDate, displayedComponents: .date)
                        }
                    }

                    // DESCRIPTION
                    SettingsSection(title: "DESCRIPTION") {
                        TextEditor(text: $metadata.description)
                            .font(.body)
                            .frame(minHeight: 100)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
                    }

                    // STATS
                    SettingsSection(title: "STATISTICS") {
                        VStack(spacing: 8) {
                            StatRow(label: "Chapters", value: "\(viewModel.document.chapters.count)")
                            StatRow(label: "Words", value: "\(viewModel.wordCount)")
                            StatRow(label: "Est. Reading", value: "\(viewModel.estimatedReadingMinutes) min")
                        }
                    }
                }
                .padding(32)
            }
            .navigationTitle("BOOK SETTINGS")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updateMetadata(metadata)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Subviews

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .kerning(1)
                .foregroundStyle(.secondary)
            
            content
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
        }
    }
}

private struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.system(.body, design: .monospaced))
        }
    }
}

// MARK: - Preview

#Preview {
    BookSettingsView(initialMetadata: BookMetadata())
        .environmentObject(DocumentViewModel())
}

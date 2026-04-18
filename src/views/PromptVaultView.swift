import SwiftUI

struct PromptVaultView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @EnvironmentObject var themeManager: ColorThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var showingAddSheet = false
    @State private var newPromptTitle = ""
    @State private var newPromptBody = ""
    @State private var selectedCategory = "General"
    
    private var colors: ColorThemeManager.ThemeColors {
        themeManager.currentTheme.colors
    }

    private let categories = ["General", "Characters", "World Building", "Style", "Outlining"]

    var body: some View {
        NavigationStack {
            List {
                if viewModel.document.metadata.promptVault.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 40))
                                .foregroundStyle(colors.accent.opacity(0.3))
                            Text("THE VAULT IS EMPTY")
                                .font(.system(size: 12, weight: .black))
                                .kerning(2)
                            Text("Store your character bibles, world rules, and stylistic prompts here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(categories, id: \.self) { category in
                    let prompts = viewModel.document.metadata.promptVault.filter { $0.category == category }
                    if !prompts.isEmpty {
                        Section(category.uppercased()) {
                            ForEach(prompts) { prompt in
                                PromptRow(prompt: prompt) {
                                    viewModel.document.removePrompt(id: prompt.id)
                                    viewModel.objectWillChange.send()
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(colors.background)
            .navigationTitle("PROMPT VAULT")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("New Prompt", systemImage: "plus.square.dashed")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addPromptSheet
            }
        }
    }

    private var addPromptSheet: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $newPromptTitle)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextEditor(text: $newPromptBody)
                    .frame(minHeight: 200)
            }
            .navigationTitle("SAVE PROMPT")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to Vault") {
                        viewModel.document.addPrompt(title: newPromptTitle, body: newPromptBody, category: selectedCategory)
                        viewModel.objectWillChange.send()
                        newPromptTitle = ""
                        newPromptBody = ""
                        showingAddSheet = false
                    }
                    .disabled(newPromptTitle.isEmpty || newPromptBody.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 450)
    }
}

// MARK: - Prompt Row

private struct PromptRow: View {
    let prompt: SavedPrompt
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.title)
                    .font(.headline)
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Text(prompt.body)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(4)
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prompt.body, forType: .string)
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    PromptVaultView()
        .environmentObject(DocumentViewModel())
        .environmentObject(ColorThemeManager.shared)
}

import SwiftUI
import UniformTypeIdentifiers

struct DocumentLibraryView: View {

    @EnvironmentObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) var dismiss

    @State private var urls: [URL] = []
    @State private var showImporter = false
    @State private var deleteTarget: URL?
    @State private var showDeleteConfirm = false
    @State private var deleteError: String?

    private let fm = DocumentFileManager()

    var body: some View {
        NavigationStack {
            Group {
                if urls.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import", systemImage: "folder.badge.plus")
                    }
                    .help("Import from Google Drive, Word, or Markdown")
                }
            }
            .onAppear { reload() }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.data, .item, .rtf, UTType(filenameExtension: "docx")!],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let picked) = result, let url = picked.first {
                    // Check if it's our native format or an external one
                    if url.pathExtension == DocumentFileManager.fileExtension {
                        viewModel.load(from: url)
                    } else {
                        viewModel.importExternal(from: url)
                    }
                    
                    if viewModel.loadError == nil {
                        dismiss()
                    }
                }
            }
            .alert("Import Failed", isPresented: Binding(
                get: { viewModel.loadError != nil },
                set: { if !$0 { viewModel.loadError = nil } }
            )) {
                Button("OK") { viewModel.loadError = nil }
            } message: {
                Text(viewModel.loadError ?? "")
            }
            .alert("Delete Failed", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
            .confirmationDialog(
                "Delete this book?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let url = deleteTarget {
                        do {
                            try fm.delete(at: url)
                        } catch {
                            deleteError = error.localizedDescription
                        }
                        reload()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            Section("AvantGarde Library") {
                ForEach(urls, id: \.absoluteString) { url in
                    DocumentRow(url: url)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.load(from: url)
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTarget = url
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            
            Section("External Workflow") {
                Button {
                    showImporter = true
                } label: {
                    Label("Import from Google Drive / Word / MD", systemImage: "square.and.arrow.down")
                }
                
                Text("Select any .docx, .md, or .rtf file. If you use Google Drive, look for the 'Google Drive' folder in your Finder sidebar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Books Yet")
                    .font(.headline)
                Text("Create a new book or import your existing work from Google Drive or Word.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button {
                    viewModel.newDocument()
                    dismiss()
                } label: {
                    Label("Create New Book", systemImage: "plus")
                        .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showImporter = true
                } label: {
                    Label("Import External File", systemImage: "folder")
                        .frame(width: 200)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
            
            Text("Tip: Google Drive synced folders can be selected via the sidebar in the file picker.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func reload() {
        urls = fm.listDocuments()
    }
}

// MARK: - Document Row

private struct DocumentRow: View {

    let url: URL

    private var title: String {
        url.deletingPathExtension().lastPathComponent
    }

    private var modifiedDate: String {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
              let date = values.contentModificationDate else { return "" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            if !modifiedDate.isEmpty {
                Text("Modified \(modifiedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    DocumentLibraryView()
        .environmentObject(DocumentViewModel())
}

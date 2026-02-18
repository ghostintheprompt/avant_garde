import Foundation

/// Handles reading and writing EbookDocument to/from the app's local sandbox.
/// Replaces NSDocument file management for cross-platform use.
class DocumentFileManager {

    // MARK: - Paths

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AvantGarde", isDirectory: true)
    }

    static let fileExtension = "avantgarde"

    // MARK: - Directory Setup

    static func ensureDirectoryExists() throws {
        let dir = documentsDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            Logger.info("Created AvantGarde documents directory", category: .general)
        }
    }

    // MARK: - Save

    func save(_ document: EbookDocument, to url: URL) throws {
        let data = try document.toData()
        try data.write(to: url, options: .atomic)
        Logger.info("Saved document '\(document.metadata.title)' (\(data.count) bytes) to \(url.lastPathComponent)", category: .general)
    }

    func save(_ document: EbookDocument, named filename: String) throws -> URL {
        try DocumentFileManager.ensureDirectoryExists()
        let safeName = filename.isEmpty ? "Untitled" : filename
        let url = DocumentFileManager.documentsDirectory
            .appendingPathComponent(safeName)
            .appendingPathExtension(DocumentFileManager.fileExtension)
        try save(document, to: url)
        return url
    }

    // MARK: - Load

    func load(from url: URL) throws -> EbookDocument {
        let data = try Data(contentsOf: url)
        let document = try EbookDocument.from(data: data)
        Logger.info("Loaded document '\(document.metadata.title)' (\(document.chapters.count) chapters)", category: .general)
        return document
    }

    // MARK: - List

    func listDocuments() -> [URL] {
        let dir = DocumentFileManager.documentsDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        return contents
            .filter { $0.pathExtension == DocumentFileManager.fileExtension }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return date1 > date2
            }
    }

    // MARK: - Delete

    func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        Logger.info("Deleted document at \(url.lastPathComponent)", category: .general)
    }

    // MARK: - Auto-save

    /// Returns the auto-save URL for a document (not user-facing, always in sandbox)
    static func autoSaveURL(for documentID: UUID) -> URL {
        let dir = documentsDirectory.appendingPathComponent(".autosave", isDirectory: true)
        return dir.appendingPathComponent(documentID.uuidString)
            .appendingPathExtension(fileExtension)
    }

    func autoSave(_ document: EbookDocument, id: UUID) {
        let dir = DocumentFileManager.documentsDirectory.appendingPathComponent(".autosave", isDirectory: true)
        do {
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let url = DocumentFileManager.autoSaveURL(for: id)
            try save(document, to: url)
            Logger.debug("Auto-saved document \(id)", category: .general)
        } catch {
            Logger.warning("Auto-save failed for \(id): \(error.localizedDescription)", category: .general)
        }
    }

    func loadAutoSave(for id: UUID) -> EbookDocument? {
        let url = DocumentFileManager.autoSaveURL(for: id)
        return try? load(from: url)
    }

    func clearAutoSave(for id: UUID) {
        let url = DocumentFileManager.autoSaveURL(for: id)
        try? FileManager.default.removeItem(at: url)
    }
}

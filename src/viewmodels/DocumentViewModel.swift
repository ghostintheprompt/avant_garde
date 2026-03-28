import Foundation
import SwiftUI
import Combine

/// Central ObservableObject — single source of truth for the entire editor.
/// Owned by the app root and injected into the SwiftUI environment.
@MainActor
class DocumentViewModel: ObservableObject {

    // MARK: - Document State

    @Published var document: EbookDocument = EbookDocument()
    @Published var currentFileURL: URL?
    @Published var hasUnsavedChanges: Bool = false

    // MARK: - Editor State

    @Published var selectedChapterID: UUID?
    @Published var isEditingMetadata: Bool = false

    var selectedChapterIndex: Int? {
        guard let id = selectedChapterID else { return nil }
        return document.chapters.firstIndex { $0.id == id }
    }

    var selectedChapter: Chapter? {
        guard let index = selectedChapterIndex else { return nil }
        return document.chapters[index]
    }

    // MARK: - Statistics (cached @Published so SwiftUI re-renders on mutation)

    @Published private(set) var wordCount: Int = 0
    @Published private(set) var characterCount: Int = 0
    @Published private(set) var estimatedReadingMinutes: Int = 0

    private func refreshStats() {
        wordCount = document.getWordCount()
        characterCount = document.getCharacterCount()
        estimatedReadingMinutes = Int(ceil(document.getEstimatedReadingTime() / 60))
    }

    // MARK: - UI State

    @Published var isExporting: Bool = false
    @Published var exportError: String?
    @Published var ttsError: String?
    @Published var loadError: String?
    @Published var exportedData: ExportedFile?
    @Published var showExportSheet: Bool = false

    // Pre-export validation warning state
    @Published var showExportValidationAlert: Bool = false
    @Published var exportValidationErrors: [String] = []
    private var pendingExportTarget: ExportTarget?

    enum ExportTarget { case kdp, google }

    @Published var validationReport: ValidationReport?
    @Published var showValidationSheet: Bool = false

    @Published var isShowingThemePicker: Bool = false
    @Published var isShowingSettings: Bool = false
    @Published var isShowingTTSPlayer: Bool = false

    // MARK: - TTS State

    @Published var ttsIsPlaying: Bool = false
    @Published var ttsIsPaused: Bool = false
    @Published var ttsCurrentChapterIndex: Int = 0
    @Published var ttsHighlightRange: NSRange?

    // MARK: - Services

    private let fileManager = DocumentFileManager()
    private let audioController: AudioController
    private var autoSaveTask: Task<Void, Never>?
    private var documentID = UUID()

    private static let lastOpenURLKey = "lastOpenFileURL"

    // MARK: - Init

    init() {
        self.audioController = ServiceContainer.shared.audioController
        self.audioController.delegate = self
        restoreLastSession()
        selectFirstChapter()
        refreshStats()
    }

    private func restoreLastSession() {
        // Restore the last open document from UserDefaults
        if let data = UserDefaults.standard.data(forKey: DocumentViewModel.lastOpenURLKey),
           let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data) as URL? {
            if let loaded = try? fileManager.load(from: url) {
                document = loaded
                currentFileURL = url
                Logger.info("Restored last session: \(url.lastPathComponent)", category: .general)
                return
            }
        }
        Logger.info("No previous session to restore — starting fresh", category: .general)
    }

    // MARK: - Chapter Selection

    func selectFirstChapter() {
        selectedChapterID = document.chapters.first?.id
    }

    func select(chapter: Chapter) {
        selectedChapterID = chapter.id
    }

    func select(chapterAt index: Int) {
        guard index >= 0 && index < document.chapters.count else { return }
        selectedChapterID = document.chapters[index].id
    }

    // MARK: - Chapter Editing

    func updateChapterContent(_ content: String, for id: UUID) {
        guard let index = document.chapters.firstIndex(where: { $0.id == id }) else { return }
        objectWillChange.send()
        document.chapters[index].content = content
        refreshStats()
        markDirty()
    }

    func updateChapterTitle(_ title: String, for id: UUID) {
        guard let index = document.chapters.firstIndex(where: { $0.id == id }) else { return }
        objectWillChange.send()
        document.chapters[index].title = title
        markDirty()
    }

    func addChapter() {
        objectWillChange.send()
        document.addChapter()
        selectedChapterID = document.chapters.last?.id
        refreshStats()
        markDirty()
    }

    func deleteChapter(id: UUID) {
        guard let index = document.chapters.firstIndex(where: { $0.id == id }) else { return }
        objectWillChange.send()
        document.chapters.remove(at: index)
        if document.chapters.isEmpty {
            selectedChapterID = nil
        } else {
            let newIndex = min(index, document.chapters.count - 1)
            selectedChapterID = document.chapters[newIndex].id
        }
        refreshStats()
        markDirty()
    }

    func duplicateChapter(id: UUID) {
        guard let index = document.chapters.firstIndex(where: { $0.id == id }) else { return }
        objectWillChange.send()
        var copy = document.chapters[index]
        copy = Chapter(title: copy.title + " (Copy)", content: copy.content)
        document.chapters.insert(copy, at: index + 1)
        selectedChapterID = copy.id
        refreshStats()
        markDirty()
    }

    func moveChapters(from source: IndexSet, to destination: Int) {
        objectWillChange.send()
        document.chapters.move(fromOffsets: source, toOffset: destination)
        markDirty()
    }

    // MARK: - Metadata

    func updateMetadata(_ metadata: BookMetadata) {
        objectWillChange.send()
        document.metadata = metadata
        markDirty()
    }

    // MARK: - File Operations

    func newDocument() {
        stopTTS()
        document = EbookDocument()
        documentID = UUID()
        currentFileURL = nil
        hasUnsavedChanges = false
        UserDefaults.standard.removeObject(forKey: DocumentViewModel.lastOpenURLKey)
        selectFirstChapter()
        refreshStats()
    }

    func save() async {
        guard hasUnsavedChanges else { return }
        if let url = currentFileURL {
            do {
                try fileManager.save(document, to: url)
                hasUnsavedChanges = false
                persistLastOpenURL(url)
                Logger.info("Document saved to \(url.lastPathComponent)", category: .general)
            } catch {
                Logger.error("Save failed", error: error, category: .general)
            }
        } else {
            await saveAs()
        }
    }

    func saveAs() async {
        let title = document.metadata.title
        do {
            let url = try fileManager.save(
                document,
                named: title.isEmpty ? "Untitled" : title
            )
            currentFileURL = url
            hasUnsavedChanges = false
            persistLastOpenURL(url)
        } catch {
            Logger.error("Save As failed", error: error, category: .general)
        }
    }

    func load(from url: URL) {
        do {
            let loaded = try fileManager.load(from: url)
            document = loaded
            documentID = UUID()
            currentFileURL = url
            hasUnsavedChanges = false
            persistLastOpenURL(url)
            selectFirstChapter()
            refreshStats()
        } catch {
            loadError = "Could not open \"\(url.deletingPathExtension().lastPathComponent)\": \(error.localizedDescription)"
            Logger.error("Load failed", error: error, category: .general)
        }
    }

    private func persistLastOpenURL(_ url: URL) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: url as NSURL, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: DocumentViewModel.lastOpenURLKey)
        }
    }

    // MARK: - Export

    func exportKDP() async {
        guard !isExporting else { return }
        let report = document.validateForKDP()
        if !report.errors.isEmpty {
            exportValidationErrors = report.errors
            pendingExportTarget = .kdp
            showExportValidationAlert = true
            return
        }
        await performExportKDP()
    }

    func exportGoogle() async {
        guard !isExporting else { return }
        let report = document.validateForGoogle()
        if !report.errors.isEmpty {
            exportValidationErrors = report.errors
            pendingExportTarget = .google
            showExportValidationAlert = true
            return
        }
        await performExportGoogle()
    }

    /// Called when user confirms "Export Anyway" from the validation alert.
    func confirmExportDespiteErrors() async {
        guard let target = pendingExportTarget else { return }
        pendingExportTarget = nil
        switch target {
        case .kdp: await performExportKDP()
        case .google: await performExportGoogle()
        }
    }

    private func performExportKDP() async {
        isExporting = true
        exportError = nil
        do {
            let data = try await document.exportToKDP()
            let name = (document.metadata.title.isEmpty ? "Untitled" : document.metadata.title) + ".html"
            exportedData = ExportedFile(data: data, suggestedFileName: name, contentType: "text/html")
            showExportSheet = true
        } catch {
            exportError = "KDP export failed: \(error.localizedDescription)"
        }
        isExporting = false
    }

    private func performExportGoogle() async {
        isExporting = true
        exportError = nil
        do {
            let data = try await document.exportToGoogle()
            let name = (document.metadata.title.isEmpty ? "Untitled" : document.metadata.title) + ".epub"
            exportedData = ExportedFile(data: data, suggestedFileName: name, contentType: "application/epub+zip")
            showExportSheet = true
        } catch {
            exportError = "Google Play export failed: \(error.localizedDescription)"
        }
        isExporting = false
    }

    // MARK: - Validation

    func validateKDP() {
        validationReport = document.validateForKDP()
        showValidationSheet = true
    }

    func validateGoogle() {
        validationReport = document.validateForGoogle()
        showValidationSheet = true
    }

    // MARK: - Text-to-Speech

    func playTTS() {
        let chapter: Chapter?
        if let index = selectedChapterIndex {
            chapter = document.chapters[index]
            ttsCurrentChapterIndex = index
        } else if !document.chapters.isEmpty {
            chapter = document.chapters[0]
            ttsCurrentChapterIndex = 0
        } else {
            return
        }
        guard let c = chapter else { return }
        audioController.readChapter(c)
        ttsIsPlaying = true
        ttsIsPaused = false
    }

    func pauseTTS() {
        audioController.pauseTextToSpeech()
        ttsIsPaused = true
    }

    func resumeTTS() {
        audioController.resumeTextToSpeech()
        ttsIsPaused = false
    }

    func stopTTS() {
        audioController.stopTextToSpeech()
        ttsIsPlaying = false
        ttsIsPaused = false
        ttsHighlightRange = nil
    }

    func setTTSRate(_ rate: Float) {
        audioController.setSpeechRate(rate)
    }

    func setTTSVoice(_ voice: VoiceOption) {
        audioController.setVoice(voice)
    }

    func setTTSVolume(_ volume: Float) {
        audioController.setSpeechVolume(volume)
    }

    var availableVoices: [VoiceOption] {
        audioController.getAvailableVoices()
    }

    // MARK: - Auto-save

    private func markDirty() {
        hasUnsavedChanges = true
        scheduleAutoSave()
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            guard !Task.isCancelled, let self = self else { return }
            self.fileManager.autoSave(self.document, id: self.documentID)
        }
    }
}

// MARK: - AudioControllerDelegate

extension DocumentViewModel: AudioControllerDelegate {
    nonisolated func audioDidStart() {
        Task { @MainActor [weak self] in
            self?.ttsIsPlaying = true
            self?.ttsIsPaused = false
        }
    }

    nonisolated func audioDidFinish() {
        Task { @MainActor [weak self] in
            self?.ttsIsPlaying = false
            self?.ttsIsPaused = false
            self?.ttsHighlightRange = nil
        }
    }

    nonisolated func audioDidPause() {
        Task { @MainActor [weak self] in
            self?.ttsIsPaused = true
        }
    }

    nonisolated func audioPlaybackProgress(_ progress: Float) {
        // No-op for TTS — word highlighting handled via speechProgress
    }

    nonisolated func audioError(_ error: Error) {
        Task { @MainActor [weak self] in
            self?.ttsIsPlaying = false
            self?.ttsError = error.localizedDescription
        }
    }
}

// MARK: - Export Support

struct ExportedFile: Identifiable {
    let id = UUID()
    let data: Data
    let suggestedFileName: String
    let contentType: String
}

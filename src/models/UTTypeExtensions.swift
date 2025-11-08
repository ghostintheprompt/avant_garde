import UniformTypeIdentifiers

extension UTType {
    static let avantGardeDocument = UTType(exportedAs: "com.avantgarde.document")
    static let epub = UTType(filenameExtension: "epub") ?? UTType.data
    static let html = UTType(filenameExtension: "html") ?? UTType.html
}

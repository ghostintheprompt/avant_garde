import Foundation

/// Protocol for format conversion between different ebook formats
protocol Converter {
    /// Converts an ebook from one format, calling completion handler when done
    /// - Parameters:
    ///   - source: The source format to convert from
    ///   - completion: Completion handler with success/failure result
    func convert(from source: EbookFormat, completion: @escaping (Bool) -> Void)
}

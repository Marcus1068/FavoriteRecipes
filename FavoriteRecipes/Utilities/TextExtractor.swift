import Foundation
import Vision
import PDFKit
import UIKit

/// Reads text from ingredient photos (Vision OCR) and PDFs (PDFKit).
enum TextExtractor {

    /// Recognized text in a photo, or nil if the image is unreadable or has no text.
    static func text(fromImageData data: Data) async -> String? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        guard let observations = try? await request.perform(on: cgImage) else { return nil }
        let text = observations
            .map(\.transcript)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    /// Text of all PDF pages, or nil if the PDF is unreadable or has no text layer.
    /// Runs off the main actor because large PDFs can take a while.
    @concurrent
    nonisolated static func text(fromPDFData data: Data) async -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        let text = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}

import Foundation
import Vision
import PDFKit
import UIKit

enum TextExtractor {

    static func extract(from recipe: Recipe) async -> String {
        switch recipe.ingredientsType {
        case .text:
            let text = recipe.ingredientsText ?? ""
            return text.isEmpty ? "No ingredients text entered." : text

        case .photo:
            guard let data = recipe.ingredientsImageData,
                  let image = UIImage(data: data),
                  let cgImage = image.cgImage else {
                return "No ingredients photo available."
            }
            let recognized = await recognizeText(in: cgImage)
            return recognized.isEmpty ? "No text could be recognized in the photo." : recognized

        case .pdf:
            guard let data = recipe.ingredientsPDFData,
                  let document = PDFDocument(data: data) else {
                return "No PDF available."
            }
            let extracted = extractText(from: document)
            return extracted.isEmpty ? "No text found in the PDF." : extracted
        }
    }

    // MARK: - Vision OCR

    private static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    // MARK: - PDF Text Extraction

    private static func extractText(from document: PDFDocument) -> String {
        (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

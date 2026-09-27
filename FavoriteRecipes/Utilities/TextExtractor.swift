import Foundation
import Vision
import PDFKit
import UIKit

enum TextExtractor {

    // Called from SwiftUI views that hold a Recipe @Model reference.
    static func extract(from recipe: Recipe) async -> String {
        await extract(
            type:       recipe.ingredientsType,
            text:       recipe.ingredientsText,
            imageData:  recipe.ingredientsImageData,
            pdfData:    recipe.ingredientsPDFData
        )
    }

    // Called from Transferable types that work with plain value copies.
    static func extract(
        type:      IngredientsType,
        text:      String?,
        imageData: Data?,
        pdfData:   Data?
    ) async -> String {
        switch type {
        case .text:
            let entered = text ?? ""
            return entered.isEmpty ? String(localized: .noIngredientsTextEntered) : entered

        case .photo:
            guard let data = imageData,
                  let image = UIImage(data: data),
                  let cgImage = image.cgImage else {
                return String(localized: .noIngredientsPhotoAvailable)
            }
            let recognized = await recognizeText(in: cgImage)
            return recognized.isEmpty ? String(localized: .noTextRecognizedInPhoto) : recognized

        case .pdf:
            guard let data = pdfData,
                  let document = PDFDocument(data: data) else {
                return String(localized: .noPDFAvailable)
            }
            let extracted = extractText(from: document)
            return extracted.isEmpty ? String(localized: .noTextFoundInPDF) : extracted
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

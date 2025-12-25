//
//  ImageProcessingService.swift
//  stickermaker
//
//  Created by Claude on 12/22/24.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

@MainActor
class ImageProcessingService {
    static let shared = ImageProcessingService()

    private init() {}

    // MARK: - Background Removal

    func removeBackground(from image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: ImageProcessingError.maskGenerationFailed)
                    return
                }

                do {
                    let maskedImage = try self.generateMaskedImage(from: image, using: result)
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: ImageProcessingError.cgImageConversionFailed)
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func generateMaskedImage(from image: UIImage, using observation: VNInstanceMaskObservation) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.cgImageConversionFailed
        }

        let maskPixelBuffer = try observation.generateScaledMaskForImage(
            forInstances: observation.allInstances,
            from: VNImageRequestHandler(cgImage: cgImage)
        )

        let ciImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = CIImage.empty()
        filter.maskImage = maskCIImage

        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.filterApplicationFailed
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageProcessingError.imageGenerationFailed
        }

        return UIImage(cgImage: outputCGImage)
    }

    // MARK: - Image Cropping

    func cropToAspectRatio(_ image: UIImage, aspectRatio: AspectRatio) -> UIImage {
        guard let cgImage = image.cgImage,
              let targetRatio = aspectRatio.ratio else { return image }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        let originalRatio = originalWidth / originalHeight

        var newWidth: CGFloat
        var newHeight: CGFloat

        if targetRatio < originalRatio {
            // Target ratio is narrower (portrait) - base on height
            newHeight = originalHeight
            newWidth = originalHeight * targetRatio
        } else {
            // Target ratio is wider - base on width
            newWidth = originalWidth
            newHeight = originalWidth / targetRatio
        }

        // Crop from center
        let x = (originalWidth - newWidth) / 2
        let y = (originalHeight - newHeight) / 2

        let cropRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return image }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Image Resizing

    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If already small enough, don't resize
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Maintain aspect ratio while resizing
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Scale Image

    func scaleImage(_ image: UIImage, scale: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)

        // Calculate new size
        let newWidth = originalWidth * scale
        let newHeight = originalHeight * scale

        // Keep canvas size as original to maintain centering
        let canvasSize = CGSize(width: originalWidth, height: originalHeight)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let scaledImage = renderer.image { context in
            // Transparent background
            context.cgContext.clear(CGRect(origin: .zero, size: canvasSize))

            // Draw scaled image in center
            let x = (originalWidth - newWidth) / 2
            let y = (originalHeight - newHeight) / 2
            let rect = CGRect(x: x, y: y, width: newWidth, height: newHeight)

            image.draw(in: rect)
        }

        return scaledImage
    }
}

// MARK: - Error Types

enum ImageProcessingError: LocalizedError {
    case cgImageConversionFailed
    case maskGenerationFailed
    case filterApplicationFailed
    case imageGenerationFailed

    var errorDescription: String? {
        switch self {
        case .cgImageConversionFailed:
            return "CGImage 변환 실패"
        case .maskGenerationFailed:
            return "마스크 생성 실패"
        case .filterApplicationFailed:
            return "필터 적용 실패"
        case .imageGenerationFailed:
            return "이미지 생성 실패"
        }
    }
}

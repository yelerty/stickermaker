//
//  StickerViewModel.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine
import Photos

@MainActor
class StickerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var selectedPhotoItem: PhotosPickerItem?

    func loadImage() async {
        guard let photoItem = selectedPhotoItem else { return }

        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "이미지를 불러올 수 없습니다."
                return
            }

            selectedImage = image
            await removeBackground(from: image)
        } catch {
            errorMessage = "이미지 로드 실패: \(error.localizedDescription)"
        }
    }

    func removeBackground(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            let processedImage = try await processImageWithVision(image)
            self.processedImage = processedImage
        } catch {
            errorMessage = "배경 제거 실패: \(error.localizedDescription)"
            // 배경 제거 실패 시 원본 이미지 사용
            self.processedImage = image
        }

        isProcessing = false
    }

    private func processImageWithVision(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: NSError(domain: "StickerMaker", code: 2, userInfo: [NSLocalizedDescriptionKey: "마스크 생성 실패"]))
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
                continuation.resume(throwing: NSError(domain: "StickerMaker", code: 1, userInfo: [NSLocalizedDescriptionKey: "CGImage 변환 실패"]))
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
            throw NSError(domain: "StickerMaker", code: 1, userInfo: [NSLocalizedDescriptionKey: "CGImage 변환 실패"])
        }

        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: VNImageRequestHandler(cgImage: cgImage))

        let ciImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = CIImage.empty()
        filter.maskImage = maskCIImage

        guard let outputImage = filter.outputImage else {
            throw NSError(domain: "StickerMaker", code: 3, userInfo: [NSLocalizedDescriptionKey: "필터 적용 실패"])
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw NSError(domain: "StickerMaker", code: 4, userInfo: [NSLocalizedDescriptionKey: "이미지 생성 실패"])
        }

        return UIImage(cgImage: outputCGImage)
    }

    func saveSticker() async {
        guard let image = processedImage else {
            errorMessage = "저장할 이미지가 없습니다."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            // PNG 형식으로 저장하여 투명도 유지
            guard let pngData = image.pngData() else {
                errorMessage = "이미지 변환 실패"
                isSaving = false
                return
            }

            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: pngData, options: nil)
            }
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func reset() {
        selectedImage = nil
        processedImage = nil
        selectedPhotoItem = nil
        errorMessage = nil
    }
}

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
import AVFoundation
import UniformTypeIdentifiers

// AspectRatio enum은 VideoToGIFMaker.swift에 정의되어 있음
// 여기서는 재사용

@MainActor
class StickerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var isProcessing = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var videoURL: URL?
    @Published var videoDuration: Double = 0
    @Published var selectedTime: Double = 0
    @Published var showVideoCapture = false
    @Published var removeBackgroundEnabled = true
    @Published var aspectRatio: AspectRatio = .original

    private let imageProcessingService = ImageProcessingService.shared

    func loadImage() async {
        guard let photoItem = selectedPhotoItem else { return }

        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "이미지를 불러올 수 없습니다."
                return
            }

            selectedImage = image

            // 비율 조정
            var processedImage = image
            if aspectRatio != .original {
                processedImage = imageProcessingService.cropToAspectRatio(processedImage, aspectRatio: aspectRatio)
            }

            // 배경 제거
            if removeBackgroundEnabled {
                await removeBackground(from: processedImage)
            } else {
                self.processedImage = processedImage
            }
        } catch {
            errorMessage = "이미지 로드 실패: \(error.localizedDescription)"
        }
    }

    func removeBackground(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil

        do {
            let processedImage = try await imageProcessingService.removeBackground(from: image)
            self.processedImage = processedImage
        } catch {
            errorMessage = "배경 제거 실패: \(error.localizedDescription)"
            // 배경 제거 실패 시 원본 이미지 사용
            self.processedImage = image
        }

        isProcessing = false
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
        selectedVideoItem = nil
        videoURL = nil
        showVideoCapture = false
        errorMessage = nil
    }

    func loadVideo() async {
        guard let videoItem = selectedVideoItem else { return }

        isProcessing = true
        errorMessage = nil

        do {
            guard let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) else {
                errorMessage = "비디오를 불러올 수 없습니다."
                isProcessing = false
                return
            }

            let asset = AVURLAsset(url: movie.url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)

            await MainActor.run {
                self.videoURL = movie.url
                self.videoDuration = durationSeconds
                self.selectedTime = durationSeconds / 2
                self.showVideoCapture = true
            }

            // 초기 프레임 캡처
            await captureVideoFrame()
        } catch {
            errorMessage = "비디오 로드 실패: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func captureVideoFrame() async {
        guard let videoURL = videoURL else { return }

        do {
            let asset = AVURLAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero

            let time = CMTime(seconds: selectedTime, preferredTimescale: 600)

            let cgImage = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let cgImage = cgImage {
                        continuation.resume(returning: cgImage)
                    } else {
                        continuation.resume(throwing: NSError(domain: "StickerViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate image"]))
                    }
                }
            }

            let image = UIImage(cgImage: cgImage)

            selectedImage = image
            await removeBackground(from: image)
        } catch {
            errorMessage = "프레임 캡처 실패: \(error.localizedDescription)"
        }
    }
}

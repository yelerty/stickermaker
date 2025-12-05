//
//  VideoToGIFMaker.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers
import ImageIO
import Photos
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

class VideoToGIFViewModel: ObservableObject {
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var videoURL: URL?
    @Published var duration: Double = 0
    @Published var startTime: Double = 0
    @Published var endTime: Double = 1
    @Published var frameRate: Int = 10
    @Published var frameDelay: Double = 0.1 // 프레임 간 딜레이 (초)
    @Published var isProcessing = false
    @Published var generatedGIFURL: URL?
    @Published var errorMessage: String?
    @Published var removeBackground = false
    @Published var thumbnailImage: UIImage?

    private var asset: AVAsset?

    func loadVideo() async {
        guard let videoItem = selectedVideoItem else { return }

        isProcessing = true

        do {
            guard let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) else {
                errorMessage = "비디오를 불러올 수 없습니다."
                isProcessing = false
                return
            }

            let asset = AVAsset(url: movie.url)
            self.asset = asset

            let durationValue = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(durationValue)

            await MainActor.run {
                self.videoURL = movie.url
                self.duration = durationSeconds
                self.endTime = min(3.0, durationSeconds) // 기본 3초 또는 전체 길이
                self.isProcessing = false
            }

            // 썸네일 생성
            await generateThumbnail()
        } catch {
            await MainActor.run {
                self.errorMessage = "비디오 로드 실패: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }

    func generateThumbnail() async {
        guard let asset = asset else { return }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let time = CMTime(seconds: startTime, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)

            await MainActor.run {
                self.thumbnailImage = UIImage(cgImage: cgImage)
            }
        } catch {
            print("썸네일 생성 실패: \(error)")
        }
    }

    func createGIF() {
        guard let asset = asset else {
            errorMessage = "비디오를 먼저 선택하세요."
            return
        }

        isProcessing = true

        Task {
            do {
                let frames = try await extractFrames(from: asset, start: startTime, end: endTime)

                var processedFrames = frames
                if removeBackground {
                    processedFrames = try await removeBackgroundFromFrames(frames)
                }

                let gifURL = try await generateGIF(from: processedFrames)

                await MainActor.run {
                    self.generatedGIFURL = gifURL
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "GIF 생성 실패: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }

    private func extractFrames(from asset: AVAsset, start: Double, end: Double) async throws -> [UIImage] {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let duration = end - start
        let frameInterval = duration / Double(frameRate)
        var frames: [UIImage] = []

        for i in 0..<frameRate {
            let timeValue = start + (Double(i) * frameInterval)
            let time = CMTime(seconds: timeValue, preferredTimescale: 600)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                frames.append(UIImage(cgImage: cgImage))
            } catch {
                print("프레임 추출 실패 at \(timeValue): \(error)")
            }
        }

        return frames
    }

    private func removeBackgroundFromFrames(_ frames: [UIImage]) async throws -> [UIImage] {
        var processedFrames: [UIImage] = []

        for frame in frames {
            let processed = try await removeBackground(from: frame)
            processedFrames.append(processed)
        }

        return processedFrames
    }

    private func removeBackground(from image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(returning: image)
                    return
                }

                do {
                    let maskedImage = try self.generateMaskedImage(from: image, using: result)
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(returning: image)
                }
            }

            guard let cgImage = image.cgImage else {
                continuation.resume(returning: image)
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: image)
            }
        }
    }

    private func generateMaskedImage(from image: UIImage, using observation: VNInstanceMaskObservation) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VideoToGIF", code: 1, userInfo: nil)
        }

        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: VNImageRequestHandler(cgImage: cgImage))

        let ciImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = CIImage.empty()
        filter.maskImage = maskCIImage

        guard let outputImage = filter.outputImage else {
            throw NSError(domain: "VideoToGIF", code: 2, userInfo: nil)
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw NSError(domain: "VideoToGIF", code: 3, userInfo: nil)
        }

        return UIImage(cgImage: outputCGImage)
    }

    private func generateGIF(from frames: [UIImage]) async throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")

        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            throw NSError(domain: "VideoToGIF", code: 1, userInfo: [NSLocalizedDescriptionKey: "GIF 생성 실패"])
        }

        let gifProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]

        // frameDelay 프로퍼티 사용
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: self.frameDelay
            ]
        ]

        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        for frame in frames {
            guard let cgImage = frame.cgImage else { continue }
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "VideoToGIF", code: 2, userInfo: [NSLocalizedDescriptionKey: "GIF 저장 실패"])
        }

        return fileURL
    }

    func saveGIF() {
        guard let gifURL = generatedGIFURL else { return }

        Task {
            do {
                let data = try Data(contentsOf: gifURL)
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "GIF 저장 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    func reset() {
        selectedVideoItem = nil
        videoURL = nil
        asset = nil
        generatedGIFURL = nil
        duration = 0
        startTime = 0
        endTime = 1
        thumbnailImage = nil
        errorMessage = nil
    }
}

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

struct VideoToGIFView: View {
    @StateObject private var viewModel = VideoToGIFViewModel()
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let gifURL = viewModel.generatedGIFURL {
                    // GIF 미리보기
                    ScrollView {
                        VStack(spacing: 20) {
                            GIFPreviewView(url: gifURL, frameDelay: viewModel.frameDelay)
                                .frame(maxHeight: 400)
                                .background(CheckerboardView())
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding()

                            HStack(spacing: 15) {
                                Button(action: {
                                    viewModel.saveGIF()
                                    showingSaveAlert = true
                                }) {
                                    Label("저장", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)

                                Button(action: {
                                    viewModel.reset()
                                }) {
                                    Label("다시 만들기", systemImage: "arrow.clockwise")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if viewModel.isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(viewModel.videoURL == nil ? "비디오 로딩 중..." : "GIF 생성 중...")
                            .font(.headline)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.videoURL != nil {
                    // 비디오 편집 화면
                    ScrollView {
                        VStack(spacing: 20) {
                            // 썸네일 미리보기
                            if let thumbnail = viewModel.thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding(.horizontal)
                            }

                            // 구간 설정
                            VStack(alignment: .leading, spacing: 15) {
                                Text("GIF 구간 선택")
                                    .font(.headline)
                                    .padding(.horizontal)

                                VStack(spacing: 15) {
                                    HStack {
                                        Text("시작")
                                            .frame(width: 60, alignment: .leading)
                                        Slider(value: $viewModel.startTime, in: 0...max(0, viewModel.endTime - 0.1))
                                            .onChange(of: viewModel.startTime) { oldValue, newValue in
                                                Task {
                                                    await viewModel.generateThumbnail()
                                                }
                                            }
                                        Text(formatTime(viewModel.startTime))
                                            .frame(width: 50)
                                            .font(.caption)
                                    }

                                    HStack {
                                        Text("종료")
                                            .frame(width: 60, alignment: .leading)
                                        Slider(value: $viewModel.endTime, in: min(viewModel.startTime + 0.1, viewModel.duration)...viewModel.duration)
                                        Text(formatTime(viewModel.endTime))
                                            .frame(width: 50)
                                            .font(.caption)
                                    }

                                    Text("선택된 구간: \(formatTime(viewModel.endTime - viewModel.startTime))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            }

                            // GIF 설정
                            VStack(spacing: 15) {
                                // 프레임 레이트
                                HStack {
                                    Text("프레임 수")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(viewModel.frameRate) 프레임")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Slider(value: Binding(
                                    get: { Double(viewModel.frameRate) },
                                    set: { viewModel.frameRate = Int($0) }
                                ), in: 5...30, step: 1)

                                Divider()

                                // 프레임 간 딜레이
                                HStack {
                                    Text("프레임 간 딜레이")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(String(format: "%.2f", viewModel.frameDelay))초")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Slider(value: $viewModel.frameDelay, in: 0.03...0.5, step: 0.01)

                                Text("총 재생시간: \(String(format: "%.1f", Double(viewModel.frameRate) * viewModel.frameDelay))초")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Divider()

                                // 배경 제거
                                Toggle(isOn: $viewModel.removeBackground) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "scissors")
                                            .foregroundStyle(.tint)
                                        Text("배경 제거")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)

                            // GIF 생성 버튼
                            Button(action: {
                                viewModel.createGIF()
                            }) {
                                Label("GIF 만들기", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    // 초기 상태
                    VStack(spacing: 30) {
                        Image(systemName: "video.badge.waveform")
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)

                        VStack(spacing: 10) {
                            Text("비디오로 GIF 만들기")
                                .font(.title)
                                .bold()

                            Text("비디오의 원하는 구간을\n선택하여 GIF로 변환합니다")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        PhotosPicker(
                            selection: $viewModel.selectedVideoItem,
                            matching: .videos
                        ) {
                            Label("비디오 선택", systemImage: "video.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("비디오 → GIF")
            .navigationBarTitleDisplayMode(.inline)
            .alert("저장 완료", isPresented: $showingSaveAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("GIF가 사진 라이브러리에 저장되었습니다.")
            }
        }
        .onChange(of: viewModel.selectedVideoItem) { oldValue, newValue in
            Task {
                await viewModel.loadVideo()
            }
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, milliseconds)
    }
}

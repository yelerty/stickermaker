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

enum AspectRatio: CaseIterable, Identifiable {
    case original
    case square
    case vertical_9_16
    case vertical_4_5
    case vertical_5_7
    case vertical_3_4
    case vertical_3_5
    case vertical_2_3

    var id: String { localizedName }

    var localizedName: String {
        switch self {
        case .original: return "option.original".localized
        case .square: return "option.square".localized
        case .vertical_9_16: return "9:16"
        case .vertical_4_5: return "4:5"
        case .vertical_5_7: return "5:7"
        case .vertical_3_4: return "3:4"
        case .vertical_3_5: return "3:5"
        case .vertical_2_3: return "2:3"
        }
    }

    var ratio: CGFloat? {
        switch self {
        case .original: return nil
        case .square: return 1.0
        case .vertical_9_16: return 9.0 / 16.0
        case .vertical_4_5: return 4.0 / 5.0
        case .vertical_5_7: return 5.0 / 7.0
        case .vertical_3_4: return 3.0 / 4.0
        case .vertical_3_5: return 3.0 / 5.0
        case .vertical_2_3: return 2.0 / 3.0
        }
    }
}

enum ScaleAnimation: CaseIterable, Identifiable {
    case none
    case zoomInOut
    case zoomIn
    case zoomOut
    case pulse

    var id: String { localizedName }

    var localizedName: String {
        switch self {
        case .none: return "animation.none".localized
        case .zoomInOut: return "animation.zoom_in_out".localized
        case .zoomIn: return "animation.zoom_in".localized
        case .zoomOut: return "animation.zoom_out".localized
        case .pulse: return "animation.pulse".localized
        }
    }

    func scaleForFrame(_ frameIndex: Int, totalFrames: Int) -> CGFloat {
        let progress = CGFloat(frameIndex) / CGFloat(max(totalFrames - 1, 1))

        switch self {
        case .none:
            return 1.0

        case .zoomInOut:
            // 사인 곡선으로 작아졌다 커지기 (0.7 ~ 1.0 범위)
            let scale = sin(progress * .pi) * 0.3 + 0.7
            return scale

        case .zoomIn:
            // 선형으로 계속 작아지기 (1.0 -> 0.5)
            return 1.0 - (progress * 0.5)

        case .zoomOut:
            // 선형으로 계속 커지기 (0.7 -> 1.0)
            return 0.7 + (progress * 0.3)

        case .pulse:
            // 작은 상태(0.7)에서 시작해서 30% 커지기 (0.7 -> 1.0)
            return 0.7 + (progress * 0.3)
        }
    }
}

class VideoToGIFViewModel: ObservableObject {
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var videoURL: URL?
    @Published var duration: Double = 0
    @Published var startTime: Double = 0
    @Published var endTime: Double = 1
    @Published var frameRate: Int = 10
    @Published var frameDelay: Double = 0.1 // 프레임 간 딜레이 (초)
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage: String = ""
    @Published var generatedGIFURL: URL?
    @Published var errorMessage: String?
    @Published var removeBackground = false
    @Published var thumbnailImage: UIImage?
    @Published var aspectRatio: AspectRatio = .original
    @Published var scaleAnimation: ScaleAnimation = .none

    private var asset: AVAsset?
    private var isCancelled = false
    private let imageProcessingService = ImageProcessingService.shared

    func loadVideo() async {
        guard let videoItem = selectedVideoItem else { return }

        isProcessing = true

        do {
            guard let movie = try await videoItem.loadTransferable(type: VideoTransferable.self) else {
                errorMessage = "비디오를 불러올 수 없습니다."
                isProcessing = false
                return
            }

            let asset = AVURLAsset(url: movie.url)
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

        let time = CMTime(seconds: startTime, preferredTimescale: 600)
        imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
            if let error = error {
                print("썸네일 생성 실패: \(error)")
                return
            }

            guard let cgImage = cgImage else { return }

            Task { @MainActor in
                self.thumbnailImage = UIImage(cgImage: cgImage)
            }
        }
    }

    func createGIF() {
        guard let asset = asset else {
            errorMessage = "비디오를 먼저 선택하세요."
            return
        }

        isCancelled = false
        isProcessing = true
        processingProgress = 0.0

        Task {
            do {
                await updateProgress(0.1, "프레임 추출 중...")
                let frames = try await extractFrames(from: asset, start: startTime, end: endTime)

                if isCancelled {
                    await cancelProcessing()
                    return
                }

                var processedFrames = frames
                if removeBackground {
                    await updateProgress(0.3, "배경 제거 중...")
                    processedFrames = try await removeBackgroundFromFrames(frames)

                    if isCancelled {
                        await cancelProcessing()
                        return
                    }
                }

                await updateProgress(0.8, "GIF 생성 중...")
                let gifURL = try await generateGIF(from: processedFrames)

                if isCancelled {
                    await cancelProcessing()
                    return
                }

                await MainActor.run {
                    self.processingProgress = 1.0
                    self.processingMessage = "완료!"
                    self.generatedGIFURL = gifURL
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "GIF 생성 실패: \(error.localizedDescription)"
                    self.isProcessing = false
                    self.processingProgress = 0.0
                    self.processingMessage = ""
                }
            }
        }
    }

    func cancelGIFCreation() {
        isCancelled = true
    }

    private func updateProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            self.processingProgress = progress
            self.processingMessage = message
        }
    }

    private func cancelProcessing() async {
        await MainActor.run {
            self.isProcessing = false
            self.processingProgress = 0.0
            self.processingMessage = ""
            self.errorMessage = "작업이 취소되었습니다."
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
                let cgImage = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                    imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let cgImage = cgImage {
                            continuation.resume(returning: cgImage)
                        } else {
                            continuation.resume(throwing: NSError(domain: "VideoToGIFMaker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate image"]))
                        }
                    }
                }

                var image = UIImage(cgImage: cgImage)

                // 비율에 맞게 이미지 크롭
                if aspectRatio != .original {
                    image = imageProcessingService.cropToAspectRatio(image, aspectRatio: aspectRatio)
                }

                // 스케일 애니메이션 적용
                if scaleAnimation != .none {
                    let scale = scaleAnimation.scaleForFrame(i, totalFrames: frameRate)
                    image = imageProcessingService.scaleImage(image, scale: scale)
                }

                frames.append(image)
            } catch {
                print("프레임 추출 실패 at \(timeValue): \(error)")
            }
        }

        return frames
    }

    private func removeBackgroundFromFrames(_ frames: [UIImage]) async throws -> [UIImage] {
        var processedFrames: [UIImage] = []

        for (index, frame) in frames.enumerated() {
            if isCancelled {
                throw NSError(domain: "VideoToGIF", code: 999, userInfo: [NSLocalizedDescriptionKey: "취소됨"])
            }

            let progress = 0.3 + (Double(index + 1) / Double(frames.count)) * 0.4 // 30% ~ 70%
            await updateProgress(progress, "배경 제거 중 (\(index + 1)/\(frames.count))...")

            let processed = try await imageProcessingService.removeBackground(from: frame)
            processedFrames.append(processed)
        }

        return processedFrames
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

    func backToEdit() {
        generatedGIFURL = nil
        errorMessage = nil
        // Keep all other settings intact (videoURL, asset, startTime, endTime, frameRate, frameDelay, removeBackground)
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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                if let gifURL = viewModel.generatedGIFURL {
                    // GIF 미리보기
                    ScrollView {
                        VStack(spacing: 20) {
                            GIFPreviewView(url: gifURL, frameDelay: viewModel.frameDelay)
                                .frame(maxHeight: 400)
                                .background(CheckerboardView())
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding()

                            VStack(spacing: 12) {
                                // 저장 버튼
                                Button(action: {
                                    viewModel.saveGIF()
                                    showingSaveAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("button.save".localized)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())

                                // 편집 다시하기 & 새로 만들기 버튼
                                HStack(spacing: 12) {
                                    Button(action: {
                                        viewModel.backToEdit()
                                    }) {
                                        HStack {
                                            Image(systemName: "slider.horizontal.3")
                                            Text("button.edit_again".localized)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())

                                    Button(action: {
                                        viewModel.reset()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("button.new".localized)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if viewModel.isProcessing {
                    VStack(spacing: 30) {
                        VStack(spacing: 15) {
                            ProgressView(value: viewModel.processingProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.appPrimary))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .frame(maxWidth: 300)

                            Text("\(Int(viewModel.processingProgress * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appPrimary)
                        }

                        VStack(spacing: 10) {
                            if !viewModel.processingMessage.isEmpty {
                                Text(viewModel.processingMessage)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            Text(viewModel.videoURL == nil ? "video_gif.loading".localized : "message.please_wait".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            viewModel.cancelGIFCreation()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("button.cancel".localized)
                            }
                            .frame(width: 200)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else if viewModel.videoURL != nil {
                    // 비디오 편집 화면
                    ScrollView {
                        if isLandscape {
                            landscapeEditView(geometry: geometry)
                        } else {
                            portraitEditView
                        }
                    }
                } else {
                    // 초기 상태
                    if isLandscape {
                        landscapeEmptyView(geometry: geometry)
                    } else {
                        portraitEmptyView
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("video_gif.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ThemeToggleButton()
                }
            }
            .alert("message.saved".localized, isPresented: $showingSaveAlert) {
                Button("button.ok".localized, role: .cancel) { }
            } message: {
                Text("gif.saved.message".localized)
            }
        }
        .onChange(of: viewModel.selectedVideoItem) { oldValue, newValue in
            Task {
                await viewModel.loadVideo()
            }
        }
    }

    func landscapeEditView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // 왼쪽: 썸네일 미리보기 (40%)
            VStack {
                if let thumbnail = viewModel.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .frame(width: geometry.size.width * 0.35)
            .padding(.leading, Spacing.md)

            // 오른쪽: 컨트롤 패널 (60%)
            VStack(spacing: 15) {
                // 구간 설정
                VStack(alignment: .leading, spacing: 15) {
                    Text("video_gif.select_section".localized)
                        .font(.headline)

                    VStack(spacing: 15) {
                        HStack {
                            Text("video_gif.start".localized)
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
                            Text("video_gif.end".localized)
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
                }

                // GIF 설정
                settingsPanel

                // GIF 생성 버튼
                Button(action: {
                    viewModel.createGIF()
                }) {
                    Label("gif.create".localized, systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)

                // 다른 비디오 선택 버튼
                PhotosPicker(
                    selection: $viewModel.selectedVideoItem,
                    matching: .videos
                ) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath.video")
                        Text("video_gif.select_other".localized)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .frame(width: geometry.size.width * 0.55)
            .padding(.trailing, Spacing.md)
        }
    }

    var portraitEditView: some View {
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
                Text("video_gif.select_section".localized)
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
            settingsPanel
                .padding(.horizontal)

            // GIF 생성 버튼
            Button(action: {
                viewModel.createGIF()
            }) {
                Label("gif.create".localized, systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            // 다른 비디오 선택 버튼
            PhotosPicker(
                selection: $viewModel.selectedVideoItem,
                matching: .videos
            ) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.video")
                    Text("다른 비디오 선택")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    func landscapeEmptyView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // 왼쪽: Empty State (40%)
            VStack {
                EmptyStateView(
                    icon: "video.badge.waveform",
                    title: "비디오로 GIF 만들기",
                    message: "비디오의 원하는 구간을\n선택하여 GIF로 변환합니다"
                )
            }
            .frame(width: geometry.size.width * 0.35)
            .padding(.leading, Spacing.md)

            // 오른쪽: 선택 버튼 (60%)
            VStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.sm) {
                    Text("button.select_video".localized)
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(
                        selection: $viewModel.selectedVideoItem,
                        matching: .videos
                    ) {
                        HStack {
                            Image(systemName: "video.badge.plus")
                            Text("button.select_video".localized)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .frame(width: geometry.size.width * 0.55)
            .padding(.trailing, Spacing.md)
        }
    }

    var portraitEmptyView: some View {
        VStack(spacing: 30) {
            Image(systemName: "video.badge.waveform")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text("video_gif.empty.title".localized)
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
                Label("button.select_video".localized, systemImage: "video.badge.plus")
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

    var settingsPanel: some View {
        VStack(spacing: 15) {
            // 프레임 레이트
            HStack {
                Text("video_gif.frame_count".localized)
                    .font(.subheadline)
                Spacer()
                Text("\(viewModel.frameRate) 프레임")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { Double(viewModel.frameRate) },
                set: { viewModel.frameRate = Int($0) }
            ), in: 5...45, step: 1)

            Divider()

            // 프레임 간 딜레이
            HStack {
                Text("gif.frame_delay".localized)
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

            // 프레임 비율
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "aspectratio")
                        .foregroundStyle(.tint)
                    Text("option.aspect_ratio".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Picker("option.aspect_ratio".localized, selection: $viewModel.aspectRatio) {
                    ForEach(AspectRatio.allCases) { ratio in
                        Text(ratio.localizedName).tag(ratio)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.appPrimary)
            }

            Divider()

            // 크기 애니메이션
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(.tint)
                    Text("animation.scale".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Picker("animation.scale".localized, selection: $viewModel.scaleAnimation) {
                    ForEach(ScaleAnimation.allCases) { animation in
                        Text(animation.localizedName).tag(animation)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.appPrimary)
            }

            Divider()

            // 배경 제거
            Toggle(isOn: $viewModel.removeBackground) {
                HStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .foregroundStyle(.tint)
                    Text("option.remove_background".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, milliseconds)
    }
}

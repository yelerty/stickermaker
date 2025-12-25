//
//  GIFMaker.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import MobileCoreServices
import Combine
import Photos
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class GIFMakerViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var images: [UIImage] = []
    @Published var isProcessing = false
    @Published var generatedGIFURL: URL?
    @Published var errorMessage: String?
    @Published var frameDelay: Double = 0.2
    @Published var removeBackground = false

    private let imageProcessingService = ImageProcessingService.shared

    func loadImages() async {
        isProcessing = true
        var loadedImages: [UIImage] = []

        for item in selectedItems {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    continue
                }
                loadedImages.append(image)
            } catch {
                errorMessage = "이미지 로드 실패: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            self.images = loadedImages
            self.isProcessing = false
        }
    }

    func createGIF() {
        guard !images.isEmpty else {
            errorMessage = "최소 1개 이상의 이미지가 필요합니다."
            return
        }

        isProcessing = true

        Task {
            do {
                // 배경 제거 옵션이 활성화된 경우 모든 이미지의 배경 제거
                var processedImages = images
                if removeBackground {
                    processedImages = try await removeBackgroundFromImages(images)
                }

                let gifURL = try await generateGIF(from: processedImages, delay: frameDelay)
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

    private func removeBackgroundFromImages(_ images: [UIImage]) async throws -> [UIImage] {
        var processedImages: [UIImage] = []

        for image in images {
            let processedImage = try await imageProcessingService.removeBackground(from: image)
            processedImages.append(processedImage)
        }

        return processedImages
    }

    private func generateGIF(from images: [UIImage], delay: Double) async throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")

        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.gif.identifier as CFString,
            images.count,
            nil
        ) else {
            throw NSError(domain: "GIFMaker", code: 1, userInfo: [NSLocalizedDescriptionKey: "GIF 생성 실패"])
        }

        let gifProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]

        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: delay
            ]
        ]

        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        for image in images {
            guard let cgImage = image.cgImage else { continue }
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "GIFMaker", code: 2, userInfo: [NSLocalizedDescriptionKey: "GIF 저장 실패"])
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

    func removeImage(at index: Int) {
        images.remove(at: index)
        selectedItems.remove(at: index)
    }

    func reset() {
        selectedItems.removeAll()
        images.removeAll()
        generatedGIFURL = nil
        errorMessage = nil
    }
}

struct GIFMakerView: View {
    @StateObject private var viewModel = GIFMakerViewModel()
    @State private var showingSaveAlert = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                VStack(spacing: 20) {
                    if let gifURL = viewModel.generatedGIFURL {
                    ScrollView {
                        VStack(spacing: 20) {
                            // GIF 미리보기
                            GIFPreviewView(url: gifURL, frameDelay: viewModel.frameDelay)
                                .frame(maxHeight: 400)
                                .background(CheckerboardView())
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding()

                            // GIF 설정 조절
                            VStack(spacing: 15) {
                                // 배경 제거 옵션
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
                                .onChange(of: viewModel.removeBackground) { oldValue, newValue in
                                    // 배경 제거 옵션이 변경되면 GIF 재생성
                                    viewModel.createGIF()
                                }

                                Divider()

                                // 프레임 속도
                                HStack {
                                    Text("gif.frame_speed".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(String(format: "%.1f", viewModel.frameDelay))" + "gif.seconds".localized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Slider(value: $viewModel.frameDelay, in: 0.1...1.0, step: 0.1)
                                    .onChange(of: viewModel.frameDelay) { oldValue, newValue in
                                        // 속도가 변경되면 GIF 재생성
                                        viewModel.createGIF()
                                    }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)

                            // 액션 버튼
                            HStack(spacing: 15) {
                                Button(action: {
                                    viewModel.saveGIF()
                                    showingSaveAlert = true
                                }) {
                                    Label("button.save".localized, systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)

                                Button(action: {
                                    viewModel.reset()
                                }) {
                                    Label("button.recreate".localized, systemImage: "arrow.clockwise")
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
                        Text("gif.processing".localized)
                            .font(.headline)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        if isLandscape {
                            HStack(alignment: .top, spacing: 15) {
                                // 왼쪽: 사진 선택 버튼 (작게)
                                PhotosPicker(
                                    selection: $viewModel.selectedItems,
                                    maxSelectionCount: 10,
                                    matching: .images
                                ) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.stack")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.tint)

                                        Text("button.select_photo".localized)
                                            .font(.subheadline)

                                        Text("\(viewModel.images.count)/10")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 120, height: 120)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                // 중앙: 나머지 콘텐츠 (넓게)
                                landscapeContent
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        } else {
                            VStack(spacing: 20) {
                                // 세로 모드: 사진 선택
                                PhotosPicker(
                                    selection: $viewModel.selectedItems,
                                    maxSelectionCount: 10,
                                    matching: .images
                                ) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.stack")
                                            .font(.system(size: 50))
                                            .foregroundStyle(.tint)

                                        Text(String(format: "gif.select_photos".localized, viewModel.images.count))
                                            .font(.headline)

                                        Text("gif.select_multiple".localized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                }
                                .padding(.horizontal)

                                portraitContent
                            }
                        }
                    }
                    .padding(.vertical)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .navigationTitle("gif.title".localized)
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
        .onChange(of: viewModel.selectedItems) { oldValue, newValue in
            Task {
                await viewModel.loadImages()
            }
        }
    }

    @ViewBuilder
    var landscapeContent: some View {
        if !viewModel.images.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                // 선택된 이미지 그리드
                VStack(alignment: .leading, spacing: 10) {
                    Text("gif.selected_photos".localized)
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(viewModel.images.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button(action: {
                                        viewModel.removeImage(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }

                // 설정과 버튼을 가로로 배치
                HStack(spacing: 15) {
                    // 설정 패널 (최대한 넓게)
                    HStack(spacing: 20) {
                        // 배경 제거 옵션
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

                        Divider()
                            .frame(height: 30)

                        // 프레임 속도
                        VStack(spacing: 5) {
                            HStack {
                                Text("gif.frame_speed".localized)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(String(format: "%.1f", viewModel.frameDelay))초")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $viewModel.frameDelay, in: 0.1...1.0, step: 0.1)
                        }
                        .frame(maxWidth: 250)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // GIF 생성 버튼 (오른쪽 끝)
                    Button(action: {
                        viewModel.createGIF()
                    }) {
                        Label("gif.create".localized, systemImage: "sparkles")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    @ViewBuilder
    var portraitContent: some View {
        // 선택된 이미지 그리드
        if !viewModel.images.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("gif.selected_photos".localized)
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.images.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(action: {
                                    viewModel.removeImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.red))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // GIF 설정
            VStack(spacing: 15) {
                // 배경 제거 옵션
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

                Divider()

                // 프레임 속도
                HStack {
                    Text("프레임 속도")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.1f", viewModel.frameDelay))초")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $viewModel.frameDelay, in: 0.1...1.0, step: 0.1)
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
    }
}

struct GIFPreviewView: View {
    let url: URL
    let frameDelay: Double

    var body: some View {
        if let data = try? Data(contentsOf: url),
           let source = CGImageSourceCreateWithData(data as CFData, nil) {
            AnimatedGIFView(source: source, frameDelay: frameDelay)
        } else {
            Text("GIF 미리보기 실패")
                .foregroundStyle(.secondary)
        }
    }
}

struct AnimatedGIFView: View {
    let source: CGImageSource
    let frameDelay: Double
    @State private var currentFrame = 0
    @State private var timer: Timer?

    var frameCount: Int {
        CGImageSourceGetCount(source)
    }

    var body: some View {
        Group {
            if frameCount > 0,
               let cgImage = CGImageSourceCreateImageAtIndex(source, currentFrame, nil) {
                Image(uiImage: UIImage(cgImage: cgImage))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: frameDelay) { oldValue, newValue in
            restartAnimation()
        }
    }

    private func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: frameDelay, repeats: true) { _ in
            currentFrame = (currentFrame + 1) % frameCount
        }
    }

    private func restartAnimation() {
        startAnimation()
    }
}

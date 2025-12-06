//
//  BackgroundCompositor.swift
//  stickermaker
//
//  Created by jihong on 12/6/25.
//

import SwiftUI
import PhotosUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import Combine

@MainActor
class BackgroundCompositorViewModel: ObservableObject {
    @Published var selectedPersonItem: PhotosPickerItem?
    @Published var selectedBackgroundItem: PhotosPickerItem?
    @Published var personImage: UIImage?
    @Published var backgroundImage: UIImage?
    @Published var personWithoutBg: UIImage?
    @Published var composedImage: UIImage?
    @Published var isProcessing = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var personScale: Double = 1.0
    @Published var personOffsetXPercent: Double = 0.0  // -50% ~ 50%
    @Published var personOffsetYPercent: Double = 0.0  // -50% ~ 50%

    func loadPersonImage() async {
        guard let item = selectedPersonItem else { return }

        isProcessing = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "이미지를 불러올 수 없습니다."
                isProcessing = false
                return
            }

            personImage = image

            // 배경 제거
            let processed = try await removeBackground(from: image)
            personWithoutBg = processed

            // 배경 이미지가 있으면 자동으로 합성
            if backgroundImage != nil {
                composeImages()
            }
        } catch {
            errorMessage = "사람 이미지 로드 실패: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func loadBackgroundImage() async {
        guard let item = selectedBackgroundItem else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "배경 이미지를 불러올 수 없습니다."
                return
            }

            backgroundImage = image

            // 사람 이미지가 있으면 자동으로 합성
            if personWithoutBg != nil {
                composeImages()
            }
        } catch {
            errorMessage = "배경 이미지 로드 실패: \(error.localizedDescription)"
        }
    }

    private func removeBackground(from image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNInstanceMaskObservation else {
                    continuation.resume(throwing: NSError(domain: "BackgroundCompositor", code: 2, userInfo: [NSLocalizedDescriptionKey: "마스크 생성 실패"]))
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
                continuation.resume(throwing: NSError(domain: "BackgroundCompositor", code: 1, userInfo: [NSLocalizedDescriptionKey: "CGImage 변환 실패"]))
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
            throw NSError(domain: "BackgroundCompositor", code: 1, userInfo: [NSLocalizedDescriptionKey: "CGImage 변환 실패"])
        }

        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: VNImageRequestHandler(cgImage: cgImage))

        let ciImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = CIImage.empty()
        filter.maskImage = maskCIImage

        guard let outputImage = filter.outputImage else {
            throw NSError(domain: "BackgroundCompositor", code: 3, userInfo: [NSLocalizedDescriptionKey: "필터 적용 실패"])
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw NSError(domain: "BackgroundCompositor", code: 4, userInfo: [NSLocalizedDescriptionKey: "이미지 생성 실패"])
        }

        return UIImage(cgImage: outputCGImage)
    }

    func composeImages() {
        guard let person = personWithoutBg,
              let background = backgroundImage else { return }

        let backgroundSize = background.size
        let personSize = person.size

        // 스케일 적용된 사람 이미지 크기
        let scaledPersonSize = CGSize(
            width: personSize.width * personScale,
            height: personSize.height * personScale
        )

        // 사람 이미지 위치 (중앙 + 퍼센트 기반 오프셋)
        let offsetX = backgroundSize.width * (personOffsetXPercent / 100.0)
        let offsetY = backgroundSize.height * (personOffsetYPercent / 100.0)
        let personX = (backgroundSize.width - scaledPersonSize.width) / 2 + offsetX
        let personY = (backgroundSize.height - scaledPersonSize.height) / 2 + offsetY

        let renderer = UIGraphicsImageRenderer(size: backgroundSize)
        let composed = renderer.image { context in
            // 배경 그리기
            background.draw(in: CGRect(origin: .zero, size: backgroundSize))

            // 사람 이미지 그리기
            person.draw(in: CGRect(x: personX, y: personY, width: scaledPersonSize.width, height: scaledPersonSize.height))
        }

        composedImage = composed
    }

    func saveComposedImage() async {
        guard let image = composedImage else {
            errorMessage = "저장할 이미지가 없습니다."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
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
        selectedPersonItem = nil
        selectedBackgroundItem = nil
        personImage = nil
        backgroundImage = nil
        personWithoutBg = nil
        composedImage = nil
        personScale = 1.0
        personOffsetXPercent = 0.0
        personOffsetYPercent = 0.0
        errorMessage = nil
    }
}

struct BackgroundCompositorView: View {
    @StateObject private var viewModel = BackgroundCompositorViewModel()
    @State private var showSaveAlert = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("배경 합성")
                .navigationBarTitleDisplayMode(.inline)
                .alert("저장 완료", isPresented: $showSaveAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("합성된 이미지가 사진 라이브러리에 저장되었습니다.")
                }
        }
        .onChange(of: viewModel.selectedPersonItem) { _, _ in
            Task {
                await viewModel.loadPersonImage()
            }
        }
        .onChange(of: viewModel.selectedBackgroundItem) { _, _ in
            Task {
                await viewModel.loadBackgroundImage()
            }
        }
    }

    @ViewBuilder
    var content: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let composedImage = viewModel.composedImage {
                        // 합성된 이미지 미리보기
                        CardView {
                            Image(uiImage: composedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .padding(Spacing.md)
                        }
                        .padding(.horizontal, Spacing.md)

                        // 조정 컨트롤
                        CardView {
                            VStack(spacing: Spacing.md) {
                                CustomSlider(
                                    title: "사람 크기",
                                    value: $viewModel.personScale,
                                    range: 0.3...2.0,
                                    step: 0.1,
                                    unit: "배"
                                )
                                .onChange(of: viewModel.personScale) { _, _ in
                                    viewModel.composeImages()
                                }

                                CustomSlider(
                                    title: "가로 위치",
                                    value: $viewModel.personOffsetXPercent,
                                    range: -50...50,
                                    step: 1,
                                    unit: "%"
                                )
                                .onChange(of: viewModel.personOffsetXPercent) { _, _ in
                                    viewModel.composeImages()
                                }

                                CustomSlider(
                                    title: "세로 위치",
                                    value: $viewModel.personOffsetYPercent,
                                    range: -50...50,
                                    step: 1,
                                    unit: "%"
                                )
                                .onChange(of: viewModel.personOffsetYPercent) { _, _ in
                                    viewModel.composeImages()
                                }
                            }
                            .padding(Spacing.md)
                        }
                        .padding(.horizontal, Spacing.md)

                        // 액션 버튼
                        VStack(spacing: Spacing.md) {
                            Button(action: {
                                Task {
                                    await viewModel.saveComposedImage()
                                    if viewModel.errorMessage == nil {
                                        showSaveAlert = true
                                    }
                                }
                            }) {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("저장")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(viewModel.isSaving)

                            Button(action: {
                                viewModel.reset()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("다시 만들기")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.horizontal, Spacing.md)
                    } else {
                        // 이미지 선택 화면
                        EmptyStateView(
                            icon: "photo.stack",
                            title: "배경 합성",
                            message: "사람 사진과 배경 사진을\n선택하여 합성하세요"
                        )

                        VStack(spacing: Spacing.md) {
                            // 사람 이미지 선택
                            VStack(spacing: Spacing.sm) {
                                Text("1. 사람 사진 선택")
                                    .font(.appSubheadline)
                                    .foregroundColor(.secondary)

                                PhotosPicker(
                                    selection: $viewModel.selectedPersonItem,
                                    matching: .images
                                ) {
                                    HStack {
                                        Image(systemName: viewModel.personWithoutBg != nil ? "checkmark.circle.fill" : "person.crop.circle")
                                        Text(viewModel.personWithoutBg != nil ? "사람 선택됨" : "사람 선택")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            // 배경 이미지 선택
                            VStack(spacing: Spacing.sm) {
                                Text("2. 배경 사진 선택")
                                    .font(.appSubheadline)
                                    .foregroundColor(.secondary)

                                PhotosPicker(
                                    selection: $viewModel.selectedBackgroundItem,
                                    matching: .images
                                ) {
                                    HStack {
                                        Image(systemName: viewModel.backgroundImage != nil ? "checkmark.circle.fill" : "photo")
                                        Text(viewModel.backgroundImage != nil ? "배경 선택됨" : "배경 선택")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                        .padding(.horizontal, Spacing.lg)

                        if viewModel.isProcessing {
                            VStack(spacing: Spacing.md) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color.appPrimary)
                                Text("배경 제거 중...")
                                    .font(.appBody)
                                    .foregroundColor(.secondary)
                            }
                            .padding(Spacing.xl)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.appCaption)
                            .foregroundColor(.red)
                            .padding(Spacing.md)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.vertical, Spacing.md)
            }
    }
}

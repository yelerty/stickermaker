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

    private let imageProcessingService = ImageProcessingService.shared

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

            // 메모리 절약을 위해 이미지 리사이즈 (최대 2000px)
            let resizedImage = imageProcessingService.resizeImage(image, maxDimension: 2000)
            personImage = resizedImage

            // 배경 제거
            let processed = try await imageProcessingService.removeBackground(from: resizedImage)
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

            // 메모리 절약을 위해 이미지 리사이즈 (최대 2000px)
            let resizedImage = imageProcessingService.resizeImage(image, maxDimension: 2000)
            backgroundImage = resizedImage

            // 사람 이미지가 있으면 자동으로 합성
            if personWithoutBg != nil {
                composeImages()
            }
        } catch {
            errorMessage = "배경 이미지 로드 실패: \(error.localizedDescription)"
        }
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

        // 메모리 효율적인 렌더링
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // 스케일을 1.0으로 고정하여 메모리 절약
        format.opaque = true  // 불투명 배경으로 설정하여 메모리 절약

        let renderer = UIGraphicsImageRenderer(size: backgroundSize, format: format)
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
            // JPEG로 저장 (메모리 절약, 품질 0.9)
            guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
                errorMessage = "이미지 변환 실패"
                isSaving = false
                return
            }

            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: jpegData, options: nil)
            }

            // 저장 후 메모리 해제
            await MainActor.run {
                // 저장 완료 후에도 composedImage는 유지 (UI에서 보여주기 위해)
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
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                ScrollView {
                    if let composedImage = viewModel.composedImage {
                        if isLandscape {
                            landscapeComposedView(image: composedImage, geometry: geometry)
                        } else {
                            portraitComposedView(image: composedImage)
                        }
                    } else {
                        if isLandscape {
                            landscapeEmptyView(geometry: geometry)
                        } else {
                            portraitEmptyView
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
            .navigationTitle("compositor.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ThemeToggleButton()
                }
            }
            .alert("message.saved".localized, isPresented: $showSaveAlert) {
                Button("button.ok".localized, role: .cancel) { }
            } message: {
                Text("compositor.saved.message".localized)
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

    func landscapeComposedView(image: UIImage, geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // 왼쪽: 이미지 미리보기 (40%)
            CardView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(Spacing.md)
            }
            .frame(width: geometry.size.width * 0.35)
            .padding(.leading, Spacing.md)

            // 오른쪽: 컨트롤 패널 (60%)
            VStack(spacing: Spacing.lg) {
                CardView {
                    VStack(spacing: Spacing.md) {
                        CustomSlider(
                            title: "compositor.person_size".localized,
                            value: $viewModel.personScale,
                            range: 0.3...2.0,
                            step: 0.1,
                            unit: "배"
                        )
                        .onChange(of: viewModel.personScale) { _, _ in
                            viewModel.composeImages()
                        }

                        CustomSlider(
                            title: "compositor.horizontal_position".localized,
                            value: $viewModel.personOffsetXPercent,
                            range: -50...50,
                            step: 1,
                            unit: "%"
                        )
                        .onChange(of: viewModel.personOffsetXPercent) { _, _ in
                            viewModel.composeImages()
                        }

                        CustomSlider(
                            title: "compositor.vertical_position".localized,
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
                                Text("button.save".localized)
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
                            Text("button.recreate".localized)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .frame(width: geometry.size.width * 0.55)
            .padding(.trailing, Spacing.md)
        }
    }

    func portraitComposedView(image: UIImage) -> some View {
        VStack(spacing: Spacing.lg) {
            // 합성된 이미지 미리보기
            CardView {
                Image(uiImage: image)
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
        }
    }

    func landscapeEmptyView(geometry: GeometryProxy) -> some View {
        let hasPersonImage = viewModel.personWithoutBg != nil
        let hasBackgroundImage = viewModel.backgroundImage != nil
        let isProcessing = viewModel.isProcessing

        return HStack(alignment: .top, spacing: Spacing.lg) {
            // 왼쪽: Empty State (40%)
            VStack {
                EmptyStateView(
                    icon: "photo.stack",
                    title: "compositor.title".localized,
                    message: "compositor.empty.message".localized
                )

                if isProcessing {
                    VStack(spacing: Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.appPrimary)
                        Text("compositor.processing".localized)
                            .font(.appBody)
                            .foregroundColor(.secondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .frame(width: geometry.size.width * 0.35)
            .padding(.leading, Spacing.md)

            // 오른쪽: 선택 버튼 (60%)
            VStack(spacing: Spacing.md) {
                // 사람 이미지 선택
                VStack(spacing: Spacing.sm) {
                    Text("compositor.step1".localized)
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(
                        selection: $viewModel.selectedPersonItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: hasPersonImage ? "checkmark.circle.fill" : "person.crop.circle")
                            Text(hasPersonImage ? "사람 선택됨" : "사람 선택")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                // 배경 이미지 선택
                VStack(spacing: Spacing.sm) {
                    Text("compositor.step2".localized)
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(
                        selection: $viewModel.selectedBackgroundItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: hasBackgroundImage ? "checkmark.circle.fill" : "photo")
                            Text(hasBackgroundImage ? "배경 선택됨" : "배경 선택")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .frame(width: geometry.size.width * 0.55)
            .padding(.trailing, Spacing.md)
        }
    }

    var portraitEmptyView: some View {
        let hasPersonImage = viewModel.personWithoutBg != nil
        let hasBackgroundImage = viewModel.backgroundImage != nil
        let isProcessing = viewModel.isProcessing

        return VStack(spacing: Spacing.lg) {
            // 이미지 선택 화면
            EmptyStateView(
                icon: "photo.stack",
                title: "배경 합성",
                message: "사람 사진과 배경 사진을\n선택하여 합성하세요"
            )

            VStack(spacing: Spacing.md) {
                // 사람 이미지 선택
                VStack(spacing: Spacing.sm) {
                    Text("compositor.step1".localized)
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(
                        selection: $viewModel.selectedPersonItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: hasPersonImage ? "checkmark.circle.fill" : "person.crop.circle")
                            Text(hasPersonImage ? "사람 선택됨" : "사람 선택")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                // 배경 이미지 선택
                VStack(spacing: Spacing.sm) {
                    Text("compositor.step2".localized)
                        .font(.appSubheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(
                        selection: $viewModel.selectedBackgroundItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: hasBackgroundImage ? "checkmark.circle.fill" : "photo")
                            Text(hasBackgroundImage ? "배경 선택됨" : "배경 선택")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)

            if isProcessing {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.appPrimary)
                    Text("compositor.processing".localized)
                        .font(.appBody)
                        .foregroundColor(.secondary)
                }
                .padding(Spacing.xl)
            }
        }
    }
}

//
//  ImprovedContentView.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI

struct ImprovedStickerMakerTab: View {
    @StateObject private var viewModel = StickerViewModel()
    @State private var showSaveAlert = false
    @State private var showingEditor = false
    @State private var isLandscape = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    if let processedImage = viewModel.processedImage {
                        if isLandscape {
                            landscapePreview(image: processedImage, geometry: geometry)
                        } else {
                            portraitPreview(image: processedImage)
                        }
                    } else if viewModel.isProcessing {
                        processingView
                    } else {
                        if isLandscape {
                            landscapeEmptyStateView
                        } else {
                            emptyStateView
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: geometry.size) { oldValue, newValue in
                    isLandscape = newValue.width > newValue.height
                }
                .onAppear {
                    isLandscape = geometry.size.width > geometry.size.height
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("sticker.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ThemeToggleButton()
                }
            }
            .alert("sticker.saved".localized, isPresented: $showSaveAlert) {
                Button("button.ok".localized, role: .cancel) { }
            } message: {
                Text("sticker.saved.message".localized)
            }
            .sheet(isPresented: $showingEditor) {
                ImageEditorView(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
            Task {
                await viewModel.loadImage()
            }
        }
        .onChange(of: viewModel.selectedVideoItem) { oldValue, newValue in
            Task {
                await viewModel.loadVideo()
            }
        }
        .sheet(isPresented: $viewModel.showVideoCapture) {
            VideoCaptureView(viewModel: viewModel)
        }
    }

    func portraitPreview(image: UIImage) -> some View {
        VStack(spacing: Spacing.lg) {
            CardView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .background(CheckerboardView())
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .padding(Spacing.md)
            }
            .padding(.horizontal, Spacing.md)

            optionControls
                .padding(.horizontal, Spacing.md)

            actionButtons
                .padding(.horizontal, Spacing.md)

            if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            }
        }
        .padding(.vertical, Spacing.md)
    }

    func landscapePreview(image: UIImage, geometry: GeometryProxy) -> some View {
        HStack(spacing: Spacing.lg) {
            // 왼쪽: 이미지 미리보기
            CardView {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(CheckerboardView())
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .padding(Spacing.md)
            }
            .frame(width: geometry.size.width * 0.55)

            // 오른쪽: 옵션 및 액션 버튼들
            VStack(spacing: Spacing.lg) {
                Spacer()
                optionControls
                actionButtons
                Spacer()

                if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                }
            }
            .frame(width: geometry.size.width * 0.40)
        }
        .padding(Spacing.lg)
    }

    var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            Button(action: {
                showingEditor = true
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("button.edit".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())

            HStack(spacing: Spacing.md) {
                Button(action: {
                    Task {
                        await viewModel.saveSticker()
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
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(width: 50)
            }
        }
    }

    var optionControls: some View {
        CardView {
            VStack(spacing: Spacing.md) {
                // 배경 제거 토글
                Toggle(isOn: $viewModel.removeBackgroundEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "scissors")
                            .foregroundStyle(.tint)
                        Text("option.remove_background".localized)
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: viewModel.removeBackgroundEnabled) { _, _ in
                    Task {
                        if viewModel.selectedImage != nil {
                            await viewModel.loadImage()
                        }
                    }
                }

                Divider()

                // 프레임 비율
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "aspectratio")
                            .foregroundStyle(.tint)
                        Text("option.aspect_ratio".localized)
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                    }

                    Picker("option.aspect_ratio".localized, selection: $viewModel.aspectRatio) {
                        ForEach(AspectRatio.allCases) { ratio in
                            Text(ratio.localizedName).tag(ratio)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                    .onChange(of: viewModel.aspectRatio) { _, _ in
                        Task {
                            if viewModel.selectedImage != nil {
                                await viewModel.loadImage()
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
        }
    }

    var processingView: some View {
        VStack(spacing: Spacing.xl) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.appPrimary)

            Text("sticker.processing".localized)
                .font(.appHeadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
        .padding(Spacing.xxl)
    }

    var landscapeEmptyStateView: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: Spacing.lg) {
                // 왼쪽: Empty State (40%)
                VStack {
                    EmptyStateView(
                        icon: "photo.badge.plus",
                        title: "sticker.empty.title".localized,
                        message: "sticker.empty.message".localized
                    )

                    if viewModel.isProcessing {
                        VStack(spacing: Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color.appPrimary)
                            Text("sticker.processing".localized)
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
                    // 사진 선택
                    VStack(spacing: Spacing.sm) {
                        Text("sticker.step.photo".localized)
                            .font(.appSubheadline)
                            .foregroundColor(.secondary)

                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("button.select_photo".localized)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    // 비디오 선택
                    VStack(spacing: Spacing.sm) {
                        Text("sticker.step.video".localized)
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
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .frame(width: geometry.size.width * 0.55)
                .padding(.trailing, Spacing.md)
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            EmptyStateView(
                icon: "photo.badge.plus",
                title: "sticker.empty.title".localized,
                message: "sticker.empty.message".localized
            )

            VStack(spacing: Spacing.md) {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("button.select_photo".localized)
                    }
                    .frame(maxWidth: 300)
                }
                .buttonStyle(PrimaryButtonStyle())
                .controlSize(.large)

                PhotosPicker(
                    selection: $viewModel.selectedVideoItem,
                    matching: .videos
                ) {
                    HStack {
                        Image(systemName: "video.badge.plus")
                        Text("button.select_video".localized)
                    }
                    .frame(maxWidth: 300)
                }
                .buttonStyle(SecondaryButtonStyle())
                .controlSize(.large)
            }
        }
        .padding(Spacing.xxl)
    }

    func errorView(_ message: String) -> some View {
        Text(message)
            .font(.appCaption)
            .foregroundColor(.red)
            .padding(Spacing.md)
            .background(Color.red.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
    }
}

struct EnhancedStickerPreviewView: View {
    let image: UIImage

    var body: some View {
        CardView {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .background(CheckerboardView())
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .padding(Spacing.md)
        }
    }
}

struct VideoCaptureView: View {
    @ObservedObject var viewModel: StickerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if let image = viewModel.selectedImage {
                    CardView {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .background(CheckerboardView())
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .padding(Spacing.md)
                    }
                    .padding(.horizontal, Spacing.md)
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("프레임 선택")
                        .font(.appHeadline)
                        .padding(.horizontal, Spacing.md)

                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text(formatTime(0))
                                .font(.appCaption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatTime(viewModel.selectedTime))
                                .font(.appSubheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.appPrimary)

                            Spacer()

                            Text(formatTime(viewModel.videoDuration))
                                .font(.appCaption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, Spacing.md)

                        Slider(value: $viewModel.selectedTime, in: 0...viewModel.videoDuration)
                            .tint(Color.appPrimary)
                            .padding(.horizontal, Spacing.md)
                            .onChange(of: viewModel.selectedTime) { oldValue, newValue in
                                Task {
                                    await viewModel.captureVideoFrame()
                                }
                            }
                    }
                }

                Button(action: {
                    viewModel.showVideoCapture = false
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("이 프레임으로 스티커 만들기")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.md)

                Spacer()
            }
            .padding(.vertical, Spacing.md)
            .navigationTitle("비디오 프레임 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        viewModel.reset()
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, secs, millis)
    }
}

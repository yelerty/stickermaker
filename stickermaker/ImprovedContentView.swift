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
                        emptyStateView
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
            .navigationTitle("Sticker Maker")
            .navigationBarTitleDisplayMode(isLandscape ? .inline : .large)
            .alert("저장 완료", isPresented: $showSaveAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("스티커가 사진 라이브러리에 저장되었습니다.")
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
                    Text("편집하기")
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
                        Text("배경 제거")
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
                        Text("프레임 비율")
                            .font(.appSubheadline)
                            .fontWeight(.medium)
                    }

                    Picker("프레임 비율", selection: $viewModel.aspectRatio) {
                        ForEach(AspectRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
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

            Text("배경 제거 중...")
                .font(.appHeadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
        .padding(Spacing.xxl)
    }

    var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            EmptyStateView(
                icon: "photo.badge.plus",
                title: "스티커 만들기",
                message: "사진 또는 비디오를 선택하여\n스티커를 만드세요"
            )

            VStack(spacing: Spacing.md) {
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("사진 선택")
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
                        Text("비디오 선택")
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

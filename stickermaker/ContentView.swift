//
//  ContentView.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView(selection: $selectedTab) {
            ImprovedStickerMakerTab()
                .tabItem {
                    Label("tab.sticker".localized, systemImage: "photo.badge.plus")
                }
                .tag(0)

            GIFMakerView()
                .tabItem {
                    Label("tab.photo_gif".localized, systemImage: "photo.stack")
                }
                .tag(1)

            VideoToGIFView()
                .tabItem {
                    Label("tab.video_gif".localized, systemImage: "video.badge.waveform")
                }
                .tag(2)

            BackgroundCompositorView()
                .tabItem {
                    Label("tab.background".localized, systemImage: "rectangle.on.rectangle")
                }
                .tag(3)

            StickerPackView()
                .tabItem {
                    Label("tab.sticker_pack".localized, systemImage: "square.grid.3x3")
                }
                .tag(4)
        }
        .environmentObject(themeManager)
    }
}

struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showThemeMenu = false

    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            Image(systemName: themeManager.currentTheme.icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.appCardBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct StickerMakerTab: View {
    @StateObject private var viewModel = StickerViewModel()
    @State private var showSaveAlert = false
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let processedImage = viewModel.processedImage {
                    // 처리된 스티커 미리보기
                    StickerPreviewView(image: processedImage)

                    // 액션 버튼들
                    VStack(spacing: 12) {
                        Button(action: {
                            showingEditor = true
                        }) {
                            Label("편집하기", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        HStack(spacing: 15) {
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
                                    Label("저장", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isSaving)

                            Button(action: {
                                viewModel.reset()
                            }) {
                                Label("다시 선택", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                } else if viewModel.isProcessing {
                    // 로딩 상태
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("배경 제거 중...")
                            .font(.headline)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // 초기 상태 - 사진 선택
                    VStack(spacing: 30) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)

                        VStack(spacing: 10) {
                            Text("스티커 만들기")
                                .font(.title)
                                .bold()

                            Text("사진을 선택하면 자동으로\n배경이 제거됩니다")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images
                        ) {
                            Label("사진 선택", systemImage: "photo.on.rectangle")
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
            .navigationTitle("Sticker Maker")
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
    }
}

struct StickerPreviewView: View {
    let image: UIImage

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .background(
                    // 체크무늬 배경으로 투명도 확인
                    CheckerboardView()
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .padding()
        }
    }
}

struct CheckerboardView: View {
    let squareSize: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / squareSize) + 1
            let rows = Int(geometry.size.height / squareSize) + 1

            Canvas { context, size in
                for row in 0..<rows {
                    for column in 0..<columns {
                        let isEvenRow = row % 2 == 0
                        let isEvenColumn = column % 2 == 0
                        let shouldFill = isEvenRow == isEvenColumn

                        if shouldFill {
                            let rect = CGRect(
                                x: CGFloat(column) * squareSize,
                                y: CGFloat(row) * squareSize,
                                width: squareSize,
                                height: squareSize
                            )
                            context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

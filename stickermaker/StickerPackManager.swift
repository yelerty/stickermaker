//
//  StickerPackManager.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine
import PhotosUI

class StickerPackManager: ObservableObject {
    @Published var stickers: [StickerItem] = []
    @Published var packName: String = "내 스티커팩"

    func addSticker(_ image: UIImage) {
        let sticker = StickerItem(image: image)
        stickers.append(sticker)
        saveStickers()
    }

    func removeSticker(_ id: UUID) {
        stickers.removeAll { $0.id == id }
        saveStickers()
    }

    func exportStickerPack() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let packDir = tempDir.appendingPathComponent(packName)

        do {
            if FileManager.default.fileExists(atPath: packDir.path) {
                try FileManager.default.removeItem(at: packDir)
            }
            try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

            for (index, sticker) in stickers.enumerated() {
                let fileName = "sticker_\(index).png"
                let fileURL = packDir.appendingPathComponent(fileName)

                if let data = sticker.image.pngData() {
                    try data.write(to: fileURL)
                }
            }

            return packDir
        } catch {
            print("스티커팩 내보내기 실패: \(error)")
            return nil
        }
    }

    private func saveStickers() {
        // UserDefaults나 파일로 저장 (간단한 구현)
    }
}

struct StickerItem: Identifiable {
    let id = UUID()
    let image: UIImage
    var name: String = ""
}

struct StickerPackView: View {
    @StateObject private var manager = StickerPackManager()
    @State private var showingImagePicker = false
    @State private var showingExportSheet = false
    @EnvironmentObject var themeManager: ThemeManager
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 스티커팩 이름
                TextField("스티커팩 이름", text: $manager.packName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // 스티커 그리드
                if manager.stickers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)

                        Text("스티커를 추가해보세요")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(manager.stickers) { sticker in
                                StickerCardView(sticker: sticker) {
                                    manager.removeSticker(sticker.id)
                                }
                            }
                        }
                        .padding()
                    }

                    // 내보내기 버튼
                    Button(action: {
                        if let url = manager.exportStickerPack() {
                            exportURL = url
                            showingExportSheet = true
                        }
                    }) {
                        Label("스티커팩 공유", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("스티커팩 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ThemeToggleButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                StickerPickerView { image in
                    manager.addSticker(image)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

struct StickerCardView: View {
    let sticker: StickerItem
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Image(uiImage: sticker.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(CheckerboardView())
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 8, y: -8)
        }
    }
}

struct StickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StickerViewModel()
    let onStickerCreated: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                if let processedImage = viewModel.processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .background(CheckerboardView())
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding()

                    Button("스티커로 추가") {
                        onStickerCreated(processedImage)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                } else if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images
                    ) {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 60))
                            Text("사진 선택")
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("스티커 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
            Task {
                await viewModel.loadImage()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

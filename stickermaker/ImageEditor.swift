//
//  ImageEditor.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImageEditorView: View {
    @ObservedObject var viewModel: StickerViewModel
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 1.0
    @State private var selectedFilter: FilterType = .none
    @State private var showingTextEditor = false
    @State private var textOverlays: [TextOverlay] = []

    var body: some View {
        VStack(spacing: 0) {
            // 이미지 프리뷰
            if let image = viewModel.processedImage {
                ZStack {
                    CheckerboardView()

                    Image(uiImage: applyEdits(to: image))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .rotationEffect(rotation)
                        .overlay {
                            ForEach(textOverlays) { overlay in
                                Text(overlay.text)
                                    .font(.system(size: overlay.fontSize))
                                    .foregroundColor(overlay.color)
                                    .position(overlay.position)
                            }
                        }
                }
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
            }

            // 편집 컨트롤
            ScrollView {
                VStack(spacing: 20) {
                    // 크기 및 회전
                    GroupBox("editor.size_rotation".localized) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("editor.size".localized)
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $scale, in: 0.5...2.0)
                                Text("\(Int(scale * 100))%")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("editor.rotation".localized)
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: Binding(
                                    get: { rotation.degrees },
                                    set: { rotation = .degrees($0) }
                                ), in: -180...180)
                                Text("\(Int(rotation.degrees))°")
                                    .frame(width: 50)
                            }
                        }
                        .padding(.vertical, 5)
                    }

                    // 색상 조정
                    GroupBox("editor.color_adjustment".localized) {
                        VStack(spacing: 15) {
                            HStack {
                                Text("editor.brightness".localized)
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $brightness, in: -0.5...0.5)
                                Text("\(Int(brightness * 100))")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("editor.contrast".localized)
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $contrast, in: 0.5...2.0)
                                Text("\(Int(contrast * 100))%")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("editor.saturation".localized)
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $saturation, in: 0...2.0)
                                Text("\(Int(saturation * 100))%")
                                    .frame(width: 50)
                            }
                        }
                        .padding(.vertical, 5)
                    }

                    // 필터
                    GroupBox("editor.filter".localized) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FilterType.allCases, id: \.self) { filter in
                                    FilterButton(
                                        filter: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }

                    // 텍스트/이모지 추가
                    GroupBox("editor.text_emoji".localized) {
                        Button(action: {
                            showingTextEditor = true
                        }) {
                            Label("editor.add_text".localized, systemImage: "textformat")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    // 액션 버튼
                    HStack(spacing: 12) {
                        Button("button.reset".localized) {
                            resetEdits()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("button.apply".localized) {
                            applyAndSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingTextEditor) {
            TextEditorSheet(textOverlays: $textOverlays)
        }
    }

    private func applyEdits(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        var outputImage = ciImage

        // 밝기 조정
        if brightness != 0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = outputImage
            filter.brightness = Float(brightness)
            outputImage = filter.outputImage ?? outputImage
        }

        // 대비 및 채도 조정
        if contrast != 1.0 || saturation != 1.0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = outputImage
            filter.contrast = Float(contrast)
            filter.saturation = Float(saturation)
            outputImage = filter.outputImage ?? outputImage
        }

        // 필터 적용
        outputImage = applyFilter(selectedFilter, to: outputImage)

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    private func applyFilter(_ filter: FilterType, to image: CIImage) -> CIImage {
        switch filter {
        case .none:
            return image
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = image
            return filter.outputImage ?? image
        case .chrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = image
            return filter.outputImage ?? image
        case .fade:
            let filter = CIFilter.photoEffectFade()
            filter.inputImage = image
            return filter.outputImage ?? image
        case .instant:
            let filter = CIFilter.photoEffectInstant()
            filter.inputImage = image
            return filter.outputImage ?? image
        case .mono:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = image
            return filter.outputImage ?? image
        case .tonal:
            let filter = CIFilter.photoEffectTonal()
            filter.inputImage = image
            return filter.outputImage ?? image
        }
    }

    private func resetEdits() {
        scale = 1.0
        rotation = .zero
        brightness = 0
        contrast = 1.0
        saturation = 1.0
        selectedFilter = .none
        textOverlays.removeAll()
    }

    private func applyAndSave() {
        guard let originalImage = viewModel.processedImage else { return }

        // 모든 편집 적용
        let editedImage = applyEdits(to: originalImage)

        // 크기와 회전 적용
        let finalImage = applyTransformations(to: editedImage)

        viewModel.processedImage = finalImage
    }

    private func applyTransformations(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: image.size)
            context.cgContext.translateBy(x: image.size.width / 2, y: image.size.height / 2)
            context.cgContext.rotate(by: CGFloat(rotation.radians))
            context.cgContext.scaleBy(x: scale, y: scale)
            context.cgContext.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            image.draw(in: rect)
        }
    }
}

enum FilterType: String, CaseIterable {
    case none
    case noir
    case chrome
    case fade
    case instant
    case mono
    case tonal

    var localizedName: String {
        switch self {
        case .none: return "filter.none".localized
        case .noir: return "filter.noir".localized
        case .chrome: return "filter.chrome".localized
        case .fade: return "filter.fade".localized
        case .instant: return "filter.instant".localized
        case .mono: return "filter.mono".localized
        case .tonal: return "filter.tonal".localized
        }
    }
}

struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(filter.localizedName.prefix(1))
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                Text(filter.localizedName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var color: Color
}

struct TextEditorSheet: View {
    @Binding var textOverlays: [TextOverlay]
    @State private var inputText = ""
    @State private var selectedColor: Color = .white
    @State private var fontSize: CGFloat = 30
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("editor.text".localized) {
                    TextField("editor.text_input".localized, text: $inputText)
                }

                Section("editor.text_size".localized) {
                    Slider(value: $fontSize, in: 20...80) {
                        Text("editor.text_size".localized)
                    }
                    Text("editor.text_size".localized + ": \(Int(fontSize))")
                        .font(.system(size: fontSize))
                }

                Section("editor.color".localized) {
                    ColorPicker("editor.color_select".localized, selection: $selectedColor)
                }
            }
            .navigationTitle("editor.add_text".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.add".localized) {
                        if !inputText.isEmpty {
                            textOverlays.append(TextOverlay(
                                text: inputText,
                                position: CGPoint(x: 200, y: 200),
                                fontSize: fontSize,
                                color: selectedColor
                            ))
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

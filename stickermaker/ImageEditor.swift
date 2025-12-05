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
                    GroupBox("크기 & 회전") {
                        VStack(spacing: 15) {
                            HStack {
                                Text("크기")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $scale, in: 0.5...2.0)
                                Text("\(Int(scale * 100))%")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("회전")
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
                    GroupBox("색상 조정") {
                        VStack(spacing: 15) {
                            HStack {
                                Text("밝기")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $brightness, in: -0.5...0.5)
                                Text("\(Int(brightness * 100))")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("대비")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $contrast, in: 0.5...2.0)
                                Text("\(Int(contrast * 100))%")
                                    .frame(width: 50)
                            }

                            HStack {
                                Text("채도")
                                    .frame(width: 60, alignment: .leading)
                                Slider(value: $saturation, in: 0...2.0)
                                Text("\(Int(saturation * 100))%")
                                    .frame(width: 50)
                            }
                        }
                        .padding(.vertical, 5)
                    }

                    // 필터
                    GroupBox("필터") {
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
                    GroupBox("텍스트 & 이모지") {
                        Button(action: {
                            showingTextEditor = true
                        }) {
                            Label("텍스트 추가", systemImage: "textformat")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    // 액션 버튼
                    HStack(spacing: 12) {
                        Button("초기화") {
                            resetEdits()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("적용") {
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
    case none = "원본"
    case noir = "누아르"
    case chrome = "크롬"
    case fade = "페이드"
    case instant = "인스턴트"
    case mono = "모노"
    case tonal = "토널"
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
                        Text(filter.rawValue.prefix(1))
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                Text(filter.rawValue)
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
                Section("텍스트") {
                    TextField("텍스트 입력", text: $inputText)
                }

                Section("크기") {
                    Slider(value: $fontSize, in: 20...80) {
                        Text("크기")
                    }
                    Text("크기: \(Int(fontSize))")
                        .font(.system(size: fontSize))
                }

                Section("색상") {
                    ColorPicker("색상 선택", selection: $selectedColor)
                }
            }
            .navigationTitle("텍스트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
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

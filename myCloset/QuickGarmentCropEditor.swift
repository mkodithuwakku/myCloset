import SwiftUI
import UIKit

struct QuickGarmentCropEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cropScale = 0.82
    @State private var horizontalPosition = 0.5
    @State private var verticalPosition = 0.5
    @State private var workingImageData: Data

    let imageData: Data
    let onApply: (Data) -> Void

    init(imageData: Data, onApply: @escaping (Data) -> Void) {
        self.imageData = imageData
        self.onApply = onApply
        _workingImageData = State(initialValue: imageData)
    }

    private var image: UIImage? { UIImage(data: workingImageData) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    ZStack {
                        Color.black.opacity(0.92)
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .overlay {
                                    GeometryReader { imageProxy in
                                        let width = imageProxy.size.width * cropScale
                                        let height = imageProxy.size.height * cropScale
                                        let availableX = imageProxy.size.width - width
                                        let availableY = imageProxy.size.height - height
                                        Rectangle()
                                            .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                                            .frame(width: width, height: height)
                                            .position(
                                                x: width / 2 + availableX * horizontalPosition,
                                                y: height / 2 + availableY * verticalPosition
                                            )
                                            .shadow(color: .black, radius: 2)
                                    }
                                }
                                .padding(16)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 10) {
                    Button("Rotate left", systemImage: "rotate.left") {
                        rotate(by: -1)
                    }
                    .accessibilityIdentifier("crop-rotate-left")

                    Button("Rotate right", systemImage: "rotate.right") {
                        rotate(by: 1)
                    }
                    .accessibilityIdentifier("crop-rotate-right")

                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        cropScale = 0.82
                        horizontalPosition = 0.5
                        verticalPosition = 0.5
                        workingImageData = imageData
                    }
                    .accessibilityIdentifier("crop-reset")
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                VStack(spacing: 14) {
                    LabeledContent("Crop size") {
                        Slider(value: $cropScale, in: 0.45...1)
                            .frame(maxWidth: 210)
                    }
                    LabeledContent("Move horizontally") {
                        Slider(value: $horizontalPosition, in: 0...1)
                            .frame(maxWidth: 210)
                    }
                    LabeledContent("Move vertically") {
                        Slider(value: $verticalPosition, in: 0...1)
                            .frame(maxWidth: 210)
                    }
                }
                .font(.subheadline)

                Text("Keep the whole garment inside the dashed box. The app will run background removal again after this crop.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .navigationTitle("Adjust garment crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        guard let cropped = ImageUtilities.croppedImageData(
                            from: workingImageData,
                            scale: cropScale,
                            horizontalPosition: horizontalPosition,
                            verticalPosition: verticalPosition
                        ) else { return }
                        onApply(cropped)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("apply-garment-crop")
                }
            }
        }
    }

    private func rotate(by quarterTurns: Int) {
        workingImageData = ImageUtilities.rotatedImageData(
            from: workingImageData,
            quarterTurns: quarterTurns
        ) ?? workingImageData
    }
}

import SwiftUI


struct ImageCropView: View {
    let sourceImage: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Crop rectangle as fraction of the displayed image (0...1 range)
    @State private var cropOrigin: CGPoint = CGPoint(x: 0.1, y: 0.1)
    @State private var cropSize: CGSize = CGSize(width: 0.8, height: 0.8)
    @State private var isDraggingCrop: Bool = false
    @State private var isResizingCrop: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let imageSize = fitSize(for: sourceImage.size, in: geo.size)

                    ZStack {
                        Color.black

                        // Image
                        Image(uiImage: sourceImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize.width, height: imageSize.height)
                            .scaleEffect(scale)
                            .offset(offset)

                        // Dimmed overlay outside crop
                        cropOverlay(imageSize: imageSize, containerSize: geo.size)

                        // Crop rectangle border
                        cropBorder(imageSize: imageSize, containerSize: geo.size)
                    }
                    .gesture(pinchGesture)
                    .gesture(panGesture)
                    .clipped()
                }

                // Bottom toolbar
                HStack(spacing: 24) {
                    Button("Reset") {
                        withAnimation {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                            cropOrigin = CGPoint(x: 0.1, y: 0.1)
                            cropSize = CGSize(width: 0.8, height: 0.8)
                        }
                    }
                    .foregroundColor(.orange)

                    Spacer()

                    Button("Use Full Image") {
                        onCrop(sourceImage)
                        dismiss()
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    Button("Crop") {
                        let cropped = performCrop()
                        onCrop(cropped)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Crop Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Gestures

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = min(max(newScale, 0.5), 4.0)
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - Crop Overlay

    private func cropOverlay(imageSize: CGSize, containerSize: CGSize) -> some View {
        let imageOrigin = CGPoint(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2
        )

        let cropRect = CGRect(
            x: imageOrigin.x + cropOrigin.x * imageSize.width,
            y: imageOrigin.y + cropOrigin.y * imageSize.height,
            width: cropSize.width * imageSize.width,
            height: cropSize.height * imageSize.height
        )

        return ZStack {
            // Semi-transparent overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .reverseMask {
                    Rectangle()
                        .frame(width: cropRect.width, height: cropRect.height)
                        .position(x: cropRect.midX, y: cropRect.midY)
                }
                .allowsHitTesting(false)
        }
    }

    private func cropBorder(imageSize: CGSize, containerSize: CGSize) -> some View {
        let imageOrigin = CGPoint(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2
        )

        let cropRect = CGRect(
            x: imageOrigin.x + cropOrigin.x * imageSize.width,
            y: imageOrigin.y + cropOrigin.y * imageSize.height,
            width: cropSize.width * imageSize.width,
            height: cropSize.height * imageSize.height
        )

        return Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: cropRect.width, height: cropRect.height)
            .position(x: cropRect.midX, y: cropRect.midY)
            .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func fitSize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)
        return CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
    }

    private func performCrop() -> UIImage {
        let imageWidth = sourceImage.size.width
        let imageHeight = sourceImage.size.height

        let cropX = cropOrigin.x * imageWidth
        let cropY = cropOrigin.y * imageHeight
        let cropW = cropSize.width * imageWidth
        let cropH = cropSize.height * imageHeight

        let cropCGRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
            .intersection(CGRect(origin: .zero, size: sourceImage.size))

        guard !cropCGRect.isEmpty,
              let cgImage = sourceImage.cgImage?.cropping(to: cropCGRect) else {
            return sourceImage
        }

        return UIImage(cgImage: cgImage, scale: sourceImage.scale, orientation: sourceImage.imageOrientation)
    }
}


// MARK: - Reverse Mask Modifier

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

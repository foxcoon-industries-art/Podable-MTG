import SwiftUI
import Podwork


struct GameImagePickerView: View {
    let game: FinalPod
    let turns: [Turn]
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: GameVisualizationType?
    @State private var renderedImage: UIImage?
    @State private var showCropView = false
    @State private var isRendering = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select a visualization to include in your story:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(GameVisualizationType.allCases) { type in
                            vizThumbnailCard(type: type)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Game Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isRendering {
                    ProgressView("Rendering...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .sheet(isPresented: $showCropView) {
                if let image = renderedImage {
                    ImageCropView(sourceImage: image) { croppedImage in
                        onImageSelected(croppedImage)
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func vizThumbnailCard(type: GameVisualizationType) -> some View {
        Button {
            renderAndPresent(type: type)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fit)

                    Image(systemName: type.systemImage)
                        .font(.system(size: 36))
                        .foregroundStyle(colorForType(type).gradient)
                }

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(type.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func renderAndPresent(type: GameVisualizationType) {
        isRendering = true
        selectedType = type

        // Render on the main actor (already required by the chart views)
        let image = GameImageRenderer.render(
            type: type,
            game: game,
            turns: turns,
            size: CGSize(width: 300, height: 300)
        )

        renderedImage = image
        isRendering = false
        showCropView = true
    }

    private func colorForType(_ type: GameVisualizationType) -> Color {
        switch type {
        case .podFlowMap: return .blue
        case .turnTimePie: return .orange
        case .companionCube: return .purple
        case .gameOverview: return .green
        }
    }
}

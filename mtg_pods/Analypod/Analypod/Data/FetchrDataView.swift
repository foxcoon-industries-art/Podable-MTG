import SwiftUI
import Charts
import Podwork


// MARK: - Stat Split Enum
public enum StatSplitCategory: CaseIterable, Identifiable {
    case commander
    case bracket
    case turnOrder

    public var id: Self { self }

    public var displayName: String {
        switch self {
        case .commander:  return "Commander"
        case .bracket:    return "Bracket"
        case .turnOrder:  return "Turn Order"
        }
    }

    public var icon: String {
        switch self {
        case .commander:  return "person.circle"
        case .bracket:    return "chart.bar"
        case .turnOrder:  return "metronome"
        }
    }
}


// MARK: - FetchrDataView  (replaces the old EnhancedStatisticsView for the Data section)
/*
public struct FetchrDataView: View {
    @StateObject private var dataManager = GameDataManager.shared
    @State private var selectedSplit: StatSplitCategory = .commander
    @State private var showUpdateCommanders = false

    private let sidePad: CGFloat = 6

    public init() {}

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {

            // ── Summary Cards ──
            summaryRow
                .padding(.top, 12)

            // ── Update Commanders Button ──
            updateCommandersButton
                .padding(.top, 8)

            // ── Split Picker ──
            splitPicker
                .padding(.top, 12)

            // ── Split Content (same panel background, interior swaps) ──
            splitContentPanel
                .padding(.top, 8)
                .padding(.bottom, 12)

            Spacer(minLength: 0)
        }
        .onAppear {
            if dataManager.commanderStats.isEmpty {
                dataManager.refreshStats()
            }
        }
        .sheet(isPresented: $showUpdateCommanders) {
            FetchrUpdateCommandersSheet()
        }
    }


    // MARK: - Summary Row  (Pods Played · Total Gameplay · Commanders Seen)
    @ViewBuilder
    private var summaryRow: some View {
        HStack(spacing: sidePad * 0.5) {
            StatisticsCardView(
                title: "Pods",
                value: "\(dataManager.podSummaryStats.totalGames)",
                color: Color.orange,
                subtitle: "Played"
            )
            .frame(minWidth: 0.25 * UIScreen.main.bounds.size.width)

            StatisticsCardView(
                title: "Time",
                value: timeFormatDuration(dataManager.podSummaryStats.totalPlaytime),
                color: Color.orange,
                subtitle: "Total"
            )
            .layoutPriority(1)

            StatisticsCardView(
                title: "Commanders",
                value: "\(dataManager.podSummaryStats.totalCmdrsSeenPlayed)",
                color: Color.orange,
                subtitle: "Seen"
            )
            .frame(minWidth: 0.25 * UIScreen.main.bounds.size.width)
        }
        .padding(.horizontal, sidePad)
    }


    // MARK: - Update Commanders Button
    @ViewBuilder
    private var updateCommandersButton: some View {
        Button {
            HapticFeedback.impact()
            showUpdateCommanders = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.subheadline)
                Text("Update Commanders")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.cyan.gradient)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(Color.cyan.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }


    // MARK: - Segmented Split Picker
    @ViewBuilder
    private var splitPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatSplitCategory.allCases) { category in
                let isSelected = selectedSplit == category
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedSplit = category
                    }
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .medium)
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)

                        // Active indicator
                        Rectangle()
                            .fill(isSelected ? Color.orange : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, sidePad)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    // MARK: - Split Content Panel  (shared panel background; interior swaps)
    @ViewBuilder
    private var splitContentPanel: some View {
        ZStack(alignment: .top) {
            // Shared panel background
            RoundedRectangle(cornerRadius: 12)
                .background(Color(.systemGray6).gradient)
                .overlay( RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cyan, lineWidth:10)
                    )
              

            // Content switches inside the same panel
            Group {
                switch selectedSplit {
                case .commander:
                    FetchrCommanderList()
                case .bracket:
                    FetchrBracketList()
                case .turnOrder:
                    FetchrTurnOrderList()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 0)
        }
        .padding(.horizontal, sidePad)
        .frame(minHeight: 200)
    }
}
*/

// MARK: - Update Commanders Sheet  (modernised placeholder)
private struct FetchrUpdateCommandersSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadComplete = false
    @State private var downloadError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer(minLength: 12)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.cyan.gradient)
                }

                // Title & description
                VStack(spacing: 8) {
                    Text("Update Commanders")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Keep your commander database in sync after every new set release so card lookups stay accurate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Divider()

                // Status / progress area
                if isDownloading {
                    VStack(spacing: 12) {
                        ProgressView(value: downloadProgress)
                            .tint(Color.cyan)
                            .padding(.horizontal, 40)
                        Text("Downloading…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if downloadComplete {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.green.gradient)
                        Text("Commanders Updated!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.green)
                    }
                } else if let err = downloadError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.orange.gradient)
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 0)

                // Action button
                if !downloadComplete {
                    Button {
                        startDownload()
                    } label: {
                        Text(isDownloading ? "Updating…" : (downloadError != nil ? "Retry" : "Download Now"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cyan.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isDownloading)
                    .padding(.horizontal, 32)
                }

                // Close
                Button("Close") { dismiss() }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func startDownload() {
        isDownloading = true
        downloadError = nil
        downloadProgress = 0

        // Simulate download progress (replace with real Scryfall fetch)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { t in
            downloadProgress += 0.03
            if downloadProgress >= 1.0 {
                t.invalidate()
                downloadProgress = 1.0
                isDownloading = false
                downloadComplete = true
            }
        }
    }
}


//#Preview {
//    FetchrDataView()
//        .preferredColorScheme(.dark)
//}

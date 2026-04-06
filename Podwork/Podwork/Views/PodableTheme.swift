import SwiftUI


// MARK: - Podable Unified Design System
//
// Core visual language shared across the three main sections (Data, History, News).
// Every reusable shell, card, header, and interactive badge lives here so that
// adding a new section or tweaking the look app-wide is a single-file change.
//
// Apple HIG compliance notes kept inline with each constant / component:
//   • 8 pt grid for spacing                        (HIG: Layout & Spacing → Grid System)
//   • SF Pro via standard Text/Image APIs          (HIG: Typography → San Francisco)
//   • Semantic colours that adapt to dark mode     (HIG: Color → System Colors)
//   • ultraThinMaterial for translucency/depth     (HIG: Color → Vibrancy)
//   • Dark-gray shells, never pure #000            (HIG: Dark Mode → "Avoid pure black")
//   • SF Symbol weight matched to adjacent text    (HIG: Typography → SF Symbols)
//   • Accessibility labels on every icon button    (HIG: Accessibility → VoiceOver)
//   • Reduce-motion guard on animated badges       (HIG: Accessibility → Reduce Motion)
//   • 16 pt horizontal margins on iPhone           (HIG: Layout & Spacing → Grid System)


// ─────────────────────────────────────────────
// MARK: - Theme Constants
// ─────────────────────────────────────────────

public enum PodableTheme {

    // MARK: Outer-Panel Gradient Colours (one per section)
    /// DataStatsMainView — lighter mid-tone shell
    public static let dataOuterColor:    Color = .gray
    public static let dataOuterColorData:    Color = Color(.systemBackground)
    /// YeetPodView — darkest shell.
    /// HIG Dark Mode: "Avoid pure black (#000000) — use dark gray for true blacks."
    public static let historyOuterColor: Color = Color(red: 0.04, green: 0.04, blue: 0.06)
    /// News — deep indigo, distinct from both while staying cohesive
    public static let newsOuterColor:    Color = Color(red: 0.06, green: 0.09, blue: 0.22)

    // MARK: Border Accents
    /// Outer panel accent stroke (Data = orange, News = purple, History omits it)
    public static let outerAccentBorder:  Color = .black
    public static let outerAccentBorderData:  Color = .purple
    /// Inner content-card stroke — shared across all sections
    public static let innerContentBorder: Color = .black

    // MARK: 8 pt Grid Spacing
    /// HIG: "8pt, 16pt, 24pt, 32pt standard increments"
    public static let spacingXS: CGFloat = 4
    public static let spacingS:  CGFloat = 8
    public static let spacingM:  CGFloat = 16
    public static let spacingL:  CGFloat = 24
    public static let spacingXL: CGFloat = 32

    // MARK: Margins
    /// HIG: "Margins: 16pt (iPhone), 20pt (iPad)"
    public static let marginIPhone: CGFloat = 16

    // MARK: Corner Radii
    public static let radiusS: CGFloat = 8
    public static let radiusM: CGFloat = 12
    public static let radiusL: CGFloat = 16
}




// ─────────────────────────────────────────────
// MARK: - Podable Logo (Colours and Outlines)
// ─────────────────────────────────────────────

@MainActor
public struct PodableLogoStyle: ViewModifier {
    ///  Text("Podable")
    ///  .modifier(PodableLogoStyle())
    public init() {}
    ///
    public func body(content: Content) -> some View {
        content
            .bold()
            .foregroundStyle(Color.blue.gradient)
            .customStroke(color: Color.brown, width: 0.20)
            .customStroke(color: Color.black, width: 1.05125)
    }
}



// ─────────────────────────────────────────────
// MARK: - Section Panel  (outermost shell)
// ─────────────────────────────────────────────
/// Wraps a section's header + content card in the gradient / material / border
/// recipe that DataStatsMainView and YeetPodView already use.
///
/// Usage:
/// ```swift
/// PodableSectionPanel(outerColor: .newsOuterColor, accentBorder: .purple) {
///     VStack {
///         PodableSectionHeader(...)
///         PodableContentCard { ... }
///     }
/// }
/// ```
public struct PodableSectionPanel<Content: View>: View {

    private let outerColor:   Color
    private let accentBorder: Color?
    private let content:      Content

    /// - Parameters:
    ///   - outerColor:   The gradient seed colour for the shell.  Defaults to `dataOuterColor`.
    ///   - accentBorder: An optional coloured 1 pt stroke overlaid on the shell.  Pass `nil` to omit (History style).
    ///   - content:      Everything that goes inside the shell (header + card + any footers).
    public init(
        outerColor:   Color   = PodableTheme.dataOuterColor,
        accentBorder: Color?  = PodableTheme.outerAccentBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.outerColor   = outerColor
        self.accentBorder = accentBorder
        self.content      = content()
    }

    public var body: some View {
        content
            .padding(PodableTheme.spacingS )
            .background(
                RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                    .fill(outerColor.gradient.opacity(0.75))
                    .fill(.ultraThinMaterial)
                    .stroke(Color.black, lineWidth: 0.5)
                    .background(Color.clear)
            )
            .overlay(
                accentBorder.map { border in
                    RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                        .stroke(border, lineWidth: 1)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, PodableTheme.marginIPhone/2)
    }
}


// ─────────────────────────────────────────────
// MARK: - Content Card  (inner scrollable area)
// ─────────────────────────────────────────────
/// The inner card that lives inside a `PodableSectionPanel`.
/// Applies the systemBackground gradient + material + cyan border that both
/// DataStatsMainView (mainPanelView) and YeetPodView (displayPodsView) share.
public struct PodableContentCard<Content: View>: View {

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(Color(.systemBackground).gradient.opacity(0.5))
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: PodableTheme.radiusM)
                    .fill(Color.clear)
                    .stroke(PodableTheme.innerContentBorder, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: PodableTheme.radiusM))
    }
}


// ─────────────────────────────────────────────
// MARK: - Section Header
// ─────────────────────────────────────────────
/// Reusable title + icon row that sits at the top of a section panel, directly
/// mirroring the `headerSection` in DataStatsMainView and the ZStack header in
/// YeetPodView.
///
/// Two title styles match the two established patterns:
///   - `.primary`  → bold, primary-coloured title   (DataStatsMainView)
///   - `.stroke`   → white title with black outline (YeetPodView)
///
/// HIG: SF Symbol weight is set to `.bold` to match the `.largeTitle.bold()` title text.
public struct PodableSectionHeader: View {

    /// Controls how the title text is rendered.
    public enum TitleStyle { case primary, stroke }

    private let title:     String
    private let icon:      String
    private let iconColor: Color
    private let style:     TitleStyle

    public init(
        title:     String,
        icon:      String,
        iconColor: Color          = .orange,
        style:     TitleStyle     = .primary
    ) {
        self.title     = title
        self.icon      = icon
        self.iconColor = iconColor
        self.style     = style
    }

    public var body: some View {
        HStack(alignment: .center) {
            //Spacer(minLength: .zero)
            Image(systemName: icon)
                .font(Font.title.weight(.bold))
                .foregroundStyle(iconColor.gradient)
                .customStroke(color: Color.black, width: 0.5)
                .scaleEffect(x: 1.25, y: 1.25)
                .offset(x: -4)
                .opacity(0)
            
            
            titleView
                .frame(maxWidth: .infinity)

            //Spacer(minLength: .zero)

            // HIG SF Symbols: "Match symbol weight to text weight"
            // Title is .largeTitle.bold() → icon must also be bold weight.
            Image(systemName: icon)
                .font(Font.title.weight(.bold))
                .foregroundStyle(iconColor.gradient)
                .customStroke(color: Color.black, width: 0.5)
                .scaleEffect(x: 1.25, y: 1.25)
                .offset(x: -4)
        }
    }

    // ── title rendering ──
    @ViewBuilder
    private var titleView: some View {
        switch style {
        case .primary:
            Text(title)
                .font(.largeTitle)
                .bold()
                .foregroundStyle(Color.primary)

        case .stroke:
            Text(title)
                .foregroundStyle(Color.white.gradient)
                .font(.largeTitle)
                .bold()
                .customStroke(color: Color.black, width: 0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.888)
        }
    }
}


// ─────────────────────────────────────────────
// MARK: - Section Label  (sub-heading)
// ─────────────────────────────────────────────
/// A `.headline` / `.secondary` sub-heading that introduces a group of content
/// inside a content card.  Coalesces the identical pattern used for "Your Pods"
/// and "View Statistics By" in DataStatsMainView (and any future equivalents).
///
/// Usage:
/// ```swift
/// PodableSectionLabel("Your Pods")
/// ```
public struct PodableSectionLabel: View {

    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.secondary)
    }
}


// ─────────────────────────────────────────────
// MARK: - Info Card  (systemGray6 container)
// ─────────────────────────────────────────────
/// A rounded container with a `.systemGray6` fill and the standard 12 pt radius.
/// Coalesces the same visual treatment used in:
///   • DataStatsMainView → updateCommandersSection (commander count + refresh button)
///   • DataStatsMainView → categoryDetailView      (back-nav bar background)
///   • CategoryButton                              (each drill-down row)
///   • PodPassInfoView                             (bullet-point feature list)
///
/// Usage:
/// ```swift
/// PodableInfoCard {
///     Text("Commander count or anything else")
/// }
/// ```
public struct PodableInfoCard<Content: View>: View {

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .background(Color(.systemGray6))
            .cornerRadius(PodableTheme.radiusM)
    }
}


// ─────────────────────────────────────────────
// MARK: - Pin Button
// ─────────────────────────────────────────────
/// Unified pin toggle shared by Commander rows (CommanderStatRow) and News
/// article cards.  Matches the exact icon / colour / rotation treatment already
/// used in CommanderStatRow so that pinning feels identical everywhere.
///
/// HIG SF Symbols: uses `.fill` variant for the pinned (selected) state.
/// HIG Accessibility: provides a VoiceOver label that reflects current state.
public struct PodablePinButton: View {

    private let isPinned: Bool
    private let onToggle: () -> Void

    public init(isPinned: Bool, onToggle: @escaping () -> Void) {
        self.isPinned = isPinned
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            // HIG: "Use filled variants for selected states"
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.callout)
                .foregroundStyle(isPinned ? Color.orange : Color.secondary)
                .rotationEffect(isPinned ? .degrees(45) : .degrees(0))
        }
        .buttonStyle(.plain)
        // HIG Accessibility: "Provide meaningful accessibility labels"
        .accessibilityLabel(isPinned ? "Pinned" : "Not pinned")
        .accessibilityHint("Tap to \(isPinned ? "unpin" : "pin")")
    }
}


// ─────────────────────────────────────────────
// MARK: - Unread Badge
// ─────────────────────────────────────────────
/// Pulsing capsule that signals an unread item.  Extracted from the existing
/// BreakingNewsBanner so that News articles can use it through the shared module
/// without duplicating the animation logic.
///
/// HIG Animation: pulse duration set to 0.3 s (Quick tier: 0.2–0.3 s) for a
/// small repeating indicator.
/// HIG Accessibility: respects the system Reduce Motion preference — when
/// enabled the pulse is suppressed entirely.
public struct PodableUnreadBadge: View {

    private let label: String
    private let color: Color
    @State private var pulse = false

    /// HIG Accessibility: "Provide alternatives to animations"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - label: Text shown next to the pulsing dot.  Defaults to `"Mega"`.
    ///   - color: Base colour for the dot and capsule fill.  Defaults to `.purple`.
    public init(label: String = "Mega", color: Color = .purple) {
        self.label = label
        self.color = color
    }

    public var body: some View {
        HStack(spacing: PodableTheme.spacingS) {
            Circle()
                .fill(color)
                .stroke(Color.black, lineWidth: 1)
                .frame(width: 8, height: 8)
                .scaleEffect(pulse && !reduceMotion ? 1.3 : 1.0)
                // HIG Animation Duration: Quick = 0.2–0.3 s
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                    value: pulse
                )

            Text(label)
                //.font(.system(size: 12, weight: .heavy))
                .font(.caption)
                .fontWeight( .heavy)
                .foregroundStyle(Color.white.gradient)
                .customStroke(color: Color.black, width: 0.7405)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.gradient.opacity(0.32))
                .stroke(Color.black, lineWidth: 1)
        )
        .onAppear { pulse = true }
    }
}



// MARK: - Podable double tap

public struct PodableDoubleTap: View {
    let two = Image(systemName:"2.brakesignal")
    let tap = Image(systemName:"hand.point.up.left.fill")

    public init() {}
    public var body : some View {
        AnyView(
            ZStack{
                two .offset(y:-5)
                    .foregroundStyle(Color.brown.gradient)
                tap .offset(x:5, y:8)
                    .foregroundStyle(Color.black.gradient)
            }.bold()
        )
    }
}



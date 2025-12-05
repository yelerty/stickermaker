//
//  DesignSystem.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI

// MARK: - Colors
extension Color {
    static let appPrimary = Color(red: 0.4, green: 0.5, blue: 1.0)
    static let appSecondary = Color(red: 0.8, green: 0.4, blue: 0.9)
    static let appBackground = Color(uiColor: .systemGroupedBackground)
    static let appCardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let appAccent = Color(red: 0.3, green: 0.7, blue: 0.9)
}

// MARK: - Typography
extension Font {
    static let appTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let appHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let appSubheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    static let appBody = Font.system(size: 15, weight: .regular, design: .default)
    static let appCaption = Font.system(size: 13, weight: .regular, design: .default)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let round: CGFloat = 999
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color.appPrimary, Color.appAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubheadline)
            .foregroundColor(.appPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.appCardBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.appCardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }
            Text(title)
                .font(.appHeadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Adaptive Layout Helper
struct AdaptiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat
    let content: Content

    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat = Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            if isLandscape {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content
                }
            } else {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - Custom Slider
struct CustomSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.appSubheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(String(format: step >= 1 ? "%.0f" : "%.2f", value))\(unit)")
                    .font(.appCaption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
            }

            Slider(value: $value, in: range, step: step)
                .tint(Color.appPrimary)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.appTitle)
                    .fontWeight(.bold)

                Text(message)
                    .font(.appBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

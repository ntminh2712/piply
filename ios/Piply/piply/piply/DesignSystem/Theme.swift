import SwiftUI

enum DS {
    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 14
        static let l: CGFloat = 18
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let m: CGFloat = 14
        static let l: CGFloat = 18
        static let xl: CGFloat = 22
    }

    enum Shadow {
        static let card = (color: Color.black.opacity(0.25), radius: CGFloat(14), y: CGFloat(8))
    }

    enum ColorToken {
        // Dark theme colors inspired by Trendlyze dashboard
        static let accent = Color(red: 0.58, green: 0.40, blue: 0.98) // Purple accent
        static let background = Color(red: 0.11, green: 0.11, blue: 0.13) // Dark background
        static let card = Color(red: 0.15, green: 0.15, blue: 0.17) // Dark card
        static let cardElevated = Color(red: 0.18, green: 0.18, blue: 0.20) // Elevated card
        static let border = Color.white.opacity(0.08)
        
        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        
        // Metric colors from dashboard
        static let metricPurple = Color(red: 0.58, green: 0.40, blue: 0.98) // Purple
        static let metricPink = Color(red: 0.98, green: 0.40, blue: 0.65) // Pink
        static let metricGreen = Color(red: 0.20, green: 0.78, blue: 0.45) // Green
        static let metricOrange = Color(red: 1.0, green: 0.58, blue: 0.20) // Orange
        static let metricTeal = Color(red: 0.20, green: 0.70, blue: 0.80) // Teal
        
        // Status colors
        static let success = Color(red: 0.20, green: 0.78, blue: 0.45) // Green
        static let danger = Color(red: 0.95, green: 0.30, blue: 0.30) // Red
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.20) // Orange
        static let info = Color(red: 0.20, green: 0.70, blue: 0.80) // Teal/Blue
    }
}

struct Card: ViewModifier {
    var elevated: Bool = false
    var color: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(DS.Spacing.l)
            .background(
                Group {
                    if let color = color {
                        color.opacity(0.15)
                    } else {
                        elevated ? DS.ColorToken.cardElevated : DS.ColorToken.card
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
    }
}

// Tooltip Sheet Component
struct TooltipSheet: View {
    let title: String
    let tooltip: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.ColorToken.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DS.ColorToken.textTertiary)
                }
            }
            
            Text(tooltip)
                .font(.subheadline)
                .foregroundStyle(DS.ColorToken.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DS.ColorToken.background)
        .presentationDetents([.height(200), .medium])
        .presentationDragIndicator(.visible)
    }
}

extension View {
    func card(elevated: Bool = false, color: Color? = nil) -> some View {
        modifier(Card(elevated: elevated, color: color))
    }
}

// Metric Card Component inspired by dashboard
struct MetricCard: View {
    let title: String
    let value: String
    let change: String?
    let icon: String
    let color: Color
    let tooltip: String?
    let percentage: String?
    
    init(title: String, value: String, change: String? = nil, icon: String, color: Color, tooltip: String? = nil, percentage: String? = nil) {
        self.title = title
        self.value = value
        self.change = change
        self.icon = icon
        self.color = color
        self.tooltip = tooltip
        self.percentage = percentage
    }
    
    @State private var showTooltip = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DS.ColorToken.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let percentage = percentage {
                        Text(percentage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.ColorToken.textSecondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(DS.ColorToken.textSecondary)
                    
                    if let tooltip = tooltip {
                        Button {
                            showTooltip = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(DS.ColorToken.textTertiary)
                        }
                    }
                }
                
                if let change = change {
                    HStack(spacing: 4) {
                        Image(systemName: change.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(change)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(change.hasPrefix("+") ? DS.ColorToken.success : DS.ColorToken.danger)
                    .padding(.top, 2)
                } else {
                    // Spacer để đảm bảo chiều cao đều nhau
                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(DS.Spacing.m)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .stroke(DS.ColorToken.border, lineWidth: 1)
        )
        .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
        .sheet(isPresented: $showTooltip) {
            TooltipSheet(title: title, tooltip: tooltip ?? "")
        }
    }
}



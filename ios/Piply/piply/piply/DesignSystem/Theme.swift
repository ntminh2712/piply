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
        static let card = (color: Color.black.opacity(0.10), radius: CGFloat(14), y: CGFloat(8))
    }

    enum ColorToken {
        static let accent = Color.indigo
        static let background = Color(uiColor: .systemGroupedBackground)
        static let card = Color(uiColor: .secondarySystemGroupedBackground)
        static let cardElevated = Color(uiColor: .systemBackground)
        static let border = Color.black.opacity(0.08)

        static let success = Color.green
        static let danger = Color.red
        static let warning = Color.orange
        static let info = Color.blue
    }
}

struct Card: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(DS.Spacing.l)
            .background(elevated ? DS.ColorToken.cardElevated : DS.ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .stroke(DS.ColorToken.border, lineWidth: 1)
            )
            .shadow(color: DS.Shadow.card.color, radius: DS.Shadow.card.radius, x: 0, y: DS.Shadow.card.y)
    }
}

extension View {
    func card(elevated: Bool = false) -> some View {
        modifier(Card(elevated: elevated))
    }
}



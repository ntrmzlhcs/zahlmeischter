//
//  Theme.swift
//  zahlmeischter
//
//  The V2 "Cool Premium" (light) design tokens from design.md — the prototype's
//  `themeColors()` ported to Swift as the single source of truth for color, glass,
//  and the editorial serif across the app. Light mode only (no dark branching).
//

import SwiftUI

enum Theme {

    // MARK: Accent & semantics
    /// Primary accent — teal. Actions, identity, selected states, the FAB, checkmarks.
    static let accent = Color(hex: "0FA28F")
    /// "Owed to you" / positive amounts.
    static let positive = Color(hex: "0E9E82")
    /// "You owe" / negative amounts — a calm rose, never an alarming red.
    static let negative = Color(hex: "D14D74")

    // MARK: Text
    static let fg = Color(hex: "172A30")
    static let fg2 = fg.opacity(0.62)
    static let fg3 = fg.opacity(0.36)

    // MARK: Glass & surfaces (float over the mesh)
    static let glass = Color.white.opacity(0.5)
    static let glass2 = Color.white.opacity(0.38)
    static let glassBorder = Color.white.opacity(0.72)
    static let sheet = Color(hex: "F7FAFA").opacity(0.9)
    static let solid = Color.white
    static let line = fg.opacity(0.1)
    static let nav = Color.white.opacity(0.62)

    // MARK: Secondary / illustration hue
    static let violet = Color(hex: "6C5CE7")

    // MARK: Universal mesh stops
    static let meshViolet = Color(hex: "C9BFFF")
    static let meshTeal = Color(hex: "9FE6DD")
    static let meshTeal2 = Color(hex: "9FE0D6")
    static let meshPink = Color(hex: "FBD5E8")
    static let meshBase1 = Color(hex: "E8F1F2")
    static let meshBase2 = Color(hex: "E6EEF5")

    // MARK: Palettes
    /// "Du" is teal; other members cycle this palette deterministically by index.
    static let me = accent
    static let memberPalette: [Color] = [
        Color(hex: "E16A93"), Color(hex: "6C5CE0"), Color(hex: "E0954E"),
        Color(hex: "3E8FD0"), Color(hex: "C77DCE"), Color(hex: "D98E5A"),
        Color(hex: "3FB7A0"),
    ]

    /// Category tint (matches the prototype's `catMeta`). Default is a soft blue.
    static func categoryColor(_ category: String) -> Color {
        switch category {
        case "Unterkunft", "Miete": Color(hex: "6C5CE0")
        case "Transport": Color(hex: "3E8FD0")
        case "Essen": Color(hex: "E16A93")
        case "Lebensmittel": Color(hex: "36A877")
        case "Aktivität": Color(hex: "E0954E")
        case "Fixkosten": Color(hex: "9B6CD0")
        case "Ausgleich": accent
        default: Color(hex: "3E8FD0")
        }
    }

    /// Two-stop gradient tint for a group tile, keyed by index.
    static func groupTint(_ index: Int) -> LinearGradient {
        let pairs: [(String, String)] = [
            ("0FA28F", "5BD2C4"), ("6C5CE0", "A99BF0"),
            ("3E8FD0", "7FC8EC"), ("E16A93", "F2A6C8"),
        ]
        let (a, b) = pairs[index % pairs.count]
        return LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Editorial serif (New York)

extension Font {
    /// New York (the system serif) at a fixed size — used for hero numbers and
    /// editorial titles per design.md's Display role.
    static func serif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Liquid Glass card

extension View {
    /// A floating glass surface over the mesh: a translucent white fill backed by a
    /// system material, a bright hairline border, and an optional soft cool shadow —
    /// the everyday material from design.md.
    func glassCard(
        cornerRadius: CGFloat = 22,
        fill: Color = Theme.glass,
        shadow: Bool = true
    ) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(fill)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.glassBorder, lineWidth: 0.5)
            )
            .shadow(color: shadow ? Color(hex: "122E2A").opacity(0.14) : .clear,
                    radius: 18, x: 0, y: 12)
    }
}

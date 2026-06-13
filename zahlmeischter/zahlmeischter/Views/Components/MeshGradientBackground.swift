//
//  MeshGradientBackground.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI

/// The Dashboard's signature backdrop: the four-stop "Cool Premium" mesh gradient
/// (design.md) that slowly **breathes**. The four corner control points stay pinned
/// so the rectangle always fills edge-to-edge; the edge and centre points spring
/// between a "rest" and a "drift" arrangement, autoreversing forever.
///
/// Reduce Motion is a hard requirement (design.md): when enabled, the animation is
/// never started and a static mesh renders.
struct MeshGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isBreathing = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: isBreathing ? Self.driftPoints : Self.restPoints,
            colors: colorScheme == .dark ? Self.darkStops : Self.lightStops
        )
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 7, dampingFraction: 0.85).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    // MARK: - Control points (row-major, 3×3; corners pinned)

    private static let restPoints: [SIMD2<Float>] = [
        [0.00, 0.00], [0.50, 0.00], [1.00, 0.00],
        [0.00, 0.50], [0.50, 0.50], [1.00, 0.50],
        [0.00, 1.00], [0.50, 1.00], [1.00, 1.00],
    ]

    private static let driftPoints: [SIMD2<Float>] = [
        [0.00, 0.00], [0.45, 0.00], [1.00, 0.00],
        [0.00, 0.55], [0.55, 0.45], [1.00, 0.40],
        [0.00, 1.00], [0.60, 1.00], [1.00, 1.00],
    ]

    // MARK: - Palettes (same organic arrangement, tuned per appearance)

    /// Dark mode — the hero experience: deep indigo base, violet, soft teal, and a
    /// single dusty-pink accent.
    private static let darkStops: [Color] = [
        Color(hex: "2B2A55"), Color(hex: "2B2A55"), Color(hex: "6C5CE7"),
        Color(hex: "6C5CE7"), Color(hex: "4ECDC4"), Color(hex: "F2A6C8"),
        Color(hex: "4ECDC4"), Color(hex: "6C5CE7"), Color(hex: "2B2A55"),
    ]

    /// Light mode — softened/lightened versions of the same four stops.
    private static let lightStops: [Color] = [
        Color(hex: "B8B8E8"), Color(hex: "B8B8E8"), Color(hex: "C9BFFF"),
        Color(hex: "C9BFFF"), Color(hex: "A8E8E2"), Color(hex: "FBD5E8"),
        Color(hex: "A8E8E2"), Color(hex: "C9BFFF"), Color(hex: "B8B8E8"),
    ]
}

#Preview("Mesh – breathing") {
    MeshGradientBackground()
}

//
//  MeshGradientBackground.swift
//  zahlmeischter
//
//  The app's signature backdrop: the single, continuous "Cool Premium" (light) mesh
//  from design.md V2 that slowly **breathes**. One instance sits behind the whole app
//  (Dashboard, group detail, sheets) — never a solid background break. The four corners
//  carry the violet / teal / pink blobs over a light wash; the edge and centre points
//  spring between a "rest" and a "drift" arrangement on an ~18s autoreversing loop.
//
//  Light only (V2 pivot). Reduce Motion is a hard requirement: when enabled the
//  animation never starts and a static mesh renders.
//

import SwiftUI

struct MeshGradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isBreathing = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: isBreathing ? Self.driftPoints : Self.restPoints,
            colors: Self.stops
        )
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    // MARK: - Control points (row-major, 3×3; corners pinned, interior drifts)

    private static let restPoints: [SIMD2<Float>] = [
        [0.00, 0.00], [0.50, 0.00], [1.00, 0.00],
        [0.00, 0.50], [0.48, 0.52], [1.00, 0.50],
        [0.00, 1.00], [0.50, 1.00], [1.00, 1.00],
    ]

    private static let driftPoints: [SIMD2<Float>] = [
        [0.00, 0.00], [0.58, 0.00], [1.00, 0.00],
        [0.00, 0.42], [0.56, 0.44], [1.00, 0.60],
        [0.00, 1.00], [0.42, 1.00], [1.00, 1.00],
    ]

    // MARK: - Stops — colour spread across the field over a light centre

    private static let center = Color(hex: "EAF1F3")

    private static let stops: [Color] = [
        Color(hex: "C3B6FF"), Color(hex: "BFD4F2"), Color(hex: "96E7DD"),
        Color(hex: "C8C0F4"), center,               Color(hex: "9FE3D8"),
        Color(hex: "9FE0D6"), Color(hex: "F6CFE6"), Color(hex: "FBD0E8"),
    ]
}

#Preview("Mesh – breathing") {
    MeshGradientBackground()
}

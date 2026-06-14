//
//  WalletMark.swift
//  zahlmeischter
//
//  The papercraft coin-purse brand mark (Konzept A, design.md): a pink-cream wallet
//  with a lighter flap and violet snap, and a teal coin cut in half sticking up out of
//  the centre. Reused by the launch animation (coin animated separately) and the
//  in-app brand lockup. No mesh background — that's the one place the mesh is absent.
//

import SwiftUI

/// A single teal coin disc (used resting in the purse and falling in the launch).
struct CoinMark: View {
    var size: CGFloat
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: "9BEDE5"), Color(hex: "4ECDC4"), Color(hex: "33B3AA")],
                                 center: .init(x: 0.36, y: 0.30), startRadius: 1, endRadius: size))
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: max(size * 0.02, 0.5)))
            .shadow(color: Color(hex: "141032").opacity(0.3), radius: size * 0.12, y: size * 0.08)
    }
}

/// The purse body (flap + snap), without the coin — the coin is composed on top so the
/// launch can animate it independently.
struct WalletBody: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            // body
            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "FEF5FB"), Color(hex: "F3D9EA"), Color(hex: "E9C3DC")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.52, height: size * 0.40)
                .shadow(color: Color(hex: "2B2A55").opacity(0.34), radius: size * 0.07, y: size * 0.06)
            // flap
            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, Color(hex: "F7E6F0")], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.52, height: size * 0.17)
                .offset(y: -size * 0.115)
            // snap
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "9D8CFF"), Color(hex: "6C5CE7")],
                                     center: .init(x: 0.35, y: 0.30), startRadius: 0, endRadius: size * 0.08))
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: size * 0.085, y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

struct WalletMark: View {
    var size: CGFloat
    var showCoin: Bool = true

    var body: some View {
        ZStack {
            if showCoin {
                CoinMark(size: size * 0.30)
                    .offset(y: -size * 0.16)   // half above the purse top edge
            }
            WalletBody(size: size)
        }
        .frame(width: size, height: size)
    }
}

#Preview { WalletMark(size: 200).padding().background(Color(hex: "EDE7FB")) }

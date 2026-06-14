//
//  LaunchView.swift
//  zahlmeischter
//
//  The launch sequence (design.md V2): the violet wallet assembles as three teal coins
//  fall in from above — the first two drop into the purse, the last settles into the
//  icon's signature half-out position — over the moving mesh, with the wordmark and
//  tagline below throughout. Then a scale-and-fade hands off. Plays once per process;
//  respects Reduce Motion (straight to the static end-state).
//

import SwiftUI

struct LaunchView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat = 190
    @State private var coinY: [CGFloat] = [-170, -170, -170]
    @State private var coinOpacity: [Double] = [0, 0, 0]
    @State private var contentScale: CGFloat = 1
    @State private var contentOpacity: Double = 1

    var body: some View {
        ZStack {
            MeshGradientBackground()
            VStack(spacing: 34) {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        CoinMark(size: size * 0.30)
                            .offset(y: coinY[index])
                            .opacity(coinOpacity[index])
                    }
                    WalletBody(size: size)
                }
                .frame(width: size, height: size)
                .scaleEffect(contentScale)

                VStack(spacing: 6) {
                    Text("zahlmeischter").font(.serif(28)).foregroundStyle(Color(hex: "211B3A"))
                    Text("Kosten geteilt, Laune gerettet").font(.system(size: 13)).foregroundStyle(Color(hex: "211B3A").opacity(0.58))
                }
            }
            .opacity(contentOpacity)
        }
        .onAppear(perform: run)
    }

    private func run() {
        guard !reduceMotion else {
            coinY[2] = -size * 0.16; coinOpacity[2] = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { onFinished() }
            return
        }
        for index in 0..<3 {
            let delay = 0.3 + Double(index) * 0.6
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                coinY[index] = index == 2 ? -size * 0.16 : size * 0.04
                coinOpacity[index] = 1
            }
            if index < 2 {
                withAnimation(.easeIn(duration: 0.3).delay(delay + 0.5)) { coinOpacity[index] = 0 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 0.55)) { contentScale = 1.2; contentOpacity = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.55) { onFinished() }
    }
}

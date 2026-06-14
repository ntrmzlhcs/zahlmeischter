//
//  OnboardingView.swift
//  zahlmeischter
//
//  The 3-screen intro (design.md V2): an animated papercraft illustration, a New York
//  title and SF body, page dots, a teal CTA and Überspringen — over the mesh, on a
//  unified violet + teal + pink palette.
//

import SwiftUI

struct OnboardingView: View {
    let onFinished: () -> Void

    @State private var page = 0

    private struct Page { let title: String; let body: String }
    private let pages: [Page] = [
        .init(title: "Kosten geteilt, Laune gerettet",
              body: "Erfasse gemeinsame Kosten in Sekunden und behalt den Überblick, wer was ausgelegt hat."),
        .init(title: "Lade deine Gruppe ein",
              body: "Schick einen Link per iMessage oder E-Mail – auch an Leute, die die App noch nicht haben."),
        .init(title: "Gleicht clever aus",
              body: "zahlmeischter rechnet aus, wer wem wie viel schuldet – pro Währung und mit so wenigen Zahlungen wie möglich."),
    ]

    var body: some View {
        ZStack {
            MeshGradientBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Überspringen", action: onFinished)
                        .font(.system(size: 15)).foregroundStyle(Theme.fg2).padding(.trailing, 4)
                }
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 0) {
                            illustration(for: index).frame(height: 220)
                            Text(pages[index].title).font(.serif(30)).foregroundStyle(Theme.fg)
                                .multilineTextAlignment(.center).padding(.top, 40).frame(maxWidth: 300)
                            Text(pages[index].body).font(.system(size: 16)).foregroundStyle(Theme.fg2)
                                .multilineTextAlignment(.center).lineSpacing(2).padding(.top, 14).frame(maxWidth: 300)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule().fill(index == page ? Theme.accent : Theme.fg3)
                            .frame(width: index == page ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 26)

                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } } else { onFinished() }
                } label: {
                    Text(page == pages.count - 1 ? "Los geht's" : "Weiter")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .shadow(color: Theme.accent.opacity(0.42), radius: 12, y: 8)
                }
                .padding(.bottom, 26)
            }
            .padding(.horizontal, 28)
            .padding(.top, 70)
        }
    }

    @ViewBuilder private func illustration(for index: Int) -> some View {
        switch index {
        case 0: ReceiptDonutArt()
        case 1: InviteArt()
        default: SettleArt()
        }
    }
}

// MARK: - Illustration 1 · receipt + splitting donut

private struct ReceiptDonutArt: View {
    @State private var draw = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .frame(width: 150, height: 190)
                .shadow(color: Theme.violet.opacity(0.18), radius: 18, y: 12)
                .overlay(alignment: .top) {
                    VStack(spacing: 9) {
                        ForEach(0..<3, id: \.self) { row in
                            Capsule().fill(row == 0 ? Theme.violet.opacity(0.6) : Theme.fg3.opacity(0.5))
                                .frame(width: draw ? (row == 0 ? 90 : 110) : 0, height: 6)
                                .animation(.easeOut(duration: 0.5).delay(Double(row) * 0.12), value: draw)
                        }
                        DonutChart(appear: draw).frame(width: 92, height: 92).padding(.top, 8)
                    }
                    .padding(.top, 20)
                }
        }
        .onAppear { draw = true }
    }
}

private struct DonutChart: View {
    var appear: Bool
    private let segments: [(frac: CGFloat, color: Color)] = [
        (0.42, Theme.violet), (0.33, Color(hex: "4ECDC4")), (0.25, Color(hex: "F2A6C8")),
    ]
    var body: some View {
        ZStack {
            ForEach(0..<segments.count, id: \.self) { i in
                let seg = segments[i]
                let from = segments[0..<i].reduce(0) { $0 + $1.frac }
                Circle()
                    .trim(from: from + 0.012, to: appear ? from + seg.frac - 0.012 : from + 0.012)
                    .stroke(seg.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.7).delay(0.3 + Double(i) * 0.15), value: appear)
            }
        }
    }
}

// MARK: - Illustration 2 · invite

private struct InviteArt: View {
    @State private var appear = false
    @State private var pulse = false
    var body: some View {
        HStack(spacing: -14) {
            avatar("Du", Theme.accent, delay: 0)
            avatar("L", Color(hex: "E16A93"), delay: 0.12)
            Circle()
                .strokeBorder(Theme.violet, style: StrokeStyle(lineWidth: 2.5, dash: [5]))
                .frame(width: 60, height: 60)
                .overlay(Image(systemName: "plus").font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.violet))
                .scaleEffect(pulse ? 1.08 : 0.96)
                .padding(.leading, 22)
        }
        .onAppear {
            appear = true
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
    private func avatar(_ text: String, _ color: Color, delay: Double) -> some View {
        Circle().fill(color).frame(width: 60, height: 60)
            .overlay(Text(text).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white))
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            .scaleEffect(appear ? 1 : 0.4)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appear)
    }
}

// MARK: - Illustration 3 · smart settle (beams)

private struct SettleArt: View {
    @State private var progress: CGFloat = 0
    @State private var checkShown = false
    var body: some View {
        ZStack {
            // beams L→Du (teal) and M→Du (pink)
            Path { p in p.move(to: CGPoint(x: 40, y: 50)); p.addLine(to: CGPoint(x: 180, y: 90)) }
                .trim(from: 0, to: progress).stroke(Color(hex: "4ECDC4"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            Path { p in p.move(to: CGPoint(x: 40, y: 130)); p.addLine(to: CGPoint(x: 180, y: 90)) }
                .trim(from: 0, to: progress).stroke(Color(hex: "E16A93"), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            person("L", Color(hex: "4ECDC4")).position(x: 40, y: 50)
            person("M", Color(hex: "E16A93")).position(x: 40, y: 130)
            person("Du", Theme.accent, size: 60).position(x: 180, y: 90)

            if checkShown {
                Circle().fill(Theme.positive).frame(width: 34, height: 34)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(.white))
                    .position(x: 205, y: 60).transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 230, height: 180)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { checkShown = true } }
        }
    }
    private func person(_ text: String, _ color: Color, size: CGFloat = 48) -> some View {
        Circle().fill(color).frame(width: size, height: size)
            .overlay(Text(text).font(.system(size: size * 0.34, weight: .semibold)).foregroundStyle(.white))
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
    }
}

//
//  ProfileView.swift
//  zahlmeischter
//
//  The Profil tab: a glass profile card and a small settings list (preferred currency,
//  replay the intro, replay the launch animation) over the mesh.
//

import SwiftUI

struct ProfileView: View {
    var replayOnboarding: () -> Void = {}
    var replayLaunch: () -> Void = {}

    @Environment(AppState.self) private var appState

    private var displayName: String {
        let name = appState.myName.trimmed
        return name.isEmpty ? "Du" : name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Profil").font(.serif(30)).foregroundStyle(Theme.fg)

                HStack(spacing: 14) {
                    Circle().fill(Theme.accent).frame(width: 56, height: 56)
                        .overlay(Text("Du").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.fg)
                        Text("iCloud · synchronisiert").font(.system(size: 13)).foregroundStyle(Theme.fg2)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 22)
                .padding(.top, 18)

                SectionLabel("Einstellungen").padding(.top, 24)

                VStack(spacing: 0) {
                    settingRow("Bevorzugte Währung", trailing: "CHF", action: nil)
                    Divider().overlay(Theme.line)
                    settingRow("Einführung erneut ansehen", chevron: true, action: replayOnboarding)
                    Divider().overlay(Theme.line)
                    settingRow("Launch-Animation abspielen", chevron: true, action: replayLaunch)
                }
                .glassCard(cornerRadius: 18)

                Text("zahlmeischter · Version 2.0 · Swiss made")
                    .font(.system(size: 12)).foregroundStyle(Theme.fg3)
                    .frame(maxWidth: .infinity).padding(.top, 26)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
    }

    private func settingRow(_ title: String, trailing: String? = nil, chevron: Bool = false, action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            HStack {
                Text(title).font(.system(size: 16)).foregroundStyle(Theme.fg)
                Spacer()
                if let trailing { Text(trailing).font(.system(size: 15)).foregroundStyle(Theme.fg2) }
                if chevron { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.fg3) }
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

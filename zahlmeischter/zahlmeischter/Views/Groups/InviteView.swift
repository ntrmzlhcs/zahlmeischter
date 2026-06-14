//
//  InviteView.swift
//  zahlmeischter
//
//  Invite people (design.md V2): a shareable link card, then a channel choice —
//  Nachrichten (iMessage) or E-Mail — leading to a compose step (recipient field with
//  inline checkmark) and a sent confirmation. The core "invite via iMessage / email"
//  App-Store feature.
//

import SwiftUI

struct InviteView: View {
    let group: ExpenseGroup
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Step { case pick, compose, sent }
    private enum Channel { case message, email }

    @State private var step: Step = .pick
    @State private var channel: Channel = .message
    @State private var recipient = ""

    private var link: String { "zahlmeischter.app/g/\(group.uuid.uuidString.prefix(8).lowercased())" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Leute einladen", leading: "Schliessen", onLeading: { dismiss() })
            switch step {
            case .pick: pick
            case .compose: compose
            case .sent: sent
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 34)
        .sheetStyle()
    }

    // MARK: Pick

    private var pick: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Schick einen Link zu „\(group.name)“ – auch an Leute ohne die App.")
                .font(.system(size: 15)).foregroundStyle(Theme.fg2)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 4)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 11).fill(Theme.accent).frame(width: 38, height: 38)
                    .overlay(Image(systemName: "link").font(.system(size: 16)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Einladungslink").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.fg)
                    Text(link).font(.system(size: 12)).foregroundStyle(Theme.fg2).lineLimit(1)
                }
                Spacer()
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.glass2))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            .padding(.top, 16)

            VStack(spacing: 10) {
                channelRow(.message, color: Color(hex: "34C759"), icon: "message.fill",
                           title: "Nachrichten (iMessage)", subtitle: "Link per SMS oder iMessage senden")
                channelRow(.email, color: Color(hex: "3B82F6"), icon: "envelope.fill",
                           title: "E-Mail", subtitle: "Einladung als E-Mail verschicken")
            }
            .padding(.top, 16)
        }
    }

    private func channelRow(_ value: Channel, color: Color, icon: String, title: String, subtitle: String) -> some View {
        Button {
            channel = value
            withAnimation(.easeOut(duration: 0.2)) { step = .compose }
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12).fill(color).frame(width: 42, height: 42)
                    .overlay(Image(systemName: icon).font(.system(size: 18)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.fg)
                    Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.fg2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.fg3)
            }
            .padding(15)
            .glassCard(cornerRadius: 16, shadow: false)
        }
        .buttonStyle(.plain)
    }

    // MARK: Compose

    private var compose: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button { withAnimation(.easeOut(duration: 0.2)) { step = .pick } } label: {
                    Text("‹ zurück").font(.system(size: 13)).foregroundStyle(Theme.accent)
                }
                Text("· \(channel == .message ? "Nachrichten" : "E-Mail")").font(.system(size: 13)).foregroundStyle(Theme.fg2)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 14) {
                InlineCheckmarkField(label: "An", text: $recipient,
                                     keyboard: channel == .email ? .emailAddress : .phonePad)
                Text(messagePreview).font(.system(size: 14)).foregroundStyle(Theme.fg2).lineSpacing(3)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.glass2))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            .padding(.top, 12)

            Button { withAnimation { step = .sent } } label: {
                Label("Senden", systemImage: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 10, y: 8)
            }
            .padding(.top, 18)
        }
    }

    private var messagePreview: String {
        "Hoi! Ich teile unsere Ausgaben für „\(group.name)“ mit zahlmeischter. Mach mit über diesen Link: \(link)"
    }

    // MARK: Sent

    private var sent: some View {
        VStack(spacing: 0) {
            Circle().fill(Theme.positive).frame(width: 84, height: 84)
                .overlay(Image(systemName: "checkmark").font(.system(size: 36, weight: .bold)).foregroundStyle(.white))
                .padding(.top, 36)
            Text("Einladung gesendet").font(.serif(23)).foregroundStyle(Theme.fg).padding(.top, 22)
            Text("Sobald die Person beitritt, taucht sie in „\(group.name)“ auf.")
                .font(.system(size: 15)).foregroundStyle(Theme.fg2).multilineTextAlignment(.center).padding(.top, 8)
            Button { dismiss() } label: {
                Text("Fertig").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Theme.accent))
            }
            .padding(.top, 26)
        }
        .frame(maxWidth: .infinity)
    }
}

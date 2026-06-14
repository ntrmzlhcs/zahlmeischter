//
//  GroupDetailView.swift
//  zahlmeischter
//
//  A group's detail screen (design.md V2): a continuous-mesh page (no solid header
//  break) led by the Settle-Up "bubble" header — organic, overlapping glass bubbles
//  sized by each member's balance magnitude, "Du" in bright teal. Below: a glass
//  balance summary with Ausgabe / Ausgleichen, a per-member Salden list, and the
//  expenses grouped by date. A persistent Einladen button and a ⋯ menu live up top.
//

import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: ExpenseGroup
    let open: (AppRoute) -> Void
    let back: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var confirmDelete = false

    private var members: [Member] {
        (group.members ?? []).filter { $0.deletedAt == nil }.sorted { $0.createdAt < $1.createdAt }
    }
    private var me: Member? { members.first { $0.isCurrentUser } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBar
                titleBlock.padding(.top, 14)
                BubbleCanvas(group: group).padding(.top, 8)
                summaryCard.padding(.top, 6)
                saldenSection.padding(.top, 22)
                expensesSection.padding(.top, 22)
            }
            .padding(.horizontal, 18)
            .padding(.top, 60)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
        .background(.clear)
        .confirmationDialog("Gruppe löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { deleteGroup() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("„\(group.name)“ und alle Ausgaben darin werden gelöscht. Das kann nicht rückgängig gemacht werden.")
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            CircleGlassButton(systemName: "chevron.left", action: back)
            Spacer()
            Button { open(.sheet(.invite(group))) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                    Text("Einladen").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14).frame(height: 38)
                .background(Capsule().fill(.regularMaterial).overlay(Capsule().fill(Color.white.opacity(0.55))))
                .overlay(Capsule().strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            }
            Menu {
                Button { open(.sheet(.invite(group))) } label: { Label("Leute einladen", systemImage: "person.badge.plus") }
                Button(role: .destructive) { confirmDelete = true } label: { Label("Gruppe löschen", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.fg)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(.regularMaterial).overlay(Circle().fill(Color.white.opacity(0.55))))
                    .overlay(Circle().strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 2) {
            Text(group.name).font(.serif(26)).foregroundStyle(Theme.fg)
            Text("\(members.count) Mitglieder").font(.system(size: 13)).foregroundStyle(Theme.fg2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Summary

    private var summaryCard: some View {
        let lines: [BalanceDisplay.Line] = me.map {
            BalanceDisplay.linesOrSettled(GroupBalances.balance(of: $0, in: group), signed: true)
        } ?? []
        return VStack(alignment: .leading, spacing: 0) {
            Text("Dein Saldo in dieser Gruppe").font(.system(size: 13)).foregroundStyle(Theme.fg2)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    Text(line.text).font(.serif(30)).monospacedDigit().foregroundStyle(line.color)
                }
            }
            .padding(.top, 4)
            HStack(spacing: 10) {
                Button { open(.sheet(.addExpense(group))) } label: {
                    Label("Ausgabe", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 8, y: 6)
                }
                Button { open(.sheet(.settle(group))) } label: {
                    Text("Ausgleichen")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg)
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
                }
            }
            .padding(.top, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    // MARK: Salden

    private var saldenSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Salden")
            VStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.uuid) { index, member in
                    if index > 0 { Divider().overlay(Theme.line) }
                    memberRow(member)
                }
            }
            .glassCard(cornerRadius: 20)
        }
    }

    private func memberRow(_ member: Member) -> some View {
        let balance = GroupBalances.balance(of: member, in: group)
        let lines = BalanceDisplay.lines(balance, signed: true)
        return HStack(spacing: 12) {
            Avatar(member, in: group, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(member.isCurrentUser ? "Du" : member.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.fg)
                Text(statusLabel(for: balance, isMe: member.isCurrentUser)).font(.system(size: 12)).foregroundStyle(Theme.fg2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                if lines.isEmpty {
                    Text("ausgeglichen").font(.serif(15)).foregroundStyle(Theme.fg2)
                } else {
                    ForEach(lines) { line in
                        Text(line.text).font(.serif(15)).monospacedDigit().foregroundStyle(line.color)
                    }
                }
            }
        }
        .padding(.horizontal, 15).padding(.vertical, 13)
    }

    private func statusLabel(for balance: [CurrencyCode: Decimal], isMe: Bool) -> String {
        let values = balance.values.filter { abs($0) > 0.005 }
        if values.isEmpty { return "ausgeglichen" }
        if values.allSatisfy({ $0 > 0 }) { return isMe ? "dir wird geschuldet" : "bekommt zurück" }
        if values.allSatisfy({ $0 < 0 }) { return isMe ? "du schuldest" : "schuldet noch" }
        return "gemischter Saldo"
    }

    // MARK: Expenses

    private var expensesSection: some View {
        let days = expensesByDay()
        return VStack(alignment: .leading, spacing: 18) {
            SectionLabel("Ausgaben")
            if days.isEmpty {
                Text("Noch keine Ausgaben hier. Leg die erste an, sobald ihr etwas geteilt habt.")
                    .font(.system(size: 15)).foregroundStyle(Theme.fg2)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.vertical, 30)
            }
            ForEach(days, id: \.label) { day in
                VStack(alignment: .leading, spacing: 7) {
                    Text(day.label).font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.fg3).padding(.leading, 4)
                    VStack(spacing: 0) {
                        ForEach(Array(day.items.enumerated()), id: \.element.uuid) { index, expense in
                            if index > 0 { Divider().overlay(Theme.line) }
                            ExpenseRow(expense: expense, group: group) { open(.sheet(.expense(expense))) }
                        }
                    }
                    .glassCard(cornerRadius: 20)
                }
            }
        }
    }

    private func expensesByDay() -> [(label: String, items: [Expense])] {
        let expenses = (group.expenses ?? []).filter { $0.deletedAt == nil }.sorted { $0.date > $1.date }
        var order: [String] = []
        var buckets: [String: [Expense]] = [:]
        for expense in expenses {
            let label = DateDisplay.string(expense.date)
            if buckets[label] == nil { order.append(label) }
            buckets[label, default: []].append(expense)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    private func deleteGroup() {
        group.deletedAt = .now
        try? modelContext.save()
        back()
    }
}

// MARK: - Bubble header

private struct BubbleCanvas: View {
    let group: ExpenseGroup

    private static let anchors: [CGPoint] = [
        CGPoint(x: 0.30, y: 0.30), CGPoint(x: 0.70, y: 0.27), CGPoint(x: 0.52, y: 0.64),
        CGPoint(x: 0.19, y: 0.66), CGPoint(x: 0.82, y: 0.63), CGPoint(x: 0.45, y: 0.16),
    ]

    private var bubbles: [Bubble] {
        let members = (group.members ?? []).filter { $0.deletedAt == nil }
        let net = GroupBalances.net(for: group)
        let entries = members.map { member -> Bubble in
            var byCurrency: [CurrencyCode: Decimal] = [:]
            for (code, map) in net { if let v = map[member.uuid] { byCurrency[code] = v } }
            let magnitude = byCurrency.values.reduce(Decimal(0)) { $0 + abs($1) }
            return Bubble(member: member, byCurrency: byCurrency,
                          magnitude: NSDecimalNumber(decimal: magnitude).doubleValue)
        }
        .filter { $0.magnitude > 0.005 || $0.member.isCurrentUser }
        .sorted { $0.magnitude > $1.magnitude }
        return entries
    }

    var body: some View {
        let items = bubbles
        let maxMag = max(items.map(\.magnitude).max() ?? 1, 1)
        GeometryReader { geo in
            if items.allSatisfy({ $0.magnitude <= 0.005 }) {
                settledBubble.position(x: geo.size.width / 2, y: geo.size.height * 0.46)
            } else {
                ZStack {
                    ForEach(Array(items.prefix(6).enumerated()), id: \.element.member.uuid) { index, bubble in
                        let size = 74 + CGFloat(bubble.magnitude / maxMag) * 78
                        let anchor = Self.anchors[index % Self.anchors.count]
                        bubbleView(bubble, size: size)
                            .position(x: geo.size.width * anchor.x, y: geo.size.height * anchor.y)
                            .zIndex(bubble.member.isCurrentUser ? 10 : Double(6 - index))
                    }
                }
            }
        }
        .frame(height: 300)
    }

    private func bubbleView(_ bubble: Bubble, size: CGFloat) -> some View {
        let isMe = bubble.member.isCurrentUser
        let lines = BalanceDisplay.lines(bubble.byCurrency, signed: true)
        return VStack(spacing: 1) {
            Text(isMe ? "Du" : bubble.member.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isMe ? .white : Theme.fg)
            ForEach(lines.prefix(2).map { $0 }) { line in
                Text(line.text)
                    .font(.serif(13)).monospacedDigit()
                    .foregroundStyle(isMe ? .white : line.color)
            }
        }
        .frame(width: size, height: size)
        .background {
            if isMe {
                Circle().fill(RadialGradient(colors: [Color(hex: "3FD2C0"), Theme.accent],
                                             center: .init(x: 0.34, y: 0.28), startRadius: 2, endRadius: size))
            } else {
                Circle().fill(.ultraThinMaterial)
                    .overlay(Circle().fill(MemberStyle.color(for: bubble.member, in: group).opacity(0.16)))
            }
        }
        .overlay(Circle().strokeBorder(isMe ? Color.white.opacity(0.7) : Theme.glassBorder, lineWidth: isMe ? 1.5 : 0.5))
        .shadow(color: Color(hex: "0F463E").opacity(0.26), radius: 16, y: 12)
    }

    private var settledBubble: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark").font(.system(size: 30, weight: .bold)).foregroundStyle(Color(hex: "06403A"))
            Text("Alles ausgeglichen").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "06403A"))
        }
        .frame(width: 168, height: 168)
        .background(Circle().fill(RadialGradient(colors: [Color(hex: "78E0D2"), Color(hex: "0F9680")],
                                                 center: .init(x: 0.34, y: 0.28), startRadius: 2, endRadius: 168)))
        .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5))
        .shadow(color: Color(hex: "0F463E").opacity(0.26), radius: 16, y: 12)
    }

    private struct Bubble {
        let member: Member
        let byCurrency: [CurrencyCode: Decimal]
        let magnitude: Double
    }
}

//
//  SettleUpView.swift
//  zahlmeischter
//
//  Settle-up (design.md V2): the fewest payments that clear the group, computed
//  **per currency** (never mixed). Confirming records the settlements and plays a
//  papercraft completion micro-interaction (expanding ring + morphing checkmark).
//

import SwiftUI
import SwiftData

struct SettleUpView: View {
    let group: ExpenseGroup
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var done = false
    @State private var ringExpanded = false
    @State private var checkShown = false

    private var transactions: [(currency: CurrencyCode, tx: DebtSimplifier.Transaction)] {
        GroupBalances.settlement(for: group)
    }
    private func member(_ id: UUID) -> Member? {
        (group.members ?? []).first { $0.uuid == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Ausgleichen", leading: "Schliessen", onLeading: { dismiss() })
            if done {
                completion
            } else if transactions.isEmpty {
                Text("In dieser Gruppe ist bereits alles ausgeglichen. Nichts zu tun.")
                    .font(.system(size: 15)).foregroundStyle(Theme.fg2)
                    .multilineTextAlignment(.center).padding(.vertical, 50)
            } else {
                planList
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 32)
        .sheetStyle()
    }

    private var planList: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Mit so wenigen Zahlungen wie möglich").font(.system(size: 14)).foregroundStyle(Theme.fg2)
                Text(headline).font(.serif(20, weight: .medium)).foregroundStyle(Theme.fg).multilineTextAlignment(.center)
            }
            .padding(20).frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.glass2))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            .padding(.top, 6)

            VStack(spacing: 10) {
                ForEach(Array(transactions.enumerated()), id: \.offset) { _, entry in
                    txRow(entry)
                }
            }
            .padding(.top, 14)

            Button(action: confirm) {
                Text("Ausgleich bestätigen")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 10, y: 8)
            }
            .padding(.top, 18)
        }
    }

    private func txRow(_ entry: (currency: CurrencyCode, tx: DebtSimplifier.Transaction)) -> some View {
        let from = member(entry.tx.from)
        let to = member(entry.tx.to)
        return HStack(spacing: 12) {
            if let from { Avatar(from, in: group, size: 34) }
            Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.fg2)
            if let to { Avatar(to, in: group, size: 34) }
            Text("\(name(from)) zahlt \(name(to))").font(.system(size: 14)).foregroundStyle(Theme.fg2).lineLimit(1)
            Spacer()
            Text(CurrencyFormatting.string(entry.tx.amount, code: entry.currency))
                .font(.serif(16)).monospacedDigit().foregroundStyle(Theme.fg)
        }
        .padding(.horizontal, 15).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
    }

    private var completion: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Theme.positive.opacity(0.25))
                    .frame(width: 96, height: 96)
                    .scaleEffect(ringExpanded ? 1.5 : 0.4)
                    .opacity(ringExpanded ? 0 : 0.7)
                Circle().fill(Theme.positive).frame(width: 96, height: 96)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 40, weight: .bold)).foregroundStyle(.white))
                    .scaleEffect(checkShown ? 1 : 0)
            }
            .padding(.top, 40)
            Text("Alles ausgeglichen").font(.serif(24)).foregroundStyle(Theme.fg).padding(.top, 24)
            Text("Die Zahlungen wurden vermerkt. Eure Salden sind ausgeglichen.")
                .font(.system(size: 15)).foregroundStyle(Theme.fg2).multilineTextAlignment(.center).padding(.top, 8)
            Button { dismiss() } label: {
                Text("Fertig").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Theme.accent))
            }
            .padding(.top, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { checkShown = true }
            withAnimation(.easeOut(duration: 1)) { ringExpanded = true }
        }
    }

    private var headline: String {
        let count = transactions.count
        return count == 1 ? "Eine Zahlung gleicht alles aus." : "\(count) Zahlungen gleichen alles aus."
    }

    private func name(_ member: Member?) -> String {
        guard let member else { return "—" }
        return member.isCurrentUser ? "Du" : member.name
    }

    private func confirm() {
        for entry in transactions {
            let settlement = Settlement(amount: entry.tx.amount, currency: entry.currency)
            settlement.group = group
            settlement.fromMember = member(entry.tx.from)
            settlement.toMember = member(entry.tx.to)
            modelContext.insert(settlement)
        }
        try? modelContext.save()
        withAnimation { done = true }
    }
}

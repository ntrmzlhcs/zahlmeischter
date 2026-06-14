//
//  ExpenseDetailView.swift
//  zahlmeischter
//
//  A presented expense: its amount in New York, the split breakdown, and a delete
//  action (with confirm) that soft-deletes the expense for everyone in the group.
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    let expense: Expense
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmDelete = false

    private var category: String { ExpenseCategory.inferred(expense) }

    private var splits: [ExpenseSplit] {
        (expense.splits ?? []).filter { $0.deletedAt == nil }
            .sorted { ($0.member?.createdAt ?? .now) < ($1.member?.createdAt ?? .now) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Ausgabe", leading: "Schliessen", onLeading: { dismiss() })

            VStack(spacing: 4) {
                CategoryIcon(category: category, size: 56, corner: 16)
                Text(expense.title).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.fg).padding(.top, 8)
                Text(CurrencyFormatting.string(expense.amount, code: expense.currency))
                    .font(.serif(38)).monospacedDigit().foregroundStyle(Theme.fg)
                Text(metaLine).font(.system(size: 13)).foregroundStyle(Theme.fg2)
            }
            .padding(.top, 12)

            SectionLabel("Aufteilung").padding(.top, 22).frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(splits.enumerated()), id: \.element.uuid) { index, split in
                    if index > 0 { Divider().overlay(Theme.line) }
                    HStack(spacing: 12) {
                        if let member = split.member { Avatar(member, in: expense.group, size: 32) }
                        Text(splitName(split)).font(.system(size: 15)).foregroundStyle(Theme.fg)
                        Spacer()
                        Text(CurrencyFormatting.amountString(split.shareAmount))
                            .font(.serif(15)).monospacedDigit().foregroundStyle(Theme.fg2)
                    }
                    .padding(.horizontal, 15).padding(.vertical, 12)
                }
            }
            .glassCard(cornerRadius: 16, fill: Theme.glass2, shadow: false)

            Button { confirmDelete = true } label: {
                Label("Ausgabe löschen", systemImage: "trash")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Theme.negative.opacity(0.14)))
            }
            .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 30)
        .sheetStyle()
        .confirmationDialog("Ausgabe löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { delete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("„\(expense.title)“ wird für alle in der Gruppe entfernt.")
        }
    }

    private var metaLine: String {
        let payer = expense.payer?.isCurrentUser == true ? "Du" : (expense.payer?.name ?? "—")
        return "\(payer) · \(DateDisplay.string(expense.date))"
    }

    private func splitName(_ split: ExpenseSplit) -> String {
        guard let member = split.member else { return "—" }
        return member.isCurrentUser ? "Du" : member.name
    }

    private func delete() {
        expense.deletedAt = .now
        try? modelContext.save()
        dismiss()
    }
}

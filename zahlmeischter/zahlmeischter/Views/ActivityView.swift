//
//  ActivityView.swift
//  zahlmeischter
//
//  The Aktivität tab: every expense across all groups, grouped by date (dd.MM.yyyy),
//  in glass cards over the mesh.
//

import SwiftUI
import SwiftData

struct ActivityView: View {
    let open: (AppRoute) -> Void

    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    private var expenses: [Expense] {
        allExpenses.filter { $0.deletedAt == nil && ($0.group?.deletedAt == nil) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Aktivität").font(.serif(30)).foregroundStyle(Theme.fg)

                if expenses.isEmpty {
                    Text("Noch keine Ausgaben hier. Leg die erste an, sobald ihr etwas geteilt habt.")
                        .font(.system(size: 15)).foregroundStyle(Theme.fg2)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 70)
                }

                ForEach(days, id: \.label) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.label).font(.system(size: 13)).monospacedDigit().foregroundStyle(Theme.fg2).padding(.leading, 4)
                        VStack(spacing: 0) {
                            ForEach(Array(day.items.enumerated()), id: \.element.uuid) { index, expense in
                                if index > 0 { Divider().overlay(Theme.line) }
                                if let group = expense.group {
                                    ExpenseRow(expense: expense, group: group) { open(.sheet(.expense(expense))) }
                                }
                            }
                        }
                        .glassCard(cornerRadius: 22)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
    }

    private var days: [(label: String, items: [Expense])] {
        var order: [String] = []
        var buckets: [String: [Expense]] = [:]
        for expense in expenses {
            let label = DateDisplay.string(expense.date)
            if buckets[label] == nil { order.append(label) }
            buckets[label, default: []].append(expense)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }
}

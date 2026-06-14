//
//  PickGroupView.swift
//  zahlmeischter
//
//  Shown when tapping + on the dashboard with more than one group: pick which group
//  the new expense belongs to, then continue to the Add-Expense sheet.
//

import SwiftUI

struct PickGroupView: View {
    let groups: [ExpenseGroup]
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Gruppe wählen", onLeading: { dismiss() })
            Text("Für welche Gruppe ist diese Ausgabe?")
                .font(.system(size: 14)).foregroundStyle(Theme.fg2)
                .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 2)

            VStack(spacing: 10) {
                ForEach(Array(groups.enumerated()), id: \.element.uuid) { index, group in
                    Button {
                        open(.sheet(.addExpense(group)))
                    } label: {
                        HStack(spacing: 13) {
                            RoundedRectangle(cornerRadius: 13).fill(Theme.groupTint(index))
                                .frame(width: 44, height: 44)
                                .overlay(Image(systemName: "person.2.fill").font(.system(size: 16)).foregroundStyle(.white))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(group.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.fg).lineLimit(1)
                                Text("\((group.members ?? []).filter { $0.deletedAt == nil }.count) Mitglieder")
                                    .font(.system(size: 13)).foregroundStyle(Theme.fg2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.fg3)
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 18, shadow: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)

            Button { open(.sheet(.newGroup)) } label: {
                Label("Neue Gruppe", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Theme.glass2))
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            }
            .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 34)
        .sheetStyle()
    }
}

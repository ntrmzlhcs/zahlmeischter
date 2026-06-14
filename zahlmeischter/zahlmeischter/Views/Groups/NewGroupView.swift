//
//  NewGroupView.swift
//  zahlmeischter
//
//  Create a group: a single inline-checkmark name field (no group currency in V2),
//  then seed the current user as the first member and open the new group.
//

import SwiftUI
import SwiftData

struct NewGroupView: View {
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var name = ""

    private var canCreate: Bool { !name.trimmed.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Neue Gruppe", onLeading: { dismiss() },
                        trailing: "Erstellen", trailingEnabled: canCreate, onTrailing: create)
            InlineCheckmarkField(label: "Gruppenname", text: $name)
                .padding(.top, 20)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 40)
        .sheetStyle()
    }

    private func create() {
        guard canCreate else { return }
        let group = ExpenseGroup(name: name.trimmed)
        modelContext.insert(group)
        let me = Member(name: appState.myName.trimmed.isEmpty ? "Du" : appState.myName.trimmed, isCurrentUser: true)
        me.group = group
        modelContext.insert(me)
        try? modelContext.save()
        appState.activeGroup = group
        dismiss()
        open(.group(group))
    }
}

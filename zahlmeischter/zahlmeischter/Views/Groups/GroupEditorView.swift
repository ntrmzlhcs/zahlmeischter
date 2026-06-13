//
//  GroupEditorView.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI
import SwiftData

/// Creates a new `ExpenseGroup` — name, default currency, and members — presented as a
/// glass sheet over the mesh gradient.
///
/// The first member is **you** (`isCurrentUser`), pre-filled from the remembered name in
/// `AppState`; further members are local placeholder/ghost participants (real iCloud
/// participants arrive with the CKShare sharing milestone). On save the new group becomes
/// the active group.
struct GroupEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var currency: CurrencyCode = .chf
    @State private var yourName = ""
    @State private var otherMembers: [MemberDraft] = []
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case groupName, yourName, member(UUID)
    }

    /// A transient, editable member row before it's committed to a `Member` on save.
    private struct MemberDraft: Identifiable {
        let id = UUID()
        var name = ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        FormFieldCard(label: "Gruppenname") {
                            TextField("", text: $name)
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .groupName)
                                .accessibilityLabel(Text("Gruppenname"))
                        }

                        FormFieldCard(label: "Währung") {
                            Picker("Währung", selection: $currency) {
                                ForEach(CurrencyCode.allCases) { code in
                                    Text(code.isoCode).tag(code)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        membersCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Neue Gruppe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { yourName = appState.myName }
        }
    }

    // MARK: - Members

    private var membersCard: some View {
        FormFieldCard(label: "Mitglieder") {
            VStack(spacing: 14) {
                memberRow(badge: initial(yourName)) {
                    TextField("", text: $yourName)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .yourName)
                        .accessibilityLabel(Text("Dein Name"))
                } trailing: {
                    Text("Du")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach($otherMembers) { $member in
                    memberRow(badge: initial(member.name)) {
                        TextField("", text: $member.name)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .member(member.id))
                            .accessibilityLabel(Text("Name des Mitglieds"))
                    } trailing: {
                        Button {
                            otherMembers.removeAll { $0.id == member.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Mitglied entfernen"))
                    }
                }

                Button {
                    let draft = MemberDraft()
                    otherMembers.append(draft)
                    focusedField = .member(draft.id)
                } label: {
                    Label("Mitglied hinzufügen", systemImage: "plus.circle.fill")
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }
        }
    }

    private func memberRow<Editor: View, Trailing: View>(
        badge: String,
        @ViewBuilder editor: () -> Editor,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Text(badge)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: .circle)
            editor()
            trailing()
        }
    }

    private func initial(_ name: String) -> String {
        name.trimmed.first.map { String($0).uppercased() } ?? "?"
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Abbrechen") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Speichern") { save() }
                .disabled(!canSave)
        }
        // design.md: confirm/cancel live in the keyboard accessory bar (never floating
        // circular buttons); they also stay in the nav bar for when the keyboard is down.
        ToolbarItemGroup(placement: .keyboard) {
            Button("Abbrechen") { dismiss() }
            Spacer()
            Button("Fertig") { focusedField = nil }
                .fontWeight(.semibold)
        }
    }

    // MARK: - Persistence

    private var canSave: Bool {
        !name.trimmed.isEmpty && !yourName.trimmed.isEmpty
    }

    private func save() {
        guard canSave else { return }

        let group = ExpenseGroup(name: name.trimmed, currency: currency)
        modelContext.insert(group)

        let me = Member(name: yourName.trimmed, isCurrentUser: true)
        me.group = group
        modelContext.insert(me)

        for draft in otherMembers {
            let memberName = draft.name.trimmed
            guard !memberName.isEmpty else { continue }
            let member = Member(name: memberName)
            member.group = group
            modelContext.insert(member)
        }

        appState.myName = yourName.trimmed
        appState.activeGroup = group
        dismiss()
    }
}

#Preview {
    GroupEditorView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview)
}

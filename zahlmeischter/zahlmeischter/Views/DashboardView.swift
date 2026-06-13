//
//  DashboardView.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI
import SwiftData

/// The app's hero screen and root. Over the breathing "Cool Premium" mesh gradient it
/// shows your total balance in New York (serif, the only Display-role text) and a stack of
/// Liquid Glass member balance cards, plus a compact list of recent expenses.
///
/// The nav-bar title doubles as a **group switcher** (`toolbarTitleMenu`) that also creates
/// a new group; the trailing "+" adds an expense to the active group. Before any group
/// exists it presents a first-run state. All figures read live SwiftData via `AppState`.
struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ExpenseGroup.createdAt, order: .reverse) private var allGroups: [ExpenseGroup]

    @State private var showingGroupEditor = false
    @State private var showingExpenseEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                content
            }
            .navigationTitle(appState.activeGroup?.name ?? "zahlmeischter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu { groupMenu }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingExpenseEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("Ausgabe hinzufügen"))
                    .disabled(appState.activeGroup == nil)
                }
            }
            .sheet(isPresented: $showingGroupEditor) {
                GroupEditorView()
            }
            .sheet(isPresented: $showingExpenseEditor) {
                if let group = appState.activeGroup {
                    ExpenseEditorView(group: group)
                }
            }
            .onAppear {
                if appState.activeGroup == nil {
                    appState.activeGroup = groups.first
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if groups.isEmpty {
            firstRunState
        } else {
            ScrollView {
                VStack(spacing: 36) {
                    heroSection
                    memberSection
                    if recentExpenses.isEmpty {
                        expensesEmptyState
                    } else {
                        recentSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Group switcher menu

    @ViewBuilder
    private var groupMenu: some View {
        ForEach(groups) { group in
            Button {
                appState.activeGroup = group
            } label: {
                if group.uuid == appState.activeGroup?.uuid {
                    Label(group.name, systemImage: "checkmark")
                } else {
                    Text(group.name)
                }
            }
        }
        if !groups.isEmpty {
            Divider()
        }
        Button {
            showingGroupEditor = true
        } label: {
            Label("Neue Gruppe", systemImage: "plus")
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 10) {
            Text("Dein Saldo")
                .font(.footnote)
                .fontWeight(.medium)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatting.string(heroBalance, code: groupCurrency))
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Member balances

    @ViewBuilder
    private var memberSection: some View {
        if !cardMembers.isEmpty {
            GlassEffectContainer(spacing: 16) {
                LazyVStack(spacing: 16) {
                    ForEach(cardMembers) { member in
                        BalanceCard(
                            memberName: member.name,
                            balance: netBalance(for: member),
                            currency: groupCurrency
                        )
                    }
                }
            }
        }
    }

    // MARK: - Recent expenses

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte Ausgaben")
                .font(.headline)
                .foregroundStyle(.secondary)

            GlassEffectContainer(spacing: 10) {
                LazyVStack(spacing: 10) {
                    ForEach(recentExpenses) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(expenseSubtitle(expense))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(CurrencyFormatting.string(expense.amount, code: expense.currency))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Empty states

    private var firstRunState: some View {
        VStack(spacing: 20) {
            // Placeholder for the future papercraft onboarding illustration (design.md).
            Image(systemName: "person.2.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Willkommen")
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Erstelle deine erste Gruppe, um Ausgaben zu teilen.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingGroupEditor = true
            } label: {
                Text("Erste Gruppe erstellen")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: 340)
        .glassEffect(in: .rect(cornerRadius: 28))
        .padding(20)
    }

    private var expensesEmptyState: some View {
        VStack(spacing: 14) {
            // Placeholder for the future papercraft empty-state illustration (design.md).
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text("Noch keine Ausgaben hier. Leg die erste an, sobald ihr etwas geteilt habt.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 28))
    }

    // MARK: - Data seams

    /// Net group balance for `member`: total they paid minus the sum of their split shares,
    /// over the active group's non-deleted expenses **in the group's currency** (mixed-
    /// currency aggregation awaits exchange rates — out of scope). Positive ⇒ ahead.
    private func netBalance(for member: Member) -> Decimal {
        var paid: Decimal = 0
        var owed: Decimal = 0
        for expense in sameCurrencyExpenses {
            if expense.payer?.uuid == member.uuid {
                paid += expense.amount
            }
            for split in expense.splits ?? [] where split.deletedAt == nil {
                if split.member?.uuid == member.uuid {
                    owed += split.shareAmount
                }
            }
        }
        return paid - owed
    }

    /// The hero figure: your own net group balance (zero if the group has no current user).
    private var heroBalance: Decimal {
        guard let me = appState.currentMember(in: appState.activeGroup) else { return 0 }
        return netBalance(for: me)
    }

    private func expenseSubtitle(_ expense: Expense) -> String {
        let dateString = Self.dateFormatter.string(from: expense.date)
        if let payer = expense.payer?.name, !payer.isEmpty {
            return "\(payer) · \(dateString)"
        }
        return dateString
    }

    private var groupCurrency: CurrencyCode {
        appState.activeGroup?.currency ?? .chf
    }

    /// Non-deleted groups, newest first (the query is already reverse-sorted by `createdAt`).
    private var groups: [ExpenseGroup] {
        allGroups.filter { $0.deletedAt == nil }
    }

    /// Active group's members minus tombstones.
    private var members: [Member] {
        (appState.activeGroup?.members ?? []).filter { $0.deletedAt == nil }
    }

    /// Members shown as balance cards — everyone except you (your figure is the hero).
    private var cardMembers: [Member] {
        members
            .filter { !$0.isCurrentUser }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var activeExpenses: [Expense] {
        (appState.activeGroup?.expenses ?? []).filter { $0.deletedAt == nil }
    }

    private var sameCurrencyExpenses: [Expense] {
        activeExpenses.filter { $0.currency == groupCurrency }
    }

    private var recentExpenses: [Expense] {
        activeExpenses.sorted { $0.date > $1.date }
    }

    /// Swiss date display (`dd.MM.yyyy`), pinned to `de_CH` regardless of device locale.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}

#Preview {
    DashboardView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview)
}

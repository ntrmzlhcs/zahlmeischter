//
//  RootView.swift
//  zahlmeischter
//
//  The app shell (design.md V2): a single continuous mesh with the tab content
//  floating over it, a floating glass tab bar (Übersicht · [+] · Aktivität) carrying
//  a raised teal FAB, and a coordinator for the group-detail push and the modal sheets.
//  Profil is reached from the avatar in the dashboard header.
//

import SwiftUI
import SwiftData

/// Which modal sheet is presented. Group-scoped cases carry their group.
enum AppSheet: Identifiable {
    case newGroup
    case pickGroup
    case addExpense(ExpenseGroup)
    case settle(ExpenseGroup)
    case invite(ExpenseGroup)
    case ocr(ExpenseGroup)
    case expense(Expense)

    var id: String {
        switch self {
        case .newGroup: "newGroup"
        case .pickGroup: "pickGroup"
        case .addExpense(let g): "add-\(g.uuid)"
        case .settle(let g): "settle-\(g.uuid)"
        case .invite(let g): "invite-\(g.uuid)"
        case .ocr(let g): "ocr-\(g.uuid)"
        case .expense(let e): "expense-\(e.uuid)"
        }
    }
}

struct RootView: View {
    var replayOnboarding: () -> Void = {}
    var replayLaunch: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseGroup.createdAt, order: .reverse) private var allGroups: [ExpenseGroup]

    enum Tab { case overview, activity, profile }
    @State private var tab: Tab = .overview
    @State private var path: [ExpenseGroup] = []
    @State private var sheet: AppSheet?
    @State private var didSeed = false

    private var groups: [ExpenseGroup] { allGroups.filter { $0.deletedAt == nil } }
    private var inGroupDetail: Bool { !path.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            MeshGradientBackground()

            NavigationStack(path: $path) {
                tabRoot
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: ExpenseGroup.self) { group in
                        GroupDetailView(group: group, open: open, back: { path.removeLast() })
                            .toolbar(.hidden, for: .navigationBar)
                    }
            }

            if !inGroupDetail {
                TabBar(tab: $tab, onAdd: addTapped)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .tint(Theme.accent)
        .sheet(item: $sheet) { sheetContent($0) }
        .task { seedIfNeeded() }
    }

    // MARK: Tabs

    @ViewBuilder private var tabRoot: some View {
        switch tab {
        case .overview:
            DashboardView(open: open, goProfile: { tab = .profile })
        case .activity:
            ActivityView(open: open)
        case .profile:
            ProfileView(replayOnboarding: replayOnboarding, replayLaunch: replayLaunch)
        }
    }

    // MARK: Coordinator

    /// Single entry point the screens use to navigate / present.
    func open(_ route: AppRoute) {
        switch route {
        case .group(let g):
            appState.activeGroup = g
            path = [g]
        case .sheet(let s):
            sheet = s
        case .closeSheet:
            sheet = nil
        }
    }

    private func addTapped() {
        if let active = path.last {
            sheet = .addExpense(active)
        } else if groups.count <= 1, let only = groups.first {
            sheet = .addExpense(only)
        } else if groups.isEmpty {
            sheet = .newGroup
        } else {
            sheet = .pickGroup
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .newGroup:
            NewGroupView(open: open)
        case .pickGroup:
            PickGroupView(groups: groups, open: open)
        case .addExpense(let group):
            AddExpenseView(group: group, open: open)
        case .settle(let group):
            SettleUpView(group: group, open: open)
        case .invite(let group):
            InviteView(group: group, open: open)
        case .ocr(let group):
            ReceiptScannerView(group: group, open: open)
        case .expense(let expense):
            ExpenseDetailView(expense: expense, open: open)
        }
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        if let first = SampleData.seedIfEmpty(modelContext, myName: appState.myName) {
            appState.activeGroup = first
        }
    }
}

/// Navigation/presentation intents the screens hand back to `RootView`.
enum AppRoute {
    case group(ExpenseGroup)
    case sheet(AppSheet)
    case closeSheet
}

// MARK: - Floating glass tab bar

private struct TabBar: View {
    @Binding var tab: RootView.Tab
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.overview, system: "house", label: "Übersicht")
            Button(action: onAdd) {
                ZStack {
                    Circle().fill(Theme.accent)
                        .frame(width: 50, height: 50)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 12, y: 8)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .offset(y: -14)
            }
            .frame(width: 60)
            item(.activity, system: "chart.line.uptrend.xyaxis", label: "Aktivität")
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .background {
            Capsule().fill(.regularMaterial)
                .overlay(Capsule().fill(Theme.nav))
                .overlay(Capsule().strokeBorder(Theme.glassBorder, lineWidth: 0.5))
        }
        .shadow(color: Color(hex: "122E2A").opacity(0.2), radius: 17, y: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func item(_ which: RootView.Tab, system: String, label: String) -> some View {
        Button {
            tab = which
        } label: {
            VStack(spacing: 3) {
                Image(systemName: system).font(.system(size: 20, weight: .medium))
                Text(label).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(tab == which ? Theme.accent : Theme.fg2)
            .frame(maxWidth: .infinity)
        }
    }
}

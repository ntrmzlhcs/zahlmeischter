//
//  DashboardView.swift
//  zahlmeischter
//
//  The Übersicht tab (design.md V2): greeting + editorial "Übersicht" title, a glass
//  hero card showing the user's total balance **per currency** (never aggregated),
//  "dir geschuldet" / "du schuldest" wells, a monthly-spending bar chart that draws on
//  with a stagger, and the list of groups. Everything floats over the universal mesh.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    let open: (AppRoute) -> Void
    let goProfile: () -> Void

    @Environment(AppState.self) private var appState
    @Query(sort: \ExpenseGroup.createdAt, order: .reverse) private var allGroups: [ExpenseGroup]

    private var groups: [ExpenseGroup] { allGroups.filter { $0.deletedAt == nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                heroCard.padding(.top, 20)
                ChartCard(bars: monthlyBars()).padding(.top, 16)
                groupsSection.padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting).font(.system(size: 14)).foregroundStyle(Theme.fg2)
                Text("Übersicht").font(.serif(30)).foregroundStyle(Theme.fg)
            }
            Spacer()
            Button(action: goProfile) {
                Circle().fill(Theme.accent)
                    .frame(width: 42, height: 42)
                    .overlay(Text("Du").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white))
                    .shadow(color: Theme.accent.opacity(0.4), radius: 8, y: 6)
            }
        }
    }

    private var greeting: String {
        let name = appState.myName.trimmed
        return name.isEmpty ? "Willkommen" : "Hallo \(name)"
    }

    // MARK: Hero

    private var heroCard: some View {
        let total = totalBalance()
        let heroLines = BalanceDisplay.linesOrSettled(total, signed: true)
        var owed: [CurrencyCode: Decimal] = [:]
        var owe: [CurrencyCode: Decimal] = [:]
        for (code, value) in total {
            if value > 0.005 { owed[code] = value } else if value < -0.005 { owe[code] = -value }
        }
        return VStack(alignment: .leading, spacing: 0) {
            Text("Gesamtsaldo").font(.system(size: 13)).foregroundStyle(Theme.fg2)
            VStack(alignment: .leading, spacing: 1) {
                ForEach(heroLines) { line in
                    Text(line.text)
                        .font(.serif(34)).monospacedDigit()
                        .foregroundStyle(line.color)
                }
            }
            .padding(.top, 8)
            Text(heroSubtitle(total)).font(.system(size: 14)).foregroundStyle(Theme.fg2).padding(.top, 10)
            HStack(spacing: 10) {
                miniWell(title: "dir geschuldet", lines: BalanceDisplay.lines(owed), color: Theme.positive)
                miniWell(title: "du schuldest", lines: BalanceDisplay.lines(owe), color: Theme.negative)
            }
            .padding(.top, 16)
        }
        .padding(EdgeInsets(top: 24, leading: 22, bottom: 24, trailing: 22))
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 28)
    }

    private func miniWell(title: String, lines: [BalanceDisplay.Line], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 12)).foregroundStyle(Theme.fg2)
            if lines.isEmpty {
                Text("—").font(.serif(16)).foregroundStyle(Theme.fg3)
            } else {
                ForEach(lines) { line in
                    Text(line.text).font(.serif(16)).monospacedDigit().foregroundStyle(color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
    }

    private func heroSubtitle(_ total: [CurrencyCode: Decimal]) -> String {
        if total.values.allSatisfy({ abs($0) <= 0.005 }) {
            return "Alles ausgeglichen über deine Gruppen."
        }
        return "Über alle Gruppen, pro Währung getrennt."
    }

    // MARK: Groups

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Gruppen").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.fg)
                Spacer()
                Button { open(.sheet(.newGroup)) } label: {
                    Text("+ Neu").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            VStack(spacing: 12) {
                ForEach(Array(groups.enumerated()), id: \.element.uuid) { index, group in
                    Button { open(.group(group)) } label: {
                        GroupCard(group: group, tintIndex: index)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Computations

    /// The user's net balance per currency, summed across every group.
    private func totalBalance() -> [CurrencyCode: Decimal] {
        var total: [CurrencyCode: Decimal] = [:]
        for group in groups {
            guard let me = group.members?.first(where: { $0.isCurrentUser && $0.deletedAt == nil }) else { continue }
            for (code, value) in GroupBalances.balance(of: me, in: group) {
                total[code, default: 0] += value
            }
        }
        return total.filter { abs($0.value) > 0.005 }
    }

    /// Trailing-6-month spending totals (amounts summed regardless of currency — a
    /// representative activity sparkline, as in the prototype).
    private func monthlyBars() -> [ChartCard.Bar] {
        let calendar = Calendar(identifier: .gregorian)
        let abbreviations = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]
        let allExpenses: [Expense] = groups.flatMap { $0.expenses ?? [] }
        let dates: [Date] = allExpenses.filter { $0.deletedAt == nil }.map { $0.date }
        let reference: Date = dates.max() ?? Date.now
        var months: [(year: Int, month: Int)] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .month, value: -offset, to: reference) {
                let comps = calendar.dateComponents([.year, .month], from: date)
                months.append((comps.year ?? 0, comps.month ?? 1))
            }
        }
        var totals: [String: Double] = [:]
        for group in groups {
            for expense in (group.expenses ?? []) where expense.deletedAt == nil {
                let comps = calendar.dateComponents([.year, .month], from: expense.date)
                let key = "\(comps.year ?? 0)-\(comps.month ?? 0)"
                totals[key, default: 0] += NSDecimalNumber(decimal: expense.amount).doubleValue
            }
        }
        return months.map { ym in
            ChartCard.Bar(label: abbreviations[(ym.month - 1) % 12],
                          value: totals["\(ym.year)-\(ym.month)"] ?? 0)
        }
    }
}

// MARK: - Group card

private struct GroupCard: View {
    let group: ExpenseGroup
    let tintIndex: Int

    private var members: [Member] {
        (group.members ?? []).filter { $0.deletedAt == nil }.sorted { $0.createdAt < $1.createdAt }
    }
    private var expenseCount: Int { (group.expenses ?? []).filter { $0.deletedAt == nil }.count }

    private var netLines: [BalanceDisplay.Line] {
        guard let me = members.first(where: { $0.isCurrentUser }) else { return [] }
        return BalanceDisplay.lines(GroupBalances.balance(of: me, in: group), signed: true)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.groupTint(tintIndex))
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "person.2.fill").font(.system(size: 17)).foregroundStyle(.white))
                    .shadow(color: Color(hex: "122E2A").opacity(0.18), radius: 6, y: 4)
                VStack(alignment: .leading, spacing: 1) {
                    Text(group.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.fg).lineLimit(1)
                    Text("\(members.count) Mitglieder · \(expenseCount) Ausgaben")
                        .font(.system(size: 13)).foregroundStyle(Theme.fg2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("dein Saldo").font(.system(size: 11)).foregroundStyle(Theme.fg2)
                    if netLines.isEmpty {
                        Text("ausgeglichen").font(.serif(15)).foregroundStyle(Theme.fg2)
                    } else {
                        ForEach(netLines) { line in
                            Text(line.text).font(.serif(15)).monospacedDigit().foregroundStyle(line.color)
                        }
                    }
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(members.prefix(5).enumerated()), id: \.element.uuid) { index, member in
                    Avatar(member, in: group, size: 27, ringColor: Theme.solid)
                        .padding(.leading, index == 0 ? 0 : -7)
                }
                Spacer()
            }
            .padding(.top, 13)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }
}

// MARK: - Monthly bar chart

struct ChartCard: View {
    struct Bar: Identifiable { let id = UUID(); let label: String; let value: Double }
    let bars: [Bar]

    @State private var grown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maxValue: Double { max(bars.map(\.value).max() ?? 1, 1) }
    private var total: Double { bars.reduce(0) { $0 + $1.value } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ausgaben pro Monat").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg)
                Spacer()
                Text(CurrencyFormatting.amountString(Decimal(total)))
                    .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.fg2)
            }
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    VStack(spacing: 7) {
                        Spacer(minLength: 0)
                        Text(shortValue(bar.value)).font(.system(size: 10)).monospacedDigit().foregroundStyle(Theme.fg3)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(LinearGradient(colors: [Theme.accent, Color(hex: "5BD2C4")],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: barHeight(bar.value))
                            .scaleEffect(y: grown ? 1 : 0, anchor: .bottom)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(Double(index) * 0.08), value: grown)
                        Text(bar.label).font(.system(size: 11)).foregroundStyle(Theme.fg2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
            .padding(.top, 18)
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
        .onAppear { grown = reduceMotion ? true : false; if !reduceMotion { grown = true } }
    }

    private func barHeight(_ value: Double) -> CGFloat {
        max(CGFloat(value / maxValue) * 84, value > 0 ? 6 : 2)
    }

    private func shortValue(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fk", value / 1000) : String(Int(value))
    }
}

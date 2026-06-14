//
//  SampleData.swift
//  zahlmeischter
//
//  Seeds the three demo groups from the prototype (Mallorca / WG / Berlin) with
//  members and per-currency expenses, so a fresh install opens onto a populated app
//  that mirrors the design prototype rather than the empty state. Idempotent: only
//  seeds when the store has no groups.
//

import Foundation
import SwiftData

@MainActor
enum SampleData {

    /// Inserts the demo data once, if the container is empty. Returns the group that
    /// should be focused first (Mallorca), or `nil` if data already existed.
    @discardableResult
    static func seedIfEmpty(_ context: ModelContext, myName: String) -> ExpenseGroup? {
        let existing = (try? context.fetch(FetchDescriptor<ExpenseGroup>())) ?? []
        guard existing.filter({ $0.deletedAt == nil }).isEmpty else { return nil }

        let me = { Member(name: myName.isEmpty ? "Du" : myName, isCurrentUser: true) }
        let you = me()

        // Members reused across groups are distinct rows per group (V1 has no cross-group identity).
        func member(_ name: String) -> Member { Member(name: name) }

        var first: ExpenseGroup?

        // Mallorca 2026 — CHF + EUR mixed.
        do {
            let lisa = member("Lisa"), jonas = member("Jonas"), sara = member("Sara")
            let group = makeGroup("Mallorca 2026", members: [you, lisa, jonas, sara], context: context)
            add(group, "Ferienwohnung", 1200, .chf, payer: you,   cat: "Unterkunft",   day: "2026-05-02", context: context)
            add(group, "Mietwagen",     480,  .eur, payer: lisa,  cat: "Transport",    day: "2026-05-02", context: context)
            add(group, "Bootstour",     320,  .eur, payer: sara,  cat: "Aktivität",    day: "2026-05-04", context: context)
            add(group, "Abendessen Strandbar", 156.5, .eur, payer: jonas, cat: "Essen", day: "2026-05-04", context: context)
            add(group, "Einkauf Supermarkt",   84.2,  .chf, payer: you,   cat: "Lebensmittel", day: "2026-05-05", context: context)
            first = group
        }

        // WG Limmatstrasse — CHF only.
        do {
            let lisa = member("Lisa"), mara = member("Mara")
            let group = makeGroup("WG Limmatstrasse", members: [me(), lisa, mara], context: context)
            let owner = group.members?.first { $0.isCurrentUser }
            add(group, "Miete Mai",    2400, .chf, payer: owner, cat: "Miete",       day: "2026-05-01", context: context)
            add(group, "Internet",     59,   .chf, payer: lisa,  cat: "Fixkosten",   day: "2026-05-03", context: context)
            add(group, "Wocheneinkauf", 128.4, .chf, payer: mara, cat: "Lebensmittel", day: "2026-05-08", context: context)
        }

        // Wochenende Berlin — EUR only.
        do {
            let jonas = member("Jonas")
            let group = makeGroup("Wochenende Berlin", members: [me(), jonas], context: context)
            let owner = group.members?.first { $0.isCurrentUser }
            add(group, "Zugtickets",      178,  .eur, payer: owner, cat: "Transport",  day: "2026-04-18", context: context)
            add(group, "Hotel Mitte",     240,  .eur, payer: jonas, cat: "Unterkunft", day: "2026-04-18", context: context)
            add(group, "Restaurant Mitte", 96.5, .eur, payer: owner, cat: "Essen",      day: "2026-04-19", context: context)
        }

        try? context.save()
        return first
    }

    // MARK: - Builders

    private static func makeGroup(_ name: String, members: [Member], context: ModelContext) -> ExpenseGroup {
        let group = ExpenseGroup(name: name)
        context.insert(group)
        for member in members {
            member.group = group
            context.insert(member)
        }
        return group
    }

    /// Adds an equally-split expense with resolved `ExpenseSplit` rows for every member.
    private static func add(
        _ group: ExpenseGroup, _ title: String, _ amount: Decimal, _ currency: CurrencyCode,
        payer: Member?, cat: String, day: String, context: ModelContext
    ) {
        let members = (group.members ?? []).filter { $0.deletedAt == nil }
        let expense = Expense(title: title, amount: amount, currency: currency,
                              splitMethod: .equal, date: parse(day))
        expense.group = group
        expense.payer = payer
        context.insert(expense)

        let shares = SplitCalculator.equalShares(of: amount, among: members.count)
        for (member, share) in zip(members, shares) {
            let split = ExpenseSplit(shareAmount: share)
            split.expense = expense
            split.member = member
            context.insert(split)
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func parse(_ day: String) -> Date {
        dayFormatter.date(from: day) ?? .now
    }
}

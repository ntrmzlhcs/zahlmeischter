//
//  GroupBalancesTests.swift
//  zahlmeischterTests
//
//  Per-currency balances (never aggregated across codes, design.md V2) and that a
//  recorded settlement moves balances toward zero.
//

import Testing
import Foundation
import SwiftData
@testable import zahlmeischter

@MainActor
struct GroupBalancesTests {

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.schema, configurations: configuration)
        return ModelContext(container)
    }

    /// A group with two members and a CHF and a EUR expense.
    private func scenario(_ context: ModelContext) -> (group: ExpenseGroup, me: Member, lisa: Member) {
        let group = ExpenseGroup(name: "Trip")
        context.insert(group)
        let me = Member(name: "Du", isCurrentUser: true)
        let lisa = Member(name: "Lisa")
        [me, lisa].forEach { context.insert($0); $0.group = group }

        addExpense(context, group, amount: 100, currency: .chf, payer: me, members: [me, lisa])
        addExpense(context, group, amount: 60, currency: .eur, payer: lisa, members: [me, lisa])
        return (group, me, lisa)
    }

    private func addExpense(_ context: ModelContext, _ group: ExpenseGroup, amount: Decimal,
                            currency: CurrencyCode, payer: Member, members: [Member]) {
        let expense = Expense(title: "x", amount: amount, currency: currency, splitMethod: .equal)
        context.insert(expense); expense.group = group; expense.payer = payer
        let shares = SplitCalculator.equalShares(of: amount, among: members.count)
        for (member, share) in zip(members, shares) {
            let split = ExpenseSplit(shareAmount: share, expense: expense, member: member)
            context.insert(split)
        }
    }

    @Test("Currencies are tracked separately, never aggregated")
    func perCurrency() throws {
        let context = try makeContext()
        let (group, me, lisa) = scenario(context)
        try context.save()

        let net = GroupBalances.net(for: group)
        #expect(net[.chf]?[me.uuid] == 50)
        #expect(net[.chf]?[lisa.uuid] == -50)
        #expect(net[.eur]?[me.uuid] == -30)
        #expect(net[.eur]?[lisa.uuid] == 30)

        // The member's combined view keeps the two codes on separate keys.
        let mine = GroupBalances.balance(of: me, in: group)
        #expect(mine[.chf] == 50)
        #expect(mine[.eur] == -30)
    }

    @Test("Settle-up produces one payment per currency that clears the group")
    func settlementClears() throws {
        let context = try makeContext()
        let (group, me, lisa) = scenario(context)
        try context.save()

        let plan = GroupBalances.settlement(for: group)
        #expect(plan.count == 2) // one CHF, one EUR

        // Record the payments and confirm everyone nets to zero.
        for entry in plan {
            let settlement = Settlement(amount: entry.tx.amount, currency: entry.currency)
            settlement.group = group
            settlement.fromMember = entry.tx.from == me.uuid ? me : lisa
            settlement.toMember = entry.tx.to == me.uuid ? me : lisa
            context.insert(settlement)
        }
        try context.save()

        #expect(GroupBalances.balance(of: me, in: group).isEmpty)
        #expect(GroupBalances.balance(of: lisa, in: group).isEmpty)
    }
}

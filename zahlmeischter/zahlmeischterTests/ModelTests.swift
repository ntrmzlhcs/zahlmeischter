//
//  ModelTests.swift
//  zahlmeischterTests
//
//  Created by Martin on 13.06.2026.
//

import Testing
import Foundation
import SwiftData
@testable import zahlmeischter

/// Exercises the SwiftData models against an **in-memory** container (no disk, no
/// CloudKit): the defaults every CloudKit-safe property must carry, that the relationship
/// inverses connect both sides, and that a saved expense's split shares add back up to its
/// amount. `@MainActor` because `@Model` access and `ModelContext` are main-actor work.
@MainActor
struct ModelTests {

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistenceController.schema, configurations: configuration)
        return ModelContext(container)
    }

    @Test("New models carry their CloudKit-safe defaults")
    func defaults() {
        let group = ExpenseGroup()
        #expect(group.name == "")
        #expect(group.currency == .chf)
        #expect(group.deletedAt == nil)

        let expense = Expense()
        #expect(expense.amount == 0)
        #expect(expense.splitMethod == .equal)
        #expect(expense.currency == .chf)

        let member = Member()
        #expect(member.isCurrentUser == false)
        #expect(member.iCloudUserID == nil)
    }

    @Test("Relationship inverses connect group, member, expense and split")
    func inverses() throws {
        let context = try makeContext()

        let group = ExpenseGroup(name: "Mallorca")
        let me = Member(name: "Martin", isCurrentUser: true)
        let lisa = Member(name: "Lisa")
        context.insert(group)
        context.insert(me)
        context.insert(lisa)
        me.group = group
        lisa.group = group

        let expense = Expense(title: "Pizza", amount: 30)
        context.insert(expense)
        expense.group = group
        expense.payer = me
        let mine = ExpenseSplit(shareAmount: 15, expense: expense, member: me)
        let hers = ExpenseSplit(shareAmount: 15, expense: expense, member: lisa)
        context.insert(mine)
        context.insert(hers)
        try context.save()

        #expect(group.members?.count == 2)
        #expect(group.expenses?.count == 1)
        #expect(expense.splits?.count == 2)
        #expect(me.paidExpenses?.count == 1)
        #expect(me.splits?.count == 1)
        let splitTotal = (expense.splits ?? []).reduce(Decimal(0)) { $0 + $1.shareAmount }
        #expect(splitTotal == expense.amount)
    }

    @Test("A persisted equal split's shares sum back to the expense amount")
    func equalSplitPersisted() throws {
        let context = try makeContext()

        let group = ExpenseGroup(name: "WG")
        context.insert(group)
        let members = ["A", "B", "C"].map { Member(name: $0) }
        members.forEach {
            context.insert($0)
            $0.group = group
        }

        let expense = Expense(title: "Strom", amount: Decimal(string: "10.00")!)
        context.insert(expense)
        expense.group = group

        let shares = SplitCalculator.equalShares(of: expense.amount, among: members.count)
        for (member, amount) in zip(members, shares) {
            let split = ExpenseSplit(shareAmount: amount, expense: expense, member: member)
            context.insert(split)
        }
        try context.save()

        let total = (expense.splits ?? []).reduce(Decimal(0)) { $0 + $1.shareAmount }
        #expect(total == expense.amount)
        #expect(expense.splits?.count == 3)
    }
}

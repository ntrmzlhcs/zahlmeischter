//
//  DebtSimplifier.swift
//  zahlmeischter
//
//  Settle-up: turns a set of net balances into the fewest payments that clear them.
//  Framework-agnostic value math (no SwiftUI/SwiftData), so it's trivially testable
//  without a ModelContainer. Runs **per currency** — callers never mix codes
//  (design.md V2). Ported from the prototype's `simplifyCur`.
//

import Foundation

nonisolated enum DebtSimplifier {

    /// A single "from pays to" payment, identified by member `uuid`.
    struct Transaction: Equatable, Sendable {
        let from: UUID
        let to: UUID
        let amount: Decimal
    }

    /// Greedy minimal-transaction settlement for one currency.
    ///
    /// `net` maps member uuid → net balance (positive = is owed money, negative =
    /// owes money) in a single currency. Returns the payments that bring everyone to
    /// zero, largest debtor paying largest creditor first. Ties are broken by `uuid`
    /// so the result is deterministic (dictionaries have no stable order).
    static func simplify(_ net: [UUID: Decimal]) -> [Transaction] {
        let epsilon = Decimal(string: "0.01")!
        var debtors = net.filter { $0.value < -epsilon }
            .map { (id: $0.key, amount: -$0.value) }
        var creditors = net.filter { $0.value > epsilon }
            .map { (id: $0.key, amount: $0.value) }

        debtors.sort { $0.amount != $1.amount ? $0.amount > $1.amount : $0.id.uuidString < $1.id.uuidString }
        creditors.sort { $0.amount != $1.amount ? $0.amount > $1.amount : $0.id.uuidString < $1.id.uuidString }

        var transactions: [Transaction] = []
        var i = 0, j = 0
        while i < debtors.count, j < creditors.count {
            let amount = min(debtors[i].amount, creditors[j].amount)
            transactions.append(Transaction(from: debtors[i].id, to: creditors[j].id, amount: amount))
            debtors[i].amount -= amount
            creditors[j].amount -= amount
            if debtors[i].amount < epsilon { i += 1 }
            if creditors[j].amount < epsilon { j += 1 }
        }
        return transactions
    }
}

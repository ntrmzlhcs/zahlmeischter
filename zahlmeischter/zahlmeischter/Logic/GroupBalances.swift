//
//  GroupBalances.swift
//  zahlmeischter
//
//  Derives per-member, per-currency net balances for a group from its expenses and
//  the resolved `ExpenseSplit.shareAmount` rows. Currencies are kept strictly
//  separate (design.md V2: never aggregate across codes). Touches SwiftData models,
//  so it inherits the project's MainActor default isolation (unlike the pure
//  `SplitCalculator` / `DebtSimplifier`).
//

import Foundation

enum GroupBalances {

    /// Net balance per member uuid, per currency, for `group`.
    /// Positive ⇒ the member is owed money; negative ⇒ the member owes.
    ///
    /// For each (non-deleted) expense: the payer is credited the full amount and every
    /// split member is debited their resolved share — all within the expense's own
    /// currency. Soft-deleted rows are ignored.
    static func net(for group: ExpenseGroup) -> [CurrencyCode: [UUID: Decimal]] {
        var balances: [CurrencyCode: [UUID: Decimal]] = [:]
        for expense in (group.expenses ?? []) where expense.deletedAt == nil {
            let currency = expense.currency
            if let payer = expense.payer {
                balances[currency, default: [:]][payer.uuid, default: 0] += expense.amount
            }
            for split in (expense.splits ?? []) where split.deletedAt == nil {
                if let member = split.member {
                    balances[currency, default: [:]][member.uuid, default: 0] -= split.shareAmount
                }
            }
        }
        // A settlement payment moves both parties toward zero: the payer (a debtor) is
        // credited, the receiver (a creditor) is debited — within the payment's currency.
        for settlement in (group.settlements ?? []) where settlement.deletedAt == nil {
            let currency = settlement.currency
            if let from = settlement.fromMember {
                balances[currency, default: [:]][from.uuid, default: 0] += settlement.amount
            }
            if let to = settlement.toMember {
                balances[currency, default: [:]][to.uuid, default: 0] -= settlement.amount
            }
        }
        return balances
    }

    /// Net balance for a single member across every currency in the group.
    /// One entry per currency where the member's balance is non-trivial.
    static func balance(of member: Member, in group: ExpenseGroup) -> [CurrencyCode: Decimal] {
        let all = net(for: group)
        var out: [CurrencyCode: Decimal] = [:]
        for (currency, byMember) in all {
            if let value = byMember[member.uuid], abs(value) > 0.005 {
                out[currency] = value
            }
        }
        return out
    }

    /// The minimal settle-up payments for the whole group, computed per currency and
    /// flattened. Each transaction carries the currency it settles.
    static func settlement(for group: ExpenseGroup) -> [(currency: CurrencyCode, tx: DebtSimplifier.Transaction)] {
        let all = net(for: group)
        var out: [(currency: CurrencyCode, tx: DebtSimplifier.Transaction)] = []
        for currency in CurrencyCode.allCases {
            guard let byMember = all[currency] else { continue }
            for tx in DebtSimplifier.simplify(byMember) {
                out.append((currency, tx))
            }
        }
        return out
    }
}

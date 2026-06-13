//
//  Expense.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import SwiftData

/// A single shared expense within an `ExpenseGroup`.
///
/// `Settlement` arrives in a later milestone; division is modelled by the `splits`
/// to-many (`ExpenseSplit` rows, one per participant). Money is `Decimal` — never
/// `Double` — to keep split math free of floating-point rounding error.
@Model
final class Expense {
    var uuid: UUID = UUID()
    var title: String = ""
    /// Total amount of the expense. Always `Decimal`.
    var amount: Decimal = 0
    /// Currency this expense was incurred in (may differ from the group default).
    var currency: CurrencyCode = CurrencyCode.chf
    /// How the amount is divided among participants. Per-expense (not per-split) — the
    /// `splits` hold the *resolved* amounts; this records which method produced them.
    var splitMethod: SplitMethod = SplitMethod.equal
    var date: Date = Date.now
    var createdAt: Date = Date.now
    var deletedAt: Date? = nil

    /// Optional scanned receipt image, stored outside the row to keep the store lean.
    @Attribute(.externalStorage) var receiptImageData: Data? = nil

    /// Owning group. Inverse is declared on `ExpenseGroup.expenses`.
    var group: ExpenseGroup? = nil
    /// The member who fronted the money. Inverse is declared on `Member.paidExpenses`.
    var payer: Member? = nil

    /// How the amount is divided — one row per participating member. Cascade-deletes with
    /// the expense; the inverse (`ExpenseSplit.expense`) is the plain to-one side.
    @Relationship(deleteRule: .cascade, inverse: \ExpenseSplit.expense)
    var splits: [ExpenseSplit]? = []

    init(
        uuid: UUID = UUID(),
        title: String = "",
        amount: Decimal = 0,
        currency: CurrencyCode = .chf,
        splitMethod: SplitMethod = .equal,
        date: Date = .now,
        createdAt: Date = .now,
        deletedAt: Date? = nil,
        receiptImageData: Data? = nil,
        group: ExpenseGroup? = nil,
        payer: Member? = nil
    ) {
        self.uuid = uuid
        self.title = title
        self.amount = amount
        self.currency = currency
        self.splitMethod = splitMethod
        self.date = date
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.receiptImageData = receiptImageData
        self.group = group
        self.payer = payer
    }
}

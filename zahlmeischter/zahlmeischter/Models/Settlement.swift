//
//  Settlement.swift
//  zahlmeischter
//
//  A recorded "X paid Y" payment that clears part of a group's debt. Produced when the
//  user confirms a settle-up; folded back into `GroupBalances` so balances move toward
//  zero. Follows the CloudKit rules (optional/defaulted properties, `uuid` identity,
//  optional relationships with the inverse on the group's to-many side).
//

import Foundation
import SwiftData

@Model
final class Settlement {
    var uuid: UUID = UUID()
    /// Amount paid, in `currency`. Always `Decimal`.
    var amount: Decimal = 0
    var currency: CurrencyCode = CurrencyCode.chf
    var date: Date = Date.now
    var deletedAt: Date? = nil

    /// Owning group. Inverse is declared on `ExpenseGroup.settlements`.
    var group: ExpenseGroup? = nil
    /// The member who paid (a debtor clearing what they owe).
    var fromMember: Member? = nil
    /// The member who received (a creditor being paid back).
    var toMember: Member? = nil

    init(
        uuid: UUID = UUID(),
        amount: Decimal = 0,
        currency: CurrencyCode = .chf,
        date: Date = .now,
        deletedAt: Date? = nil,
        group: ExpenseGroup? = nil,
        fromMember: Member? = nil,
        toMember: Member? = nil
    ) {
        self.uuid = uuid
        self.amount = amount
        self.currency = currency
        self.date = date
        self.deletedAt = deletedAt
        self.group = group
        self.fromMember = fromMember
        self.toMember = toMember
    }
}

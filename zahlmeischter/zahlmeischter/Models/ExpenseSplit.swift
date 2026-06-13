//
//  ExpenseSplit.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import SwiftData

/// One participant's share of a single `Expense`.
///
/// `shareAmount` is the **resolved** amount this member owes for the expense — computed
/// once at save time by `SplitCalculator` (equal/percentage/custom) and then the single
/// source of truth for balance math, so the dashboard never re-derives split rounding.
/// Money is `Decimal`, never `Double`. Follows the CloudKit rules (all properties
/// optional-or-defaulted, `uuid` identity rather than `@Attribute(.unique)`, relationships
/// optional with the inverse declared on the to-many side).
@Model
final class ExpenseSplit {
    var uuid: UUID = UUID()
    /// Resolved amount this member owes for the owning expense, in the expense's currency.
    var shareAmount: Decimal = 0
    /// The percentage input, retained only for `.percentage` splits so the value stays
    /// re-editable; `nil` for equal/custom (where it carries no meaning).
    var percent: Decimal? = nil
    var createdAt: Date = Date.now
    var deletedAt: Date? = nil

    /// Owning expense. Inverse is declared on `Expense.splits` (cascade).
    var expense: Expense? = nil
    /// The member this share belongs to. Inverse is declared on `Member.splits` (nullify).
    var member: Member? = nil

    init(
        uuid: UUID = UUID(),
        shareAmount: Decimal = 0,
        percent: Decimal? = nil,
        createdAt: Date = .now,
        deletedAt: Date? = nil,
        expense: Expense? = nil,
        member: Member? = nil
    ) {
        self.uuid = uuid
        self.shareAmount = shareAmount
        self.percent = percent
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.expense = expense
        self.member = member
    }
}

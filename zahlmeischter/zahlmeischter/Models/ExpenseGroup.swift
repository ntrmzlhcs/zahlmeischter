//
//  ExpenseGroup.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import SwiftData

/// A group of people sharing expenses — a dinner, trip, shared household, travel.
///
/// Destined to be the CKShare **root record** (see CLAUDE.md "CloudKit Setup &
/// Known Gap"): members, expenses, and their children hang off it and share as a
/// unit. Every stored property is optional or defaulted, and identity uses a
/// client-generated `uuid` rather than `@Attribute(.unique)`, per the CloudKit
/// constraints.
@Model
final class ExpenseGroup {
    /// Stable, client-generated identity (CloudKit can't enforce uniqueness).
    var uuid: UUID = UUID()
    var name: String = ""
    /// Default currency for the group; an individual `Expense` may override it.
    var currency: CurrencyCode = CurrencyCode.chf
    var createdAt: Date = Date.now
    /// Soft-delete tombstone (`nil` ⇒ active). CloudKit deletion is eventually consistent.
    var deletedAt: Date? = nil

    /// The relationship inverses are declared here (the to-many side); the partner
    /// properties (`Member.group`, `Expense.group`) stay plain to avoid a
    /// double-declared inverse, which SwiftData rejects.
    @Relationship(deleteRule: .cascade, inverse: \Member.group)
    var members: [Member]? = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.group)
    var expenses: [Expense]? = []

    init(
        uuid: UUID = UUID(),
        name: String = "",
        currency: CurrencyCode = .chf,
        createdAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.currency = currency
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

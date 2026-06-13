//
//  Member.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import SwiftData

/// A participant in an `ExpenseGroup`.
///
/// A "real" member gains an `iCloudUserID` once group sharing (CKShare) lands; a
/// `nil` id marks a Splitwise-style **placeholder/ghost** member — someone tracked
/// locally who doesn't use the app (CKShare only supports real iCloud participants,
/// so placeholders stay local-only annotations).
@Model
final class Member {
    var uuid: UUID = UUID()
    var name: String = ""
    /// `nil` ⇒ placeholder/ghost member; non-nil links a real iCloud participant.
    var iCloudUserID: String? = nil
    /// Marks the device owner's member — the "you" the dashboard and payer default are
    /// framed around. **Local-only V1 simplification:** "who am I" is a per-device fact,
    /// not a shared one, so once CKShare group sharing lands (see CLAUDE.md "Known gap")
    /// this must move to device-local storage rather than syncing on the shared record.
    /// Until then it rides along on the model. Related: `iCloudUserID`.
    var isCurrentUser: Bool = false
    var createdAt: Date = Date.now
    var deletedAt: Date? = nil

    /// Owning group. Inverse is declared on `ExpenseGroup.members`.
    var group: ExpenseGroup? = nil

    /// Expenses this member fronted. Inverse of `Expense.payer`; `.nullify` (not
    /// cascade) so removing a payer never deletes the shared expense itself.
    @Relationship(deleteRule: .nullify, inverse: \Expense.payer)
    var paidExpenses: [Expense]? = []

    /// This member's shares across expenses. `.nullify` (not cascade) so removing a
    /// member never deletes the shared expense's split data — mirrors `paidExpenses`.
    @Relationship(deleteRule: .nullify, inverse: \ExpenseSplit.member)
    var splits: [ExpenseSplit]? = []

    init(
        uuid: UUID = UUID(),
        name: String = "",
        iCloudUserID: String? = nil,
        isCurrentUser: Bool = false,
        createdAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.iCloudUserID = iCloudUserID
        self.isCurrentUser = isCurrentUser
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

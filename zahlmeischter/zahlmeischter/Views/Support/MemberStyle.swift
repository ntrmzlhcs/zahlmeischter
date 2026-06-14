//
//  MemberStyle.swift
//  zahlmeischter
//
//  Maps members to their avatar colour and initials. "Du" (the current user) is always
//  teal; everyone else cycles the palette deterministically by their position in the
//  group, so a member keeps the same colour everywhere they appear.
//

import SwiftUI

@MainActor
enum MemberStyle {

    static func color(for member: Member, in group: ExpenseGroup?) -> Color {
        if member.isCurrentUser { return Theme.me }
        let others = (group?.members ?? [])
            .filter { !$0.isCurrentUser && $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
        let index = others.firstIndex { $0.uuid == member.uuid } ?? 0
        return Theme.memberPalette[index % Theme.memberPalette.count]
    }

    /// "Du" for the current user, otherwise the first letter of the name.
    static func initials(for member: Member) -> String {
        member.isCurrentUser ? "Du" : String(member.name.prefix(1)).uppercased()
    }
}

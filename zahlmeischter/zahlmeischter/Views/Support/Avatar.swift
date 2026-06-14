//
//  Avatar.swift
//  zahlmeischter
//
//  A round member token (coloured circle + initials), reused across the dashboard,
//  group detail, splits, and the settle-up list.
//

import SwiftUI

struct Avatar: View {
    let initials: String
    let color: Color
    var size: CGFloat = 36
    var ringColor: Color? = nil

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay {
                if let ringColor {
                    Circle().strokeBorder(ringColor, lineWidth: 2)
                }
            }
    }
}

extension Avatar {
    /// Convenience for a model member within its group.
    @MainActor
    init(_ member: Member, in group: ExpenseGroup?, size: CGFloat = 36, ringColor: Color? = nil) {
        self.init(
            initials: MemberStyle.initials(for: member),
            color: MemberStyle.color(for: member, in: group),
            size: size,
            ringColor: ringColor
        )
    }
}

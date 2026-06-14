//
//  SheetChrome.swift
//  zahlmeischter
//
//  Shared sheet styling: the frosted-glass presentation background + drag indicator,
//  and a reusable header row (leading cancel/close, centered title, optional trailing
//  action) so every modal reads consistently.
//

import SwiftUI

struct SheetHeader: View {
    let title: String
    var leading: String = "Abbrechen"
    var onLeading: () -> Void
    var trailing: String? = nil
    var trailingEnabled: Bool = true
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(leading, action: onLeading)
                .font(.system(size: 16)).foregroundStyle(Theme.accent)
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.fg)
            Spacer()
            if let trailing, let onTrailing {
                Button(trailing, action: onTrailing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(trailingEnabled ? Theme.accent : Theme.fg3)
                    .disabled(!trailingEnabled)
            } else {
                Text(leading).font(.system(size: 16)).opacity(0) // balance the title
            }
        }
        .frame(height: 44)
    }
}

extension View {
    /// The frosted glass look for a presented sheet.
    func sheetStyle() -> some View {
        self
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
    }
}

//
//  BalanceCard.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI

/// A Liquid Glass card summarising one member's net standing within a group.
///
/// All text is **SF** (sans) per the type scale — the New York serif is reserved
/// for the Dashboard hero number. Copy is neutral German (design.md): the sign of
/// `balance` chooses the label and tint, framed around "open amounts" rather than
/// accusatory "X owes Y" wording. Red is deliberately never used for what's owed.
struct BalanceCard: View {
    let memberName: String
    /// The member's **net group balance**: `paid − owed share`. Positive ⇒ the member is
    /// ahead (the group owes them), negative ⇒ they still owe the group, zero ⇒ settled.
    /// Pairwise "who pays whom" minimisation is the later settle-up milestone.
    let balance: Decimal
    var currency: CurrencyCode = .chf

    var body: some View {
        HStack(spacing: 16) {
            Text(initial)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(memberName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(directionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(CurrencyFormatting.string(abs(balance), code: currency))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(amountTint)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Derived presentation

    private var initial: String {
        memberName.first.map { String($0).uppercased() } ?? "?"
    }

    private var directionLabel: LocalizedStringKey {
        if balance > 0 { "im Plus" }
        else if balance < 0 { "offen" }
        else { "ausgeglichen" }
    }

    private var amountTint: Color {
        if balance > 0 { .green }
        else if balance < 0 { .primary }
        else { .secondary }
    }
}

#Preview("Balance cards", traits: .sizeThatFitsLayout) {
    GlassEffectContainer(spacing: 16) {
        VStack(spacing: 16) {
            BalanceCard(memberName: "Lisa", balance: 1200.50)
            BalanceCard(memberName: "Marco", balance: -35)
            BalanceCard(memberName: "Ana", balance: 0)
        }
    }
    .padding()
    .background(MeshGradientBackground())
}

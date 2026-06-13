//
//  CurrencyFormatting.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation

/// Formats monetary `Decimal` values per the app's Swiss conventions (CLAUDE.md +
/// design.md): apostrophe thousands separator, period decimal, exactly two fraction
/// digits, and the **ISO code as a literal prefix** (`CHF 1'000.00`) — never a
/// currency symbol. Framework-agnostic (no SwiftUI) and the single source of truth
/// for amount display across the app.
enum CurrencyFormatting {
    /// Swiss locale informs grouping size/placement; the separators are then pinned
    /// explicitly below so we never inherit `de_CH`'s right-single-quote (U+2019)
    /// group glyph — design.md mandates a plain apostrophe.
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = "'"
        formatter.decimalSeparator = "."
        formatter.groupingSize = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formats just the number part, e.g. `1000` → `"1'000.00"`.
    static func amountString(_ amount: Decimal) -> String {
        // `string(from:)` only returns nil for non-finite values, which `Decimal`
        // cannot represent — the coalesce is purely defensive.
        numberFormatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// Formats a full, displayable amount, e.g. `string(1000, .chf)` → `"CHF 1'000.00"`.
    static func string(_ amount: Decimal, code: CurrencyCode) -> String {
        "\(code.isoCode) \(amountString(amount))"
    }
}

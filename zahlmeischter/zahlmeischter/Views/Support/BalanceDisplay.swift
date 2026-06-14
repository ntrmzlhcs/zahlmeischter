//
//  BalanceDisplay.swift
//  zahlmeischter
//
//  Turns a per-currency balance map into display lines — one line per currency, never
//  aggregated (design.md V2). Each line carries its Swiss-formatted text and the
//  sign colour (positive teal-green / negative rose).
//

import SwiftUI

@MainActor
enum BalanceDisplay {

    struct Line: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
        let value: Decimal
    }

    /// Lines in CHF / EUR / USD order, skipping near-zero balances.
    /// `signed` prepends an explicit `+` / `−`; otherwise sign is colour-only.
    static func lines(_ map: [CurrencyCode: Decimal], signed: Bool = false) -> [Line] {
        CurrencyCode.allCases.compactMap { code in
            guard let value = map[code], abs(value) > 0.005 else { return nil }
            let prefix = signed ? (value >= 0 ? "+" : "\u{2212}") : ""
            let text = "\(prefix)\(code.isoCode) \(CurrencyFormatting.amountString(abs(value)))"
            return Line(text: text, color: value >= 0 ? Theme.positive : Theme.negative, value: value)
        }
    }

    /// A single neutral "ausgeglichen" line when the map is empty.
    static func linesOrSettled(_ map: [CurrencyCode: Decimal], signed: Bool = false) -> [Line] {
        let lines = lines(map, signed: signed)
        if lines.isEmpty {
            return [Line(text: "ausgeglichen", color: Theme.fg2, value: 0)]
        }
        return lines
    }
}

//
//  CurrencyCode.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation

/// ISO 4217 currency code. V1 ships CHF + EUR; the string backing makes adding
/// further codes a one-line change (per CLAUDE.md: a code type, never a CHF/EUR
/// boolean). String-backed so SwiftData/CloudKit persist it as a plain `String`.
enum CurrencyCode: String, Codable, CaseIterable, Sendable, Identifiable {
    case chf = "CHF"
    case eur = "EUR"

    var id: String { rawValue }

    /// The literal ISO code shown next to amounts (`CHF`, `EUR`) — never a symbol.
    var isoCode: String { rawValue }
}

//
//  SplitMethod.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation

/// How an `Expense` is divided among its participants. The method is a property of
/// the expense as a whole — you pick one way to split the *whole* bill — so it lives
/// on `Expense`, not on each `ExpenseSplit` row (a deliberate refinement of CLAUDE.md's
/// informal entity sketch, which listed "split type" per split).
///
/// String-backed so SwiftData/CloudKit persist it as a plain `String`, mirroring
/// `CurrencyCode`; adding a future method (e.g. shares/weights) stays a one-line change.
enum SplitMethod: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Divide the total evenly; leftover rounding cents are distributed deterministically.
    case equal = "equal"
    /// Each participant owes a percentage of the total (percentages sum to 100).
    case percentage = "percentage"
    /// Each participant's amount is entered directly (amounts sum to the total).
    case custom = "custom"

    var id: String { rawValue }

    /// Short German label for the split-method selector (design.md: informal `du`,
    /// Swiss orthography). Localized via the String Catalog.
    var label: LocalizedStringResource {
        switch self {
        case .equal: "Gleich"
        case .percentage: "Prozent"
        case .custom: "Benutzerdefiniert"
        }
    }
}

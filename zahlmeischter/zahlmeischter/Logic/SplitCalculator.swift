//
//  SplitCalculator.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation

/// Resolves how an expense's total divides into per-participant share amounts.
///
/// Framework-agnostic (no SwiftUI/SwiftData) and operates purely on values — totals,
/// counts, arrays of `Decimal` — so it's trivially unit-testable without a
/// `ModelContainer`. All money is `Decimal`; every method works in integer **cents** so
/// the returned shares **sum exactly** to the input total with no floating-point or
/// rounding drift (a lost or duplicated cent is exactly the silent bug CLAUDE.md warns
/// about). `nonisolated` so the pure math is callable from any actor despite the
/// project's `MainActor` default isolation.
///
/// Preconditions: totals and shares are expected non-negative (the editors enforce
/// amount > 0). Amounts are treated at 2-decimal (cent) precision.
nonisolated enum SplitCalculator {

    /// Splits `total` evenly among `count` participants, distributing any leftover
    /// rounding cents to the first shares so the result sums exactly to `total`.
    /// E.g. `equalShares(of: 10.00, among: 3) == [3.34, 3.33, 3.33]`.
    static func equalShares(of total: Decimal, among count: Int) -> [Decimal] {
        guard count > 0 else { return [] }
        let totalCents = cents(total)
        let base = totalCents / count
        let remainder = totalCents % count
        return (0..<count).map { index in
            decimal(fromCents: base + (index < remainder ? 1 : 0))
        }
    }

    /// Resolves each participant's `percentage` of `total` to a cent amount, distributing
    /// leftover cents by the **largest-remainder method** so the shares sum exactly to
    /// `total`. Percentages are expected to sum to 100 (see `percentagesAreValid`); the
    /// returned array matches the order of `percentages`.
    static func percentageShares(of total: Decimal, percentages: [Decimal]) -> [Decimal] {
        guard !percentages.isEmpty else { return [] }
        let totalCents = cents(total)
        let ideals = percentages.map { (Decimal(totalCents) * $0) / 100 }
        var floors = ideals.map { floorToInt($0) }
        var leftover = totalCents - floors.reduce(0, +)
        // Hand the spare cents to the largest fractional remainders first.
        let byFractionDescending = ideals.indices.sorted {
            (ideals[$0] - Decimal(floors[$0])) > (ideals[$1] - Decimal(floors[$1]))
        }
        var i = 0
        while leftover > 0 && i < byFractionDescending.count {
            floors[byFractionDescending[i]] += 1
            leftover -= 1
            i += 1
        }
        return floors.map { decimal(fromCents: $0) }
    }

    /// Whether directly-entered custom `shares` sum exactly (to the cent) to `total`.
    static func customIsValid(shares: [Decimal], total: Decimal) -> Bool {
        !shares.isEmpty && cents(shares.reduce(0, +)) == cents(total)
    }

    /// Whether `percentages` sum to exactly 100 (compared at 2-decimal precision).
    static func percentagesAreValid(_ percentages: [Decimal]) -> Bool {
        !percentages.isEmpty && round(percentages.reduce(0, +), scale: 2) == 100
    }

    // MARK: - Decimal / cent helpers

    /// Rounds `value` to `scale` decimal places (banker-free `.plain` half-up rounding).
    private static func round(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }

    /// `value` as a whole number of cents (rounded to 2dp first).
    private static func cents(_ value: Decimal) -> Int {
        NSDecimalNumber(decimal: round(value * 100, scale: 0)).intValue
    }

    /// Whole cents back to a `Decimal` amount (exact: division by a power of ten).
    private static func decimal(fromCents value: Int) -> Decimal {
        Decimal(value) / 100
    }

    /// Floor of a non-negative `Decimal` as an `Int` (`.down` = toward zero).
    private static func floorToInt(_ value: Decimal) -> Int {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 0, .down)
        return NSDecimalNumber(decimal: result).intValue
    }
}

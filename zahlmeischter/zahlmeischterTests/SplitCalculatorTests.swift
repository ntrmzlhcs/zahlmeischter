//
//  SplitCalculatorTests.swift
//  zahlmeischterTests
//
//  Created by Martin on 13.06.2026.
//

import Testing
import Foundation
@testable import zahlmeischter

/// The money math is where silent bugs hurt most (a lost or duplicated cent), so these
/// lock down the core invariant: **shares always sum exactly to the total**, plus the
/// deterministic remainder distribution and the validation helpers.
struct SplitCalculatorTests {

    // MARK: - Equal

    @Test("Equal split divides evenly when it divides cleanly")
    func equalClean() {
        let shares = SplitCalculator.equalShares(of: 100, among: 4)
        #expect(shares == [25, 25, 25, 25])
        #expect(shares.reduce(0, +) == 100)
    }

    @Test("Equal split hands leftover cents to the first shares")
    func equalRemainder() {
        let shares = SplitCalculator.equalShares(of: 10, among: 3)
        #expect(shares == [Decimal(string: "3.34")!, Decimal(string: "3.33")!, Decimal(string: "3.33")!])
        #expect(shares.reduce(0, +) == 10)
    }

    @Test("Equal split of a single cent lands entirely on one share")
    func equalTinyAmount() {
        let shares = SplitCalculator.equalShares(of: Decimal(string: "0.01")!, among: 3)
        #expect(shares == [Decimal(string: "0.01")!, 0, 0])
        #expect(shares.reduce(0, +) == Decimal(string: "0.01")!)
    }

    @Test("Equal split among one is the whole total")
    func equalSingle() {
        #expect(SplitCalculator.equalShares(of: Decimal(string: "42.50")!, among: 1) == [Decimal(string: "42.50")!])
    }

    @Test("Equal split among zero is empty")
    func equalZero() {
        #expect(SplitCalculator.equalShares(of: 100, among: 0).isEmpty)
    }

    @Test("Equal split always sums exactly to the total", arguments: [
        (Decimal(string: "100.00")!, 3),
        (Decimal(string: "0.10")!, 3),
        (Decimal(string: "99.99")!, 7),
        (Decimal(string: "1234.56")!, 5),
        (Decimal(string: "20.00")!, 6),
        (Decimal(string: "0.05")!, 4),
    ])
    func equalSumsToTotal(total: Decimal, count: Int) {
        let shares = SplitCalculator.equalShares(of: total, among: count)
        #expect(shares.count == count)
        #expect(shares.reduce(0, +) == total)
    }

    // MARK: - Percentage

    @Test("Percentage split resolves clean percentages directly")
    func percentageClean() {
        let shares = SplitCalculator.percentageShares(of: 100, percentages: [50, 25, 25])
        #expect(shares == [50, 25, 25])
        #expect(shares.reduce(0, +) == 100)
    }

    @Test("Percentage split distributes rounding cents by largest remainder")
    func percentageRemainder() {
        // 33.34 / 33.33 / 33.33 of 10.00 → the spare cent goes to the largest fraction.
        let shares = SplitCalculator.percentageShares(
            of: 10,
            percentages: [Decimal(string: "33.34")!, Decimal(string: "33.33")!, Decimal(string: "33.33")!]
        )
        #expect(shares == [Decimal(string: "3.34")!, Decimal(string: "3.33")!, Decimal(string: "3.33")!])
        #expect(shares.reduce(0, +) == 10)
    }

    @Test("Percentage split always sums exactly to the total", arguments: [
        Decimal(string: "100.00")!,
        Decimal(string: "99.99")!,
        Decimal(string: "57.43")!,
        Decimal(string: "1000.00")!,
    ])
    func percentageSumsToTotal(total: Decimal) {
        let shares = SplitCalculator.percentageShares(
            of: total,
            percentages: [Decimal(string: "33.33")!, Decimal(string: "33.33")!, Decimal(string: "33.34")!]
        )
        #expect(shares.reduce(0, +) == total)
    }

    @Test("Percentage validity requires the sum to be 100")
    func percentageValidity() {
        #expect(SplitCalculator.percentagesAreValid([50, 50]))
        #expect(SplitCalculator.percentagesAreValid([Decimal(string: "33.33")!, Decimal(string: "33.33")!, Decimal(string: "33.34")!]))
        #expect(!SplitCalculator.percentagesAreValid([50, 40]))
        #expect(!SplitCalculator.percentagesAreValid([]))
    }

    // MARK: - Custom

    @Test("Custom validity requires shares to sum to the total")
    func customValidity() {
        #expect(SplitCalculator.customIsValid(shares: [Decimal(string: "40.00")!, Decimal(string: "60.00")!], total: 100))
        #expect(!SplitCalculator.customIsValid(shares: [Decimal(string: "40.00")!, Decimal(string: "50.00")!], total: 100))
        #expect(!SplitCalculator.customIsValid(shares: [], total: 100))
    }
}

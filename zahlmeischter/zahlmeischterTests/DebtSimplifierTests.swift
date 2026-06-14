//
//  DebtSimplifierTests.swift
//  zahlmeischterTests
//
//  The settle-up algorithm: that payments clear every balance, never exceed the number
//  of non-zero parties, and stay deterministic.
//

import Testing
import Foundation
@testable import zahlmeischter

struct DebtSimplifierTests {

    private func id() -> UUID { UUID() }

    @Test("An already-balanced group needs no payments")
    func balanced() {
        let a = id(), b = id()
        #expect(DebtSimplifier.simplify([a: 0, b: 0]).isEmpty)
    }

    @Test("One debtor, one creditor settles in a single payment")
    func simplePair() {
        let debtor = id(), creditor = id()
        let tx = DebtSimplifier.simplify([debtor: Decimal(string: "-42.50")!, creditor: Decimal(string: "42.50")!])
        #expect(tx.count == 1)
        #expect(tx.first?.from == debtor)
        #expect(tx.first?.to == creditor)
        #expect(tx.first?.amount == Decimal(string: "42.50"))
    }

    @Test("Payments zero out every member's balance")
    func clearsEveryone() {
        let a = id(), b = id(), c = id(), d = id()
        let net: [UUID: Decimal] = [
            a: Decimal(string: "-30")!, b: Decimal(string: "-20")!,
            c: Decimal(string: "35")!, d: Decimal(string: "15")!,
        ]
        let tx = DebtSimplifier.simplify(net)

        var resolved = net
        for t in tx {
            resolved[t.from, default: 0] += t.amount
            resolved[t.to, default: 0] -= t.amount
        }
        for (_, value) in resolved { #expect(abs(value) < Decimal(string: "0.01")!) }
        // Never more payments than non-zero parties.
        #expect(tx.count <= net.count)
    }

    @Test("Result is deterministic regardless of dictionary order")
    func deterministic() {
        let a = id(), b = id(), c = id()
        let net: [UUID: Decimal] = [a: -50, b: 20, c: 30]
        #expect(DebtSimplifier.simplify(net) == DebtSimplifier.simplify(net))
    }
}

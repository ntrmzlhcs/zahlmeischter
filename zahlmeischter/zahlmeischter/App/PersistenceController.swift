//
//  PersistenceController.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import SwiftData

/// Owns the app's SwiftData `ModelContainer`.
///
/// **Local-only for now.** CLAUDE.md's build order is "local first," and the
/// CloudKit work — private-DB sync plus the CKShare spike for group sharing — is
/// not done yet. The models already satisfy every CloudKit constraint, so enabling
/// sync later is a configuration change here (a `cloudKitDatabase:` on the
/// `ModelConfiguration`), not a model rewrite.
enum PersistenceController {
    /// The schema shared by every container.
    static let schema = Schema([
        ExpenseGroup.self,
        Member.self,
        Expense.self,
        ExpenseSplit.self,
        Settlement.self,
    ])

    /// On-disk container backing the running app.
    static let shared: ModelContainer = makeContainer(inMemory: false)

    /// Ephemeral, in-memory container for SwiftUI previews and tests. No sample data
    /// is seeded — per the milestone's "real data + empty state" decision, an empty
    /// container renders the dashboard's empty state.
    static let preview: ModelContainer = makeContainer(inMemory: true)

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create the ModelContainer: \(error)")
        }
    }
}

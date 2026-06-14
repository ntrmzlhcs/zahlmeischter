//
//  zahlmeischterApp.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI
import SwiftData

@main
struct zahlmeischterApp: App {
    /// The single app-wide observable state, owned here and injected into the
    /// environment (MV pattern, per CLAUDE.md).
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppFlowView()
                .environment(appState)
                .preferredColorScheme(.light) // V2: light mode only (design.md)
        }
        .modelContainer(PersistenceController.shared)
    }
}

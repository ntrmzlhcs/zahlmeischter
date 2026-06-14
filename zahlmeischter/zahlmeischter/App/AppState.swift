//
//  AppState.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation
import Observation

/// App-wide, view-independent state, injected once via `.environment(_:)` (per
/// CLAUDE.md's MV pattern — not a singleton, not a per-screen view model).
///
/// Holds the currently focused group; transient UI state lives in the views that own
/// it, and SwiftData `@Model` types are observed directly.
@Observable
final class AppState {
    /// The group currently in focus across the app; `nil` until one is selected.
    var activeGroup: ExpenseGroup?

    /// The device owner's display name, remembered across groups so the "Dein Name" field
    /// when creating a group pre-fills. Persisted in `UserDefaults` because "who am I" is a
    /// per-device fact, not group data that should sync (see `Member.isCurrentUser`).
    var myName: String {
        didSet { UserDefaults.standard.set(myName, forKey: Self.myNameDefaultsKey) }
    }

    private static let myNameDefaultsKey = "myName"

    /// Whether the user has finished onboarding. Persisted per-device; gates whether the
    /// launch animation hands off to the intro or straight to the app.
    var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: Self.hasOnboardedDefaultsKey) }
    }

    private static let hasOnboardedDefaultsKey = "hasOnboarded"

    init(activeGroup: ExpenseGroup? = nil) {
        self.activeGroup = activeGroup
        self.myName = UserDefaults.standard.string(forKey: Self.myNameDefaultsKey) ?? ""
        self.hasOnboarded = UserDefaults.standard.bool(forKey: Self.hasOnboardedDefaultsKey)
    }

    /// The member flagged as the current user within `group` — the "you" the dashboard
    /// hero and the default expense payer are framed around. `nil` if the group has none
    /// (e.g. a shared group joined later, before sharing is implemented).
    func currentMember(in group: ExpenseGroup?) -> Member? {
        (group?.members ?? []).first { $0.isCurrentUser && $0.deletedAt == nil }
    }
}

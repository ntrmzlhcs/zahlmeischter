//
//  String+Trimmed.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import Foundation

extension StringProtocol {
    /// Whitespace- and newline-trimmed copy. Used to validate and normalise names/titles
    /// before persisting, so " Lisa " never lands in the store as a distinct value.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

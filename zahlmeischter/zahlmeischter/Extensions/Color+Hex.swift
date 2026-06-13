//
//  Color+Hex.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI

extension Color {
    /// Creates a color from a 6-digit RGB hex string (`"#7C6FE0"` or `"7C6FE0"`).
    /// Lets design.md's gradient stops live in code as the exact hex values from
    /// the spec. Falls back to black on a malformed string.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        let value = UInt64(cleaned, radix: 16) ?? 0
        let red = Double((value & 0xFF0000) >> 16) / 255
        let green = Double((value & 0x00FF00) >> 8) / 255
        let blue = Double(value & 0x0000FF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

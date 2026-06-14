//
//  InlineCheckmarkField.swift
//  zahlmeischter
//
//  The V2 single-line text field (design.md "Text Input & Forms" — deliberate reversal):
//  a persistent label above, an empty placeholder (no example, no label repetition,
//  no pre-filled text), and a trailing teal checkmark **inside** the field that
//  confirms the input and dismisses the keyboard. Used for group name, expense
//  description, and the invite recipient — never the amount field.
//

import SwiftUI
import UIKit

struct InlineCheckmarkField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.fg2).padding(.leading, 2)
            ZStack(alignment: .trailing) {
                TextField("", text: $text)
                    .focused($focused)
                    .keyboardType(keyboard)
                    .submitLabel(submitLabel)
                    .onSubmit { focused = false }
                    .font(.system(size: 16)).foregroundStyle(Theme.fg)
                    .padding(.leading, 14).padding(.trailing, 52)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))

                Button { focused = false } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.accent))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4, y: 2)
                }
                .padding(.trailing, 7)
            }
        }
    }
}

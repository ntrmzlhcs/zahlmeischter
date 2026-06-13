//
//  FormFieldCard.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI

/// A Liquid Glass container with a persistent label above its content — the building
/// block for the group and expense editors.
///
/// The label sits *above* the field on purpose (design.md "Text Input & Forms"):
/// placeholder text disappears once typing starts and isn't reliably surfaced to
/// VoiceOver, so it can't double as a label. Label is **SF** (Body/headline role);
/// the New York serif is reserved for hero amounts.
struct FormFieldCard<Content: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.primary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(in: .rect(cornerRadius: 22))
    }
}

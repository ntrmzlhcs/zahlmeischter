//
//  SharedComponents.swift
//  zahlmeischter
//
//  Small reusable pieces shared across screens: a glass circle button, an uppercase
//  section label, Swiss date formatting, category iconography, and the expense list row.
//

import SwiftUI

// MARK: - Swiss date

enum DateDisplay {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_CH")
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()
    /// Always `dd.MM.yyyy`, regardless of device locale (design.md).
    static func string(_ date: Date) -> String { formatter.string(from: date) }
}

// MARK: - Category iconography

enum ExpenseCategory {
    static func symbol(_ category: String) -> String {
        switch category {
        case "Unterkunft", "Miete": "house.fill"
        case "Transport": "car.fill"
        case "Essen": "fork.knife"
        case "Lebensmittel": "cart.fill"
        case "Aktivität": "star.fill"
        case "Fixkosten": "bolt.fill"
        case "Ausgleich": "arrow.left.arrow.right"
        default: "tag.fill"
        }
    }
}

/// A rounded category tile (tinted background + white glyph).
struct CategoryIcon: View {
    let category: String
    var size: CGFloat = 38
    var corner: CGFloat = 11

    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Theme.categoryColor(category))
            .frame(width: size, height: size)
            .overlay(Image(systemName: ExpenseCategory.symbol(category))
                .font(.system(size: size * 0.42, weight: .semibold)).foregroundStyle(.white))
    }
}

// MARK: - Glass circle button

struct CircleGlassButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 38

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.fg)
                .frame(width: size, height: size)
                .background(Circle().fill(.regularMaterial).overlay(Circle().fill(Color.white.opacity(0.55))))
                .overlay(Circle().strokeBorder(Theme.glassBorder, lineWidth: 0.5))
        }
    }
}

// MARK: - Section label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 13)).tracking(0.5).foregroundStyle(Theme.fg2)
            .padding(.horizontal, 4).padding(.bottom, 10)
    }
}

// MARK: - Expense row

struct ExpenseRow: View {
    let expense: Expense
    let group: ExpenseGroup
    let action: () -> Void

    private var category: String { ExpenseCategory.inferred(expense) }

    private var payerLabel: String {
        guard let payer = expense.payer else { return "—" }
        return payer.isCurrentUser ? "Du hast bezahlt" : "\(payer.name) hat bezahlt"
    }

    private var myShare: Decimal? {
        (expense.splits ?? []).first { $0.member?.isCurrentUser == true && $0.deletedAt == nil }?.shareAmount
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                CategoryIcon(category: category, size: 36, corner: 10)
                VStack(alignment: .leading, spacing: 1) {
                    Text(expense.title).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.fg).lineLimit(1)
                    Text(payerLabel).font(.system(size: 12)).foregroundStyle(Theme.fg2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(CurrencyFormatting.string(expense.amount, code: expense.currency))
                        .font(.serif(16)).monospacedDigit().foregroundStyle(Theme.fg)
                    if let share = myShare {
                        Text("Anteil \(CurrencyFormatting.amountString(share))")
                            .font(.system(size: 11)).monospacedDigit().foregroundStyle(Theme.fg2)
                    }
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension ExpenseCategory {
    /// Best-effort category for an expense. The model doesn't persist a category yet,
    /// so we key off the title for the seeded data and fall back to a default.
    @MainActor static func inferred(_ expense: Expense) -> String {
        let title = expense.title.lowercased()
        switch true {
        case title.contains("miete"): return "Miete"
        case title.contains("ferienwohnung"), title.contains("hotel"), title.contains("unterkunft"): return "Unterkunft"
        case title.contains("mietwagen"), title.contains("zug"), title.contains("ticket"), title.contains("transport"): return "Transport"
        case title.contains("essen"), title.contains("restaurant"), title.contains("abendessen"), title.contains("strandbar"): return "Essen"
        case title.contains("einkauf"), title.contains("supermarkt"), title.contains("wocheneinkauf"): return "Lebensmittel"
        case title.contains("boot"), title.contains("tour"), title.contains("aktivität"): return "Aktivität"
        case title.contains("internet"), title.contains("strom"), title.contains("fixkosten"): return "Fixkosten"
        case title.contains("ausgleich"): return "Ausgleich"
        default: return "Essen"
        }
    }
}

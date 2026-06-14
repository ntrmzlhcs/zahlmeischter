//
//  ReceiptScannerView.swift
//  zahlmeischter
//
//  Receipt OCR (design.md V2): camera frame → scanning → editable line-item review →
//  "Als Ausgabe übernehmen". A simulated capture for now; the camera step is isolated
//  so a real `VNDocumentCameraViewController` + `VNRecognizeTextRequest` flow (CLAUDE.md)
//  can drop in without touching the review UI.
//

import SwiftUI
import SwiftData

struct ReceiptScannerView: View {
    let group: ExpenseGroup
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private enum Step { case camera, scanning, review }
    @State private var step: Step = .camera
    @State private var sweep = false
    @State private var items: [LineItem] = LineItem.sample

    private struct LineItem: Identifiable {
        let id = UUID()
        let name: String
        let price: Decimal
        var on: Bool = true
        static let sample: [LineItem] = [
            .init(name: "Spaghetti Carbonara", price: 18.50),
            .init(name: "Pizza Diavola", price: 16.00),
            .init(name: "Insalata Mista", price: 9.50),
            .init(name: "Vino della Casa", price: 24.00),
            .init(name: "Acqua Minerale", price: 5.50),
        ]
    }

    private var total: Decimal { items.filter(\.on).reduce(Decimal(0)) { $0 + $1.price } }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Beleg scannen", leading: "Abbrechen", onLeading: { dismiss() })
            switch step {
            case .camera: camera
            case .scanning: scanning
            case .review: review
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.bottom, 30)
        .sheetStyle()
    }

    // MARK: Camera

    private var camera: some View {
        VStack(spacing: 0) {
            receiptFrame(showBrackets: true)
            Text("Beleg im Rahmen positionieren").font(.system(size: 13)).foregroundStyle(Theme.fg2).padding(.top, 16)
            Button { capture() } label: {
                Circle().strokeBorder(Theme.fg, lineWidth: 4).frame(width: 68, height: 68)
                    .overlay(Circle().fill(Theme.fg).frame(width: 52, height: 52))
            }
            .padding(.top, 18)
        }
        .padding(.top, 8)
    }

    private var scanning: some View {
        VStack(spacing: 0) {
            receiptFrame(showBrackets: false, showSweep: true)
            HStack(spacing: 10) {
                ProgressView().tint(Theme.accent)
                Text("Beleg wird erkannt …").font(.system(size: 15)).foregroundStyle(Theme.fg2)
            }
            .padding(.top, 20)
        }
        .padding(.top, 8)
    }

    private func receiptFrame(showBrackets: Bool, showSweep: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [Color(hex: "16323A"), Color(hex: "1E2C33")],
                                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: 6) {
                Text("TRATTORIA DA ENZO").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: "2A2A2A"))
                Text("Zürich · \(DateDisplay.string(.now))").font(.system(size: 8, design: .monospaced)).foregroundStyle(.gray)
                Divider().overlay(Color.gray.opacity(0.4))
                ForEach(items) { item in
                    HStack {
                        Text(item.name).font(.system(size: 9, design: .monospaced))
                        Spacer()
                        Text(CurrencyFormatting.amountString(item.price)).font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundStyle(Color(hex: "2A2A2A"))
                }
                Divider().overlay(Color.gray.opacity(0.4))
                HStack {
                    Text("TOTAL").font(.system(size: 10, weight: .bold, design: .monospaced))
                    Spacer()
                    Text(CurrencyFormatting.amountString(items.reduce(Decimal(0)) { $0 + $1.price }))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color(hex: "2A2A2A"))
            }
            .padding(14)
            .frame(width: 168)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: "F3F1EA")))
            .rotationEffect(.degrees(showBrackets ? -3 : 0))
            .shadow(color: .black.opacity(0.5), radius: 18, y: 12)

            if showBrackets {
                ForEach(0..<4, id: \.self) { corner in cornerBracket(corner) }
            }
            if showSweep {
                Rectangle().fill(LinearGradient(colors: [.clear, Color(hex: "3FD2C0"), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 3).shadow(color: Color(hex: "3FD2C0").opacity(0.6), radius: 8)
                    .offset(y: sweep ? 170 : -170)
                    .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { sweep = true } }
            }
        }
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func cornerBracket(_ corner: Int) -> some View {
        let isTop = corner < 2
        let isLeading = corner % 2 == 0
        return Path { p in
            p.move(to: CGPoint(x: 0, y: 20)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.white, lineWidth: 3)
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(Double(isTop ? 0 : 180) + (isLeading == isTop ? 0 : (isTop ? 90 : -90))))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(isTop: isTop, isLeading: isLeading))
        .padding(26)
    }

    private func alignment(isTop: Bool, isLeading: Bool) -> Alignment {
        switch (isTop, isLeading) {
        case (true, true): .topLeading
        case (true, false): .topTrailing
        case (false, true): .bottomLeading
        case (false, false): .bottomTrailing
        }
    }

    // MARK: Review

    private var review: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("Trattoria da Enzo").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg)
                Text("\(items.count) Positionen erkannt · tippe zum Ausschliessen").font(.system(size: 13)).foregroundStyle(Theme.fg2)
            }
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach($items) { $item in
                    if item.id != items.first?.id { Divider().overlay(Theme.line) }
                    Button { item.on.toggle() } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(item.on ? Theme.accent : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(item.on ? Theme.accent : Theme.fg3, lineWidth: 1.5))
                                .frame(width: 22, height: 22)
                                .overlay(item.on ? Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white) : nil)
                            Text(item.name).font(.system(size: 15)).foregroundStyle(Theme.fg)
                                .strikethrough(!item.on, color: Theme.fg3)
                            Spacer()
                            Text(CurrencyFormatting.amountString(item.price)).font(.serif(15)).monospacedDigit().foregroundStyle(Theme.fg)
                        }
                        .padding(.horizontal, 15).padding(.vertical, 13).opacity(item.on ? 1 : 0.5).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.glass2))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
            .padding(.top, 12)

            HStack {
                Text("Summe").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg)
                Spacer()
                Text(CurrencyFormatting.string(total, code: .chf)).font(.serif(22)).monospacedDigit().foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 6).padding(.top, 14)

            Button { apply() } label: {
                Text("Als Ausgabe übernehmen").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 10, y: 8)
            }
            .padding(.top, 12)
        }
    }

    // MARK: Actions

    private func capture() {
        step = .scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation { step = .review }
        }
    }

    private func apply() {
        let members = (group.members ?? []).filter { $0.deletedAt == nil }
        let expense = Expense(title: "Trattoria da Enzo", amount: total, currency: .chf, splitMethod: .equal, date: .now)
        expense.group = group
        expense.payer = members.first { $0.isCurrentUser } ?? members.first
        modelContext.insert(expense)
        let shares = SplitCalculator.equalShares(of: total, among: max(members.count, 1))
        for (member, share) in zip(members, shares) {
            let entry = ExpenseSplit(shareAmount: share)
            entry.expense = expense
            entry.member = member
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}

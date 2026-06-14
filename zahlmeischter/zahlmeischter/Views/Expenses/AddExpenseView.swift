//
//  AddExpenseView.swift
//  zahlmeischter
//
//  Add Expense (design.md V2): a large New York amount with a custom keypad as the
//  focal point, currency chips (CHF/EUR/USD), an inline-checkmark description, a
//  group-scoped "Bezahlt von" dropdown, an editable participant list (remove / re-add /
//  add a brand-new person), an Aufteilung selector, and a Beleg-scannen entry point.
//  Currency is booked on the expense itself (no group currency).
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    let group: ExpenseGroup
    let open: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amount = "0"
    @State private var currency: CurrencyCode = .chf
    @State private var title = ""
    @State private var payerID: UUID?
    @State private var payerOpen = false
    @State private var split: SplitMethod = .equal
    @State private var participantIDs: [UUID] = []
    @State private var addOpen = false
    @State private var newName = ""

    @FocusState private var titleFocused: Bool

    private var members: [Member] {
        (group.members ?? []).filter { $0.deletedAt == nil }.sorted { $0.createdAt < $1.createdAt }
    }
    private var participants: [Member] { participantIDs.compactMap { id in members.first { $0.uuid == id } } }
    private var payer: Member? { members.first { $0.uuid == payerID } }
    private var amountValue: Decimal { Decimal(string: amount) ?? 0 }
    private var canSave: Bool { amountValue > 0 && !participants.isEmpty }

    private let keys = ["1","2","3","4","5","6","7","8","9",".","0","del"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Neue Ausgabe", onLeading: { dismiss() },
                            trailing: "Sichern", trailingEnabled: canSave, onTrailing: save)

                VStack(spacing: 4) {
                    Text(group.name).font(.system(size: 13)).foregroundStyle(Theme.fg2)
                    Text(amount).font(.serif(54)).monospacedDigit()
                        .foregroundStyle(amountValue > 0 ? Theme.fg : Theme.fg3)
                }
                .frame(maxWidth: .infinity).padding(.top, 14)

                fieldLabel("Währung")
                currencyChips

                InlineCheckmarkField(label: "Beschreibung", text: $title).padding(.top, 14)

                payerAndDate.padding(.top, 12)
                if payerOpen { payerDropdown.padding(.top, 8) }

                fieldLabel("Aufteilung").padding(.top, 4)
                splitSelector
                sharesList.padding(.top, 10)
                addPersonControl
                if addOpen { addPersonPanel.padding(.top, 4) }

                scanButton.padding(.top, 8)
                keypad.padding(.top, 12)
            }
            .padding(.horizontal, 22).padding(.bottom, 30)
        }
        .sheetStyle()
        .onAppear(perform: setup)
    }

    // MARK: Pieces

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(Theme.fg2)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 14).padding(.bottom, 7).padding(.leading, 2)
    }

    private var currencyChips: some View {
        HStack(spacing: 5) {
            ForEach(CurrencyCode.allCases) { code in
                Button { currency = code } label: {
                    Text(code.isoCode).font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(currency == code ? .white : Theme.fg)
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background(RoundedRectangle(cornerRadius: 10).fill(currency == code ? Theme.accent : .clear))
                }
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
    }

    private var payerAndDate: some View {
        HStack(spacing: 10) {
            Button { withAnimation(.easeOut(duration: 0.2)) { payerOpen.toggle() } } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bezahlt von").font(.system(size: 12)).foregroundStyle(Theme.fg2)
                    HStack(spacing: 8) {
                        if let payer { Avatar(payer, in: group, size: 22) }
                        Text(payer?.isCurrentUser == true ? "Du" : (payer?.name ?? "—"))
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg).lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.fg2)
                            .rotationEffect(.degrees(payerOpen ? 180 : 0))
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(payerOpen ? Theme.accent : Theme.glassBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Datum").font(.system(size: 12)).foregroundStyle(Theme.fg2)
                Text(DateDisplay.string(.now)).font(.system(size: 15, weight: .semibold)).monospacedDigit().foregroundStyle(Theme.fg)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
        }
    }

    private var payerDropdown: some View {
        VStack(spacing: 0) {
            ForEach(Array(members.enumerated()), id: \.element.uuid) { index, member in
                if index > 0 { Divider().overlay(Theme.line) }
                Button {
                    payerID = member.uuid
                    withAnimation(.easeOut(duration: 0.2)) { payerOpen = false }
                } label: {
                    HStack(spacing: 11) {
                        Avatar(member, in: group, size: 30)
                        Text(member.isCurrentUser ? "Du" : member.name)
                            .font(.system(size: 15, weight: payerID == member.uuid ? .semibold : .regular)).foregroundStyle(Theme.fg)
                        Spacer()
                        if payerID == member.uuid {
                            Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .glassCard(cornerRadius: 14, shadow: false)
    }

    private var splitSelector: some View {
        HStack(spacing: 5) {
            ForEach(SplitMethod.allCases) { method in
                Button { split = method } label: {
                    Text(method.label).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(split == method ? .white : Theme.fg)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(split == method ? Theme.accent : .clear))
                }
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
    }

    private var sharesList: some View {
        let shares = SplitCalculator.equalShares(of: amountValue, among: max(participants.count, 1))
        return VStack(spacing: 2) {
            ForEach(Array(participants.enumerated()), id: \.element.uuid) { index, member in
                HStack(spacing: 10) {
                    Avatar(member, in: group, size: 30)
                    Text(member.isCurrentUser ? "Du" : member.name).font(.system(size: 14)).foregroundStyle(Theme.fg)
                    Spacer()
                    Text(CurrencyFormatting.amountString(index < shares.count ? shares[index] : 0))
                        .font(.serif(15)).monospacedDigit().foregroundStyle(Theme.fg2)
                    Button { removeParticipant(member.uuid) } label: {
                        Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.negative)
                            .frame(width: 26, height: 26).background(Circle().fill(Theme.negative.opacity(0.12)))
                    }
                    .opacity(participants.count > 1 ? 1 : 0.3)
                    .disabled(participants.count <= 1)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var addPersonControl: some View {
        Button { withAnimation(.easeOut(duration: 0.2)) { addOpen.toggle() } } label: {
            HStack(spacing: 9) {
                Image(systemName: "plus").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 1.5, dash: [3])))
                    .rotationEffect(.degrees(addOpen ? 45 : 0))
                Text("Person hinzufügen").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                Spacer()
            }
            .padding(.vertical, 8).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addPersonPanel: some View {
        let reAddable = members.filter { !participantIDs.contains($0.uuid) }
        return VStack(spacing: 0) {
            ForEach(Array(reAddable.enumerated()), id: \.element.uuid) { index, member in
                if index > 0 { Divider().overlay(Theme.line) }
                Button { addParticipant(member.uuid) } label: {
                    HStack(spacing: 11) {
                        Avatar(member, in: group, size: 30)
                        Text(member.isCurrentUser ? "Du" : member.name).font(.system(size: 15)).foregroundStyle(Theme.fg)
                        Spacer()
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.accent)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if !reAddable.isEmpty { Divider().overlay(Theme.line) }
            HStack(spacing: 11) {
                Image(systemName: "person").font(.system(size: 14)).foregroundStyle(Theme.fg3)
                    .frame(width: 30, height: 30).overlay(Circle().strokeBorder(Theme.fg3, style: StrokeStyle(lineWidth: 1.5, dash: [3])))
                TextField("Neue Person …", text: $newName).font(.system(size: 15)).foregroundStyle(Theme.fg)
                Button { addNewPerson() } label: {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34).background(Circle().fill(newName.trimmed.isEmpty ? Theme.fg3 : Theme.accent))
                }
                .disabled(newName.trimmed.isEmpty)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
        }
        .glassCard(cornerRadius: 14, shadow: false)
    }

    private var scanButton: some View {
        Button { open(.sheet(.ocr(group))) } label: {
            Label("Beleg scannen", systemImage: "doc.viewfinder")
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.fg)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
        }
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Button { tapKey(key) } label: {
                    Group {
                        if key == "del" { Image(systemName: "delete.left").font(.system(size: 20)) }
                        else { Text(key).font(.system(size: 23, weight: .medium)) }
                    }
                    .foregroundStyle(Theme.fg)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.glass2))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.glassBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Actions

    private func setup() {
        participantIDs = members.map(\.uuid)
        payerID = (members.first { $0.isCurrentUser } ?? members.first)?.uuid
    }

    private func tapKey(_ key: String) {
        switch key {
        case "del": amount = amount.count <= 1 ? "0" : String(amount.dropLast())
        case ".": if !amount.contains(".") { amount += "." }
        default:
            if amount == "0" { amount = key }
            else if let decimals = amount.split(separator: ".").last, amount.contains("."), decimals.count >= 2 { return }
            else { amount += key }
        }
    }

    private func removeParticipant(_ id: UUID) {
        guard participantIDs.count > 1 else { return }
        participantIDs.removeAll { $0 == id }
    }

    private func addParticipant(_ id: UUID) {
        if !participantIDs.contains(id) { participantIDs.append(id) }
    }

    private func addNewPerson() {
        let name = newName.trimmed
        guard !name.isEmpty else { return }
        let member = Member(name: name)
        member.group = group
        modelContext.insert(member)
        participantIDs.append(member.uuid)
        newName = ""
        withAnimation { addOpen = false }
    }

    private func save() {
        guard canSave else { return }
        let expense = Expense(title: title.trimmed.isEmpty ? "Ausgabe" : title.trimmed,
                              amount: amountValue, currency: currency, splitMethod: split, date: .now)
        expense.group = group
        expense.payer = payer
        modelContext.insert(expense)

        let shares = SplitCalculator.equalShares(of: amountValue, among: participants.count)
        for (member, share) in zip(participants, shares) {
            let entry = ExpenseSplit(shareAmount: share)
            entry.expense = expense
            entry.member = member
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}

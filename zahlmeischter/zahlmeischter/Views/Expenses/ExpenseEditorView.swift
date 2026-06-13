//
//  ExpenseEditorView.swift
//  zahlmeischter
//
//  Created by Martin on 13.06.2026.
//

import SwiftUI
import SwiftData

/// Adds a new `Expense` to a group and divides it among the chosen participants.
///
/// The amount is the focal point in New York serif (the Display role); everything else is
/// SF. The split method (equal / percentage / custom) drives per-participant inputs, and
/// `SplitCalculator` resolves the exact per-member share amounts on save. The receipt-scan
/// entry point is intentionally out of scope here — OCR is the separate, parallel V1 feature.
struct ExpenseEditorView: View {
    let group: ExpenseGroup

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var title = ""
    @State private var payerID: UUID?
    @State private var date: Date = .now
    @State private var currency: CurrencyCode
    @State private var splitMethod: SplitMethod = .equal
    @State private var includedMemberIDs: Set<UUID>
    @State private var percentText: [UUID: String] = [:]
    @State private var customText: [UUID: String] = [:]
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case amount, title, percent(UUID), custom(UUID)
    }

    init(group: ExpenseGroup) {
        self.group = group
        let active = Self.activeMembers(of: group)
        _includedMemberIDs = State(initialValue: Set(active.map(\.uuid)))
        _payerID = State(initialValue: (active.first { $0.isCurrentUser } ?? active.first)?.uuid)
        _currency = State(initialValue: group.currency)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        amountCard
                        FormFieldCard(label: "Beschreibung") {
                            TextField("", text: $title)
                                .focused($focusedField, equals: .title)
                                .accessibilityLabel(Text("Beschreibung"))
                        }
                        detailsCard
                        splitCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Ausgabe hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Amount (focal)

    private var amountCard: some View {
        VStack(spacing: 16) {
            Text("Betrag")
                .font(.footnote)
                .fontWeight(.medium)
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(currency.isoCode)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .monospacedDigit()
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .accessibilityLabel(Text("Betrag"))
            }

            Picker("Währung", selection: $currency) {
                ForEach(CurrencyCode.allCases) { code in
                    Text(code.isoCode).tag(code)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 28))
    }

    // MARK: - Payer + date

    private var detailsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bezahlt von")
                    .font(.headline)
                Spacer()
                Picker("Bezahlt von", selection: $payerID) {
                    ForEach(members) { member in
                        Text(member.name).tag(member.uuid as UUID?)
                    }
                }
                .labelsHidden()
            }

            Divider().opacity(0.4)

            HStack {
                Text("Datum")
                    .font(.headline)
                Spacer()
                DatePicker("Datum", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "de_CH"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

    // MARK: - Split

    private var splitCard: some View {
        FormFieldCard(label: "Aufteilung") {
            VStack(spacing: 16) {
                Picker("Aufteilung", selection: $splitMethod) {
                    ForEach(SplitMethod.allCases) { method in
                        Text(method.label).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: splitMethod) { _, newValue in
                    prefillSplitInputs(for: newValue)
                }

                VStack(spacing: 12) {
                    ForEach(members) { member in
                        participantRow(member)
                    }
                }

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private func participantRow(_ member: Member) -> some View {
        let isIncluded = includedMemberIDs.contains(member.uuid)
        HStack(spacing: 12) {
            Button {
                toggle(member)
            } label: {
                Image(systemName: isIncluded ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isIncluded ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(member.name))
            .accessibilityValue(Text(isIncluded ? "dabei" : "nicht dabei"))

            Text(member.name)
                .font(.body)
                .foregroundStyle(isIncluded ? .primary : .secondary)

            Spacer(minLength: 8)

            if isIncluded {
                trailingInput(for: member)
            }
        }
    }

    @ViewBuilder
    private func trailingInput(for member: Member) -> some View {
        switch splitMethod {
        case .equal:
            Text(equalShareString(for: member))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        case .percentage:
            HStack(spacing: 4) {
                TextField("0", text: percentBinding(member.uuid))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 64)
                    .focused($focusedField, equals: .percent(member.uuid))
                    .accessibilityLabel(Text("Prozentanteil von \(member.name)"))
                Text("%").foregroundStyle(.secondary)
            }
        case .custom:
            TextField("0.00", text: customBinding(member.uuid))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 96)
                .focused($focusedField, equals: .custom(member.uuid))
                .accessibilityLabel(Text("Betrag von \(member.name)"))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Abbrechen") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Speichern") { save() }
                .disabled(!canSave)
        }
        // design.md: confirm/cancel live in the keyboard accessory bar (never floating
        // circular buttons); they also stay in the nav bar for when the keyboard is down.
        ToolbarItemGroup(placement: .keyboard) {
            Button("Abbrechen") { dismiss() }
            Spacer()
            Button("Fertig") { focusedField = nil }
                .fontWeight(.semibold)
        }
    }

    // MARK: - Members

    private var members: [Member] { Self.activeMembers(of: group) }

    private var includedMembers: [Member] {
        members.filter { includedMemberIDs.contains($0.uuid) }
    }

    private static func activeMembers(of group: ExpenseGroup) -> [Member] {
        (group.members ?? [])
            .filter { $0.deletedAt == nil }
            .sorted { lhs, rhs in
                if lhs.isCurrentUser != rhs.isCurrentUser { return lhs.isCurrentUser }
                return lhs.createdAt < rhs.createdAt
            }
    }

    private func toggle(_ member: Member) {
        if includedMemberIDs.contains(member.uuid) {
            includedMemberIDs.remove(member.uuid)
        } else {
            includedMemberIDs.insert(member.uuid)
        }
    }

    // MARK: - Parsing & bindings

    private func percentBinding(_ id: UUID) -> Binding<String> {
        Binding(get: { percentText[id] ?? "" }, set: { percentText[id] = $0 })
    }

    private func customBinding(_ id: UUID) -> Binding<String> {
        Binding(get: { customText[id] ?? "" }, set: { customText[id] = $0 })
    }

    /// Parses user input that may use a comma or apostrophe (Swiss grouping) into a `Decimal`.
    private func decimalValue(_ text: String?) -> Decimal? {
        guard let text, !text.trimmed.isEmpty else { return nil }
        let normalized = text
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private var amountValue: Decimal? { decimalValue(amountText) }

    private var percentages: [Decimal] {
        includedMembers.map { decimalValue(percentText[$0.uuid]) ?? 0 }
    }

    private var customShares: [Decimal] {
        includedMembers.map { decimalValue(customText[$0.uuid]) ?? 0 }
    }

    private func equalShareString(for member: Member) -> String {
        guard let amount = amountValue, amount > 0,
              let index = includedMembers.firstIndex(where: { $0.uuid == member.uuid })
        else { return CurrencyFormatting.string(0, code: currency) }
        let shares = SplitCalculator.equalShares(of: amount, among: includedMembers.count)
        return CurrencyFormatting.string(shares[index], code: currency)
    }

    // MARK: - Validation

    private var splitIsValid: Bool {
        guard !includedMembers.isEmpty else { return false }
        switch splitMethod {
        case .equal:
            return true
        case .percentage:
            return SplitCalculator.percentagesAreValid(percentages)
        case .custom:
            guard let amount = amountValue else { return false }
            return SplitCalculator.customIsValid(shares: customShares, total: amount)
        }
    }

    private var canSave: Bool {
        guard let amount = amountValue, amount > 0 else { return false }
        guard !title.trimmed.isEmpty else { return false }
        return splitIsValid
    }

    private var validationMessage: LocalizedStringKey? {
        guard !includedMembers.isEmpty else { return "Wähle mindestens eine Person." }
        switch splitMethod {
        case .equal:
            return nil
        case .percentage:
            return SplitCalculator.percentagesAreValid(percentages)
                ? nil : "Die Prozente müssen zusammen 100 % ergeben."
        case .custom:
            guard let amount = amountValue, amount > 0 else { return nil }
            return SplitCalculator.customIsValid(shares: customShares, total: amount)
                ? nil : "Die Beträge müssen zusammen \(CurrencyFormatting.string(amount, code: currency)) ergeben."
        }
    }

    // MARK: - Prefill

    /// When switching to percentage/custom, seed empty inputs with an equal distribution so
    /// the form starts in a valid state instead of summing to zero.
    private func prefillSplitInputs(for method: SplitMethod) {
        let included = includedMembers
        guard !included.isEmpty else { return }
        switch method {
        case .percentage:
            guard included.allSatisfy({ (percentText[$0.uuid] ?? "").trimmed.isEmpty }) else { return }
            let shares = SplitCalculator.equalShares(of: 100, among: included.count)
            for (index, member) in included.enumerated() {
                percentText[member.uuid] = Self.plainString(shares[index])
            }
        case .custom:
            guard let amount = amountValue, amount > 0,
                  included.allSatisfy({ (customText[$0.uuid] ?? "").trimmed.isEmpty }) else { return }
            let shares = SplitCalculator.equalShares(of: amount, among: included.count)
            for (index, member) in included.enumerated() {
                customText[member.uuid] = Self.plainString(shares[index])
            }
        case .equal:
            break
        }
    }

    private static func plainString(_ value: Decimal) -> String {
        plainFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private static let plainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    // MARK: - Persistence

    private func save() {
        guard canSave, let amount = amountValue else { return }
        let included = includedMembers

        let resolvedShares: [Decimal]
        let percentsForSplits: [Decimal?]
        switch splitMethod {
        case .equal:
            resolvedShares = SplitCalculator.equalShares(of: amount, among: included.count)
            percentsForSplits = Array(repeating: nil, count: included.count)
        case .percentage:
            let pcts = percentages
            resolvedShares = SplitCalculator.percentageShares(of: amount, percentages: pcts)
            percentsForSplits = pcts.map { Optional($0) }
        case .custom:
            resolvedShares = customShares
            percentsForSplits = Array(repeating: nil, count: included.count)
        }

        let expense = Expense(
            title: title.trimmed,
            amount: amount,
            currency: currency,
            splitMethod: splitMethod,
            date: date
        )
        expense.group = group
        if let payerID, let payer = members.first(where: { $0.uuid == payerID }) {
            expense.payer = payer
        }
        modelContext.insert(expense)

        for (index, member) in included.enumerated() {
            let split = ExpenseSplit(
                shareAmount: resolvedShares[index],
                percent: percentsForSplits[index],
                expense: expense,
                member: member
            )
            modelContext.insert(split)
        }

        dismiss()
    }
}

#Preview {
    let container = PersistenceController.preview
    let group = ExpenseGroup(name: "Mallorca")
    container.mainContext.insert(group)
    let me = Member(name: "Martin", isCurrentUser: true); me.group = group
    let lisa = Member(name: "Lisa"); lisa.group = group
    let marco = Member(name: "Marco"); marco.group = group
    container.mainContext.insert(me)
    container.mainContext.insert(lisa)
    container.mainContext.insert(marco)
    return ExpenseEditorView(group: group)
        .modelContainer(container)
}

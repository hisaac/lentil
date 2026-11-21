import SwiftUI

private func amountValue(_ input: String, kind: Kind, locale: Locale) -> Decimal? {
    let parts = input.components(separatedBy: locale.decimalSeparator ?? ".")
    let precision = kind == .money ? 2 : 3
    guard parts.count <= 2, parts[0].count <= 12,
          parts.count == 1 || parts[1].count <= precision,
          parts.allSatisfy({ $0.allSatisfy(\.isNumber) }),
          let value = Decimal(string: input, locale: locale), value > 0 else { return nil }
    return value
}

struct NewLoan: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var direction = Direction.lent
    @State private var kind = Kind.item
    @State private var name = ""
    @State private var person = ""
    @State private var amount = ""
    @State private var currency = "USD"
    @State private var start = LoanDay.today
    @State private var due = LoanDay.calendar.date(byAdding: .day, value: 7, to: LoanDay.today)!
    @State private var note = ""
    @State private var error: String?

    private var loan: Loan? {
        let person = person.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !person.isEmpty, kind == .money || !name.isEmpty,
              let value = amountValue(amount, kind: kind, locale: locale), due >= start else { return nil }
        return Loan(direction: direction, kind: kind, name: kind == .item ? name : "", person: person,
                    amount: value, currency: currency, start: start, due: due, note: note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Direction", selection: $direction) {
                        ForEach(Direction.allCases, id: \.self) { Text($0.rawValue) }
                    }.pickerStyle(.segmented)
                    Picker("Type", selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { Text($0.rawValue) }
                    }.pickerStyle(.segmented)
                    TextField(direction == .lent ? "Lent to" : "Borrowed from", text: $person)
                    if kind == .item { TextField("Item name", text: $name) }
                    TextField(kind == .money ? "Amount" : "Quantity", text: $amount).keyboardType(.decimalPad)
                    if kind == .money {
                        Picker("Currency", selection: $currency) {
                            ForEach(["USD", "CAD", "EUR", "GBP", "AUD"], id: \.self) { Text($0) }
                        }
                    }
                }
                Section {
                    DatePicker("Start date", selection: $start, in: ...LoanDay.today, displayedComponents: .date)
                        .onChange(of: start) { _, date in due = max(due, date) }
                    DatePicker("Due date", selection: $due, in: start..., displayedComponents: .date)
                }
                Section { TextField("Note (optional)", text: $note, axis: .vertical) }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("New loan").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let loan else { return }
                        do { try store.save(loan); dismiss() }
                        catch { self.error = error.localizedDescription }
                    }.disabled(loan == nil)
                }
            }
        }
    }
}

struct ReturnForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let loan: Loan
    @State private var amount = ""
    @State private var date = LoanDay.today
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Remaining", value: loan.display(loan.remaining))
                TextField("Amount returned", text: $amount).keyboardType(.decimalPad)
                Button("Return all") {
                    amount = loan.remaining.formatted(.number.locale(locale).grouping(.never))
                }
                DatePicker("Return date", selection: $date,
                           in: (loan.returns.last?.date ?? loan.start)...max(LoanDay.today, loan.returns.last?.date ?? loan.start),
                           displayedComponents: .date)
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Record return").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = amountValue(amount, kind: loan.kind, locale: locale) else {
                            error = "Enter a positive amount with up to \(loan.kind == .money ? 2 : 3) decimal places."
                            return
                        }
                        do {
                            var updated = loan
                            try updated.record(value, on: date, today: LoanDay.today)
                            try store.save(updated)
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
        }
    }
}

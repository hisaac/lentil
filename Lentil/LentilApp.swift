import SwiftUI

@main
struct LentilApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            LoanList()
                .environment(store)
                .environment(\.timeZone, LoanDay.zone)
        }
    }
}

struct LoanList: View {
    @Environment(Store.self) private var store
    @State private var adding = false
    var history = false

    private var loans: [Loan] {
        store.loans.filter { ($0.remaining == 0) == history }.sorted {
            if history { return $0.returns.last!.date > $1.returns.last!.date }
            return $0.due < $1.due
        }
    }

    var body: some View {
        if history { content } else { NavigationStack { content } }
    }

    private var content: some View {
        List {
            ForEach(Direction.allCases, id: \.self) { direction in
                let group = loans.filter { $0.direction == direction }
                if !group.isEmpty {
                    Section(direction.rawValue) {
                        ForEach(group) { loan in
                            NavigationLink {
                                LoanDetail(id: loan.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(loan.kind == .item ? loan.name : loan.display(loan.amount))
                                        .font(.headline)
                                    Text(loan.person)
                                    if history, let last = loan.returns.last {
                                        Text("Returned \(last.date, format: dateStyle)")
                                    } else {
                                        Text("\(loan.display(loan.remaining)) left · Due \(loan.due, format: dateStyle)")
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if let error = store.loadError {
                ContentUnavailableView("Couldn’t open loans", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if loans.isEmpty {
                ContentUnavailableView(history ? "No returned loans" : "No open loans",
                                       systemImage: history ? "clock" : "tray",
                                       description: Text(history ? "Fully returned loans appear here." : "Tap + to record something you lent or borrowed."))
            }
        }
        .navigationTitle(history ? "History" : "Lentil")
        .toolbar {
            if !history {
                ToolbarItem(placement: .topBarLeading) { NavigationLink("History") { LoanList(history: true) } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add loan", systemImage: "plus") { adding = true }.disabled(store.loadError != nil)
                }
            }
        }
        .sheet(isPresented: $adding) { NewLoan() }
    }
}

let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: LoanDay.zone)

struct LoanDetail: View {
    @Environment(Store.self) private var store
    @State private var recording = false
    let id: UUID

    var body: some View {
        if let loan = store.loans.first(where: { $0.id == id }) {
            List {
                Section {
                    LabeledContent(loan.direction.rawValue, value: loan.person)
                    LabeledContent("Original amount", value: loan.display(loan.amount))
                    LabeledContent("Remaining", value: loan.display(loan.remaining))
                    LabeledContent("Start date", value: loan.start.formatted(dateStyle))
                    LabeledContent("Due date", value: loan.due.formatted(dateStyle))
                    if !loan.note.isEmpty { LabeledContent("Note", value: loan.note) }
                }
                Section("Returns") {
                    ForEach(loan.returns.reversed()) { entry in
                        LabeledContent(entry.date.formatted(dateStyle), value: loan.display(entry.amount))
                    }
                    if loan.remaining > 0 { Button("Record return") { recording = true } }
                }
            }
            .navigationTitle(loan.kind == .money ? "Money loan" : loan.name)
            .sheet(isPresented: $recording) { ReturnForm(loan: loan) }
        }
    }
}

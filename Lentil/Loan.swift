import Foundation

enum Direction: String, Codable, CaseIterable {
    case lent = "I lent", borrowed = "I borrowed"
}

enum Kind: String, Codable, CaseIterable {
    case item = "Item", money = "Money"
}

// Store civil dates at midnight UTC so travel and daylight saving cannot shift a loan date.
enum LoanDay {
    static let zone = TimeZone(secondsFromGMT: 0)!
    static var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = zone
        return result
    }
    static var today: Date {
        let local = Calendar(identifier: .gregorian)
        return calendar.date(from: local.dateComponents([.year, .month, .day], from: Date()))!
    }
}

struct LoanError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

struct LoanReturn: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let amount: Decimal
}

struct Loan: Identifiable, Codable {
    var id = UUID()
    let direction: Direction
    let kind: Kind
    let name: String
    let person: String
    let amount: Decimal
    let currency: String
    let start: Date
    let due: Date?
    let note: String
    var returns: [LoanReturn] = []

    func balance(on date: Date) -> Decimal {
        returns.filter { $0.date <= date }.reduce(amount) { $0 - $1.amount }
    }

    var remaining: Decimal { returns.reduce(amount) { $0 - $1.amount } }

    func display(_ value: Decimal) -> String {
        kind == .money ? value.formatted(.currency(code: currency)) : value.formatted(.number)
    }

    mutating func record(_ value: Decimal, on date: Date, today: Date) throws {
        guard date >= (returns.last?.date ?? start), date <= today else {
            throw LoanError("Choose a date from the latest entry through today.")
        }
        guard value > 0, value <= remaining else {
            throw LoanError("Enter a return greater than zero and within the remaining balance.")
        }
        returns.append(LoanReturn(date: date, amount: value))
    }
}

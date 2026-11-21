import Foundation

@main
struct BalanceTests {
    static func main() throws {
        let start = Date(timeIntervalSince1970: 0)
        func day(_ n: Int) -> Date { start.addingTimeInterval(Double(n * 86400)) }
        var loan = Loan(direction: .lent, kind: .money, name: "", person: "Maya", amount: 40,
                        currency: "USD", start: start, due: day(15), note: "")
        try loan.record(10, on: day(10), today: day(20))
        precondition(loan.balance(on: day(20)) == 30)
        precondition(loan.balance(on: day(5)) == 40)
        for (amount, date) in [(Decimal(0), day(20)), (31, day(20)), (1, day(9)), (1, day(21))] {
            do { try loan.record(amount, on: date, today: day(20)); fatalError("Accepted invalid return") }
            catch {}
        }
        try loan.record(30, on: day(20), today: day(20))
        precondition(loan.balance(on: day(100)) == 0)
        var apples = Loan(direction: .borrowed, kind: .item, name: "Apples", person: "Sam", amount: 2,
                          currency: "USD", start: start, due: day(1), note: "")
        try apples.record(1, on: start, today: start)
        precondition(apples.balance(on: day(30)) == 1)
        let restored = try JSONDecoder().decode(Loan.self, from: JSONEncoder().encode(apples))
        precondition(restored.balance(on: day(30)) == 1)
        precondition(restored.due == day(1))
        var fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(apples)) as! [String: Any]
        fields.removeValue(forKey: "due")
        let undated = try JSONDecoder().decode(Loan.self, from: JSONSerialization.data(withJSONObject: fields))
        precondition(undated.due == nil)
        print("Balance and storage round-trip checks passed")
    }
}

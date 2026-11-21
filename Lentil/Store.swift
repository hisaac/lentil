import Foundation
import Observation

@Observable
final class Store {
    private(set) var loans: [Loan] = []
    private(set) var loadError: String?
    private let url: URL

    init() {
        let directory = URL.applicationSupportDirectory.appending(path: "Lentil")
        url = directory.appending(path: "loans.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: url.path) {
                loans = try JSONDecoder().decode([Loan].self, from: Data(contentsOf: url))
            }
        } catch { loadError = error.localizedDescription }
    }

    func save(_ loan: Loan) throws {
        if let loadError { throw LoanError(loadError) }
        var updated = loans
        if let index = updated.firstIndex(where: { $0.id == loan.id }) {
            updated[index] = loan
        } else {
            updated.append(loan)
        }
        try JSONEncoder().encode(updated).write(to: url, options: .atomic)
        loans = updated
    }
}

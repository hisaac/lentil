# Lentil

A personal, on-device tracker for things you lend and borrow. Open Lentil.xcodeproj in Xcode and run the Lentil scheme on an iPhone with iOS 27.2 or later.

Record partial returns against the original quantity or amount. Fully returned loans move to History.

## Verification

Use Product → Test in Xcode to exercise lending money, borrowing items, recording partial returns, reopening the app, and moving a completed loan to History.

Run the standalone balance checks from the repository root:

```sh
swiftc Lentil/Loan.swift Tests/BalanceTests.swift -o /tmp/lentil-balance-tests
/tmp/lentil-balance-tests
```

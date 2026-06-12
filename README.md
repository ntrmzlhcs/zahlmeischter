# zahlmeischter

**zahlmeischter** (Swiss German: roughly "the bill master" — the person who
ends up fronting the tab and then has to chase everyone for their share) is a
Splitwise-style expense-splitting app for groups: dinners, trips, shared
households, travel.

> ⚠️ Early development. Not yet released on the App Store.

## What it does

- Create a group, log shared expenses, split them (equally, by percentage, or
  custom amounts), and see who owes whom.
- Settle up with as few payments as possible.
- Multi-currency support (CHF + EUR for V1).
- Scan receipts to auto-itemize expenses (OCR).

## Tech stack

- **UI**: SwiftUI (iOS 26.4+)
- **Persistence**: SwiftData
- **Sync**: CloudKit (private database + CKShare for group sharing)
- **OCR**: Vision / VisionKit (no third-party dependencies)

See [CLAUDE.md](CLAUDE.md) for the full architecture, data model, and
conventions used in this project.

## Build & run

```bash
xcodebuild -project zahlmeischter/zahlmeischter.xcodeproj -scheme zahlmeischter \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Run tests

```bash
xcodebuild -project zahlmeischter/zahlmeischter.xcodeproj -scheme zahlmeischter \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

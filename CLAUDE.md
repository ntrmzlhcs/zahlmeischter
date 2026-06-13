# CLAUDE.md

## Project Overview

**zahlmeischter** (Swiss German: roughly "the bill master" — the person who ends
up fronting the tab and then has to chase everyone for their share) is a
Splitwise-style expense-splitting app for groups: dinners, trips, shared
households, travel.

- **Core idea**: create a group, log shared expenses, split them (equally, by
  percentage, or custom amounts), and see who owes whom — then settle up with
  as few payments as possible.
- **Tone**: detailed branding/copy/visual design decisions will live in a
  future `design.md` — this file focuses on technical architecture only.
- **Primary users**: small friend groups, households, and travel groups —
  likely CH/EU-based, hence the multi-currency emphasis (CHF + EUR at minimum).

## Tech Stack

- **UI**: SwiftUI, iOS 26.4 deployment target (current Xcode default — revisit
  if a lower target is needed for device reach)
- **Language**: Swift 6.4 with Strict Concurrency enabled from day one
- **Persistence**: SwiftData
- **Sync**: CloudKit — private database via SwiftData's automatic CloudKit
  integration, **plus** manual CKShare work for group sharing (see "CloudKit
  Setup & Known Gap" below)
- **Dependencies**: none for V1 — OCR uses system Vision/VisionKit frameworks
- **Bundle ID**: `com.martinschulz.zahlmeischter`

## Architecture: MV Pattern (not MVVM)

Follow Apple's modern "Model-View" pattern with `@Observable`:

- **SwiftData `@Model` types are the models** — they're automatically
  observable, so views bind to them directly. Don't wrap them in a separate
  ObservableObject/ViewModel.
- **Views own their own transient UI state** (`@State` for sheet flags, form
  drafts, etc.) — this never lives in a model.
- **App-wide state** (current user, active group, settings) lives in a single
  `@Observable` `AppState`, injected via `.environment(_:)` — not singletons.
- **Only add a dedicated `@Observable` "view model"** when a screen has real
  orchestration logic reused elsewhere (e.g., a settle-up calculator feeding
  multiple views). Don't create one-ViewModel-per-screen by default.
- **Business logic lives in `Logic/`** as plain Swift types with no
  `import SwiftUI` — split math, debt simplification, currency conversion.
  Keeps it trivially unit-testable with Swift Testing.

### Naming conventions
- Views: `<Noun><Purpose>View.swift` (`ExpenseEditorView`, `GroupDetailView`)
- No `ViewModel` suffix unless the type genuinely wraps view-presentation
  orchestration
- SwiftData models: singular nouns — but use **`ExpenseGroup`**, not `Group`
  (avoids collision with SwiftUI's `Group` view)

## File Organization

```
zahlmeischter/
├── zahlmeischterApp.swift          # @main entry point, ModelContainer setup
├── App/
│   ├── AppState.swift              # top-level @Observable app state
│   └── PersistenceController.swift # SwiftData ModelContainer + CloudKit config
├── Models/                          # SwiftData @Model entities (CloudKit-compatible)
│   ├── ExpenseGroup.swift
│   ├── Member.swift
│   ├── Expense.swift
│   ├── ExpenseSplit.swift
│   └── Settlement.swift
├── Logic/                           # framework-agnostic business logic (unit-testable)
│   ├── SplitCalculator.swift       # equal/percentage/custom split math
│   ├── DebtSimplifier.swift        # settle-up / minimize-transactions algorithm
│   └── CurrencyFormatting.swift    # currency display helpers
├── Views/
│   ├── Groups/
│   ├── Expenses/
│   │   └── ReceiptScannerView.swift # VisionKit wrapper
│   └── SettleUp/
├── Extensions/
└── Resources/
    └── Localizable.xcstrings
```

New features get their own folder under `Views/`.

## Data Model & CloudKit Constraints

⚠️ **Every `@Model` type must follow these rules** — violations cause silent
sync failures or runtime crashes, not compile errors:

1. **Every stored property is `Optional` or has a default value.** No bare
   non-optional properties without defaults.
2. **No `@Attribute(.unique)`** — CloudKit can't enforce cross-device
   uniqueness. Use client-generated `UUID` (`= UUID()`) for identity + app-level
   dedup if needed.
3. **All relationships are optional with an explicit inverse** via
   `@Relationship(inverse:)`, even conceptually-required to-many relationships.
4. **Don't filter `#Predicate` across to-many relationships** — fetch then
   filter in Swift instead (CloudKit-backed predicates crash on to-many
   traversal).
5. Plan for **soft-delete/tombstones** — CloudKit deletion sync is eventually
   consistent.

### Entity sketch (informal — refine during implementation)

- **`ExpenseGroup`**: name, default currency, members, expenses, createdAt
- **`Member`**: name, optional linked iCloud user ID (for shared groups) vs.
  "placeholder" member (person without the app — Splitwise-style ghost
  participant; CKShare only supports real iCloud participants, so placeholders
  are local-only annotations)
- **`Expense`**: title, amount, currency code, payer, date, splits, optional
  receipt image reference
- **`ExpenseSplit`**: expense ref, member ref, share amount, split type
  (equal/percent/custom)
- **`Settlement`**: from member, to member, amount, currency, date, status

## CloudKit Setup & Known Gap

### One-time setup (not yet done — needed before any CloudKit code)
1. Xcode target → Signing & Capabilities → add **iCloud** → enable **CloudKit**
   → container `iCloud.com.martinschulz.zahlmeischter`
2. Add **Background Modes** → enable **Remote notifications**
3. Verify **Push Notifications** capability is present (Xcode auto-adds this
   with CloudKit)
4. CloudKit schema auto-creates in *Development* on first run — must be
   manually promoted to *Production* in CloudKit Dashboard before release

### ⚠️ Known gap: group sharing needs manual CKShare work
SwiftData's built-in CloudKit support only syncs to the **private database**
(single-user). Sharing a group with other people — the core feature of this
app — requires `CKShare` via raw CloudKit APIs:
- `ExpenseGroup` is the CKShare **root record**; members/expenses/splits/
  settlements hang off it and share automatically.
- Wrap `UICloudSharingController` in a `UIViewControllerRepresentable` for the
  share sheet.
- Handle share-acceptance via the scene delegate / `userDidAcceptCloudKitShareWith`.
- Add `CKSharingSupported = true` to `Info.plist` once implemented.

**Treat this as a spike to validate before building out the full sharing
feature** — don't assume "enable CloudKit" alone gets you multi-user groups.

## Multi-Currency

- **V1 supports CHF and EUR only** — design the currency type so adding more
  ISO codes later is trivial (e.g. an enum/string-backed `CurrencyCode`, not
  a hardcoded CHF/EUR boolean).
- Store all monetary values as **`Decimal`**, never `Double` (avoids
  floating-point rounding errors in split math).
- **Always display the ISO currency code** (`CHF`, `EUR`, `USD`, ...), never a
  currency symbol (`€`, `$`). Note that `.currency(code:)` `FormatStyle`
  renders locale-driven *symbols*, not codes — so format the number using
  Swiss grouping (`Locale(identifier: "de_CH")`, per the Localization section)
  and prepend/append the ISO code as a literal, e.g. `"CHF 1'000.00"` /
  `"EUR 1'000.00"`.
- Exchange rate source is a future business-logic decision (out of scope for
  now).

## Receipt OCR

- Capture: `VNDocumentCameraViewController` (VisionKit) — guided scan UI with
  auto-crop/perspective correction.
- Extract text: `VNRecognizeTextRequest` (Vision) on the captured image.
- Line-item parsing (mapping OCR text blocks → description/price pairs) is
  custom app logic — put it in `Logic/`, unit-test heavily since receipt
  formats vary.
- Both are system frameworks — no third-party OCR dependency needed for V1.

## V1 Feature Scope

1. **Groups & splits** — create groups, add expenses, split equally / by
   percentage / custom amounts. *(Foundation for everything else.)*
2. **Multi-currency** — track expenses in CHF, EUR, etc., display per the
   rules above.
3. **Settle-up / debt simplification** — compute who owes whom, minimize the
   number of payments to settle a group. *(Depends on #1.)*
4. **Receipt scanning (OCR)** — scan receipts to auto-itemize expenses.
   *(Independent — can be built in parallel with the above.)*

**Suggested build order**: get groups/expenses/splits working locally first
(SwiftData, CloudKit private-sync only) → validate the CKShare spike for group
sharing → settle-up → receipt OCR. Sharing is the highest-risk item
architecturally — don't leave it for last.

## Testing

- **Swift Testing** (`import Testing`, `@Test`, `#expect`) for unit tests:
  `Logic/` business rules (split math, debt simplification — great candidates
  for `@Test(arguments:)` parametrized tests), and SwiftData model
  defaults/relationships via an in-memory `ModelContainer`
  (`ModelConfiguration(isStoredInMemoryOnly: true)`).
- **XCTest** retained only for UI tests (`XCUIApplication`) — Swift Testing
  has no UI-testing story.

## Build & Run

```bash
# Build
xcodebuild -project zahlmeischter/zahlmeischter.xcodeproj -scheme zahlmeischter -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project zahlmeischter/zahlmeischter.xcodeproj -scheme zahlmeischter -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Localization & Regional Formatting

- **Primary language**: High German (Hochdeutsch) written with **Swiss
  orthography** — always `ss`, never `ß` (e.g., "Strasse" not "Straße",
  "weiss" not "weiß"). Applies throughout the `de` String Catalog
  (`Localizable.xcstrings`); no separate `de-CH` dialect variant needed.
- English (`en`) as a secondary language — scope TBD.
- **Dates**: always `dd.MM.yyyy` (Swiss format), regardless of device locale.
- **Numbers**: always Swiss grouping — apostrophe as thousands separator,
  period as decimal (`1'000.00`), regardless of device locale.
- For both dates and numbers, explicitly use `Locale(identifier: "de_CH")`
  (or fixed format strings) rather than `Locale.current` — Swiss formatting
  is required even if the device itself is set to a different locale.
- Detailed tone/copy/branding decisions: see future `design.md`.

## Open Questions / Deferred Decisions

- CKShare implementation approach — pending the sharing spike
- Exchange rate data source for multi-currency conversion
- English (`en`) localization scope for V1 vs. German-only launch

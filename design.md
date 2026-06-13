# design.md

Visual identity, motion, and copy guidelines for zahlmeischter. This is the
companion to CLAUDE.md: CLAUDE.md owns architecture, this file owns how the
app looks, moves, and sounds.

## Brand Personality & Voice

- **Personality**: warm but professional. Approachable and personable, but
  understated — no forced jokes about debt or "the bill master" gag. Clarity
  and trust come first; personality is a quiet undertone, not the headline.
- **Address form**: `du` (informal) throughout German copy. The app is for
  friends, households, and travel groups — formal `Sie` would feel wrong.
  Swiss orthography rules from CLAUDE.md apply (always `ss`, never `ß`).
- **Debt framing**: neutral and factual, not guilt-inducing. Prefer framing
  around "open amounts" rather than accusatory "X owes Y" language.
- **Example copy** (anchor points, not exhaustive — full strings live in
  `Localizable.xcstrings`):
  - Empty activity feed: "Noch keine Ausgaben hier. Leg die erste an, sobald
    ihr etwas geteilt habt."
  - Balance summary (positive): "Lisa hat noch CHF 120.00 bei dir offen."
  - Balance summary (negative): "Du hast noch CHF 35.00 bei der Gruppe offen."
  - Settle-up confirmation: "Du gleichst CHF 42.50 mit Lisa aus."
  - Generic error: "Das hat nicht geklappt. Versuch's gleich noch einmal."

## Color System — "Cool Premium"

- **Mesh gradient background** (`MeshGradient`, continuous slow "breathing"
  drift, no user interaction needed): four-stop organic blend —
  - Deep indigo (dark-mode base, e.g. `#2B2A55`)
  - Violet (e.g. `#6C5CE7`)
  - Soft teal (e.g. `#4ECDC4`)
  - Dusty pink (e.g. `#F2A6C8`)
  - Light-mode variant uses softened/lightened versions of the same four
    stops (e.g. `#B8B8E8`, `#C9BFFF`, `#A8E8E2`, `#FBD5E8`) so the same
    "organic blend" identity carries across appearances.
- **Primary accent** (interactive elements, tints, `AccentColor`): a
  violet-indigo (e.g. `#7C6FE0`) — reads clearly on both light and dark
  gradient variants.
- **Neutrals**: near-black surfaces/text in dark mode (glass and glow read
  best against dark), cool-leaning off-white/grey surfaces in light mode.
- **Mode strategy**: both light and dark mode fully supported via system
  appearance (never force one mode) — dark mode is the primary/"hero"
  experience the rest of the visual language is designed around; light mode
  is a deliberately softened variant of the same palette, not an afterthought.
- Exact gradient stops and contrast ratios are starting points — tune
  visually during implementation (see Open Questions).

## Materials & Depth — Glass + Papercraft Hybrid

- **Liquid Glass** (native iOS 26 `.glassEffect()` / system materials) is the
  *everyday* material: floating cards, navigation bars, sheets, the balance
  cards on the dashboard. This replaces hand-rolled glassmorphism — iOS 26
  gives us this natively, which is also why the iOS 26.4 deployment target in
  CLAUDE.md works in our favor here.
- **Papercraft / isometric illustration** (custom `Canvas`/`Path` drawing, or
  static vector assets) is reserved for *moments*, not everyday chrome:
  - The launch animation's morphing hero shape
  - Empty states (e.g. "no expenses yet")
  - Onboarding
  - Settlement-complete micro-interaction
- **Shadows & blend modes**: soft, warm-tinted shadows under papercraft
  elements (gives them a tactile, lifted-paper feel); cool-tinted glow under
  glass elements (reinforces the "cool premium" mesh-gradient mood).

## Typography

To prevent typography drift as new screens/modules get added later, the app
uses a **strict 3-size type scale** — before introducing any new font size
anywhere, check this table first.

Per [Apple's Human Interface Guidelines for Typography](https://developer.apple.com/design/human-interface-guidelines/typography),
text should never render smaller than **11pt** — sizes can go larger than the
table below if a screen needs it, but never smaller. All sizes use Dynamic
Type styles so they scale with the user's text-size settings; the Caption row
uses a style with a built-in floor so it can't drop below 11pt.

This scale governs typography *within screen content* (cards, lists, hero
numbers, labels). Navigation bar titles, tab bar labels, and other system
chrome follow standard SwiftUI/Liquid Glass navigation defaults and sit
outside this scale — the OS already handles their sizing.

| Role | Typeface | Dynamic Type style | ~Size @ default | Weight | Use cases |
|---|---|---|---|---|---|
| **Display** | New York (serif) | `.largeTitle` | ~34pt | Bold/Semibold | Hero numbers only — Dashboard total balance, settlement amount, the amount field in Add Expense. |
| **Body** | SF (sans) | `.body` / `.headline` | ~17pt | Regular (content) / Semibold (titles, emphasis) | List rows (expense descriptions, member names), buttons, input field text, section headers, in-content titles. |
| **Caption** | SF (sans) | `.footnote` / `.caption` | ~11–13pt | Regular | Timestamps, dates, currency-code labels next to amounts, helper/error text, metadata. Never below 11pt. |

- Two typefaces (New York + SF), three size roles — both typefaces ship with
  iOS, no custom font files to bundle or license. New York is Apple's own
  editorial serif, designed as SF's companion, giving the "more editorial"
  feel without a third-party dependency.
- If a new screen seems to need a 4th size, treat that as a signal to
  re-check the screen's hierarchy against this table first — not as an
  automatic green light to add one.

## Iconography & App Icon

- Empty-state and onboarding illustrations: papercraft style, rendered in the
  cool-premium palette, consistent with the launch animation's visual
  language.
- **App icon — three concepts, kept open for now**:
  - **A. Papercraft wallet/coin-purse**: tactile folded-paper object,
    isometric, gradient + glass highlight. Most directly extends the
    papercraft motif — could literally be the launch animation's hero shape
    at rest.
  - **B. Abstract "Z" monogram**: geometric glass shard forming a "Z," filled
    with the mesh gradient. More modern/abstract, likely scales best at small
    icon sizes (Spotlight, Settings).
  - **C. Isometric bill-fold + coins**: literal "splitting a bill" imagery,
    glossy papercraft style — most on-the-nose representation of the app's
    purpose.
  - Decide after seeing all three rendered at actual icon sizes (see Open
    Questions).

## Motion Principles

- **Launch sequence**: ~4–5s animated sequence in a dedicated
  `LaunchScreenView`, built from `withAnimation(.spring(...))` sequences
  morphing an abstract papercraft shape (e.g., paper unfolding into a
  wallet/coin form), ending in a scale-and-fade transition into the Dashboard.
  - Plays **once per process lifetime**, on a true cold launch (after the app
    process has been terminated — force-quit, OS memory eviction, or device
    restart). Does **not** replay on background→foreground resume — this is
    SwiftUI's natural default (the `@main App` struct initializes once per
    process), so no extra `scenePhase` suppression logic is required.
  - Must respect `accessibilityReduceMotion`: when enabled, skip straight to
    a static version of the end-state (or a near-instant fade), per Apple HIG.
- **Mesh gradient breathing**: continuous, slow, non-interactive drift of the
  background gradient on the Dashboard. Paused/static when Reduce Motion is
  enabled.
- **Hero / parallax**: Dashboard hero section reacts to scroll — papercraft
  vector elements shift at a different rate than the content (parallax),
  giving the header depth.
- **Charts**: Swift Charts spending-history visualization draws itself on
  with a staggered animation when the view appears (bars/lines animate in
  sequence, not all at once).
- **Cards & transitions**: glass cards float above the moving gradient;
  screen-to-screen transitions use spring-based scale/fade, consistent with
  the launch sequence's motion language.

## Key Screens — Visual Treatment

- **Dashboard**: hero section with large total-balance figure in New York
  over the breathing mesh gradient, with parallax-reactive papercraft shapes;
  below, glass balance cards per group member ("owes you" / "you owe" in CHF/
  EUR per CLAUDE.md formatting); a Swift Chart of spending history with
  staggered draw-on.
- **Add Expense**: presented as a glass sheet; large New York amount entry as
  the focal point, SF labels for description/payer/date fields, a
  split-method selector (equal/percentage/custom) styled as glass segmented
  control or pills, and a receipt-scan entry point (camera icon → VisionKit
  flow per CLAUDE.md).
- **Activity Feed**: list of glass rows grouped by date (`dd.MM.yyyy` per
  CLAUDE.md), each row showing description in SF and amount in New York with
  tabular figures for alignment.
- **Settlement Flow**: a focused glass card stating the transaction ("Du
  gleichst CHF 42.50 mit Lisa aus") in New York, debt-simplification results
  shown as a simple "from → to: amount" list, with a small papercraft
  completion micro-interaction (e.g., a checkmark shape morphing in) on
  confirmation.

## Text Input & Forms

- **No example placeholder text**: input fields (e.g. the group-name field
  when creating a new group, or the description field on an expense) must
  not rely on example-style placeholder text (e.g. "z.B. Mallorca Reise") as
  their only guidance. Use a persistent label above or beside the field
  instead — placeholder text disappears the moment the user starts typing,
  so it can't double as a label, and it isn't reliably surfaced to
  VoiceOver/accessibility users either.
- When entering text or numbers via the keyboard (expense amounts,
  descriptions, member/group names, etc.), the confirm ("Done"/"Save") and
  cancel ("Cancel"/dismiss) actions live in the **keyboard toolbar** — the
  horizontal accessory bar above the keyboard
  (`ToolbarItemGroup(placement: .keyboard)`) — not as floating circular
  buttons over the content.
- Floating circular glass/icon buttons (e.g. FAB-style action triggers,
  navigation icons) are a separate pattern reserved for when the keyboard is
  *not* active — keeping the two distinct avoids confusing "confirm this
  input" with "trigger this action."

## Accessibility & Performance Guardrails

- **Reduce Motion**: launch animation, mesh-gradient breathing, and hero
  parallax all need static/instant fallbacks — this is a hard requirement,
  not optional polish.
- **Contrast**: verify text/glass contrast against the gradient meets WCAG AA
  in both light and dark mode — gradient saturation/lightness may need
  per-mode tuning to keep New York/SF text legible.
- **Performance**: mesh gradient + glass materials + parallax running
  simultaneously on the Dashboard should be profiled on a mid-range device
  (e.g., iPhone 12/13) — if frame rate suffers, prioritize reducing gradient
  mesh resolution or animation complexity before cutting glass effects (glass
  is the everyday material; gradient motion is more negotiable).

## Localization & Formatting Conventions

These mirror CLAUDE.md's localization rules, restated here because they
affect the visual layout of almost every screen (number/date width,
alignment) and should be the first check when building any new view:

- **Language**: High German (Hochdeutsch) with **Swiss orthography** —
  always `ss`, never `ß` (e.g. "Strasse", "weiss"), throughout
  `Localizable.xcstrings`.
- **Dates**: always `dd.MM.yyyy`, regardless of device locale.
- **Numbers**: Swiss grouping — apostrophe as thousands separator, period as
  decimal, always two decimal places, e.g. `1'000.00`. Use
  `Locale(identifier: "de_CH")` (or fixed format strings), never
  `Locale.current`.
- **Currency**: always the ISO code (`CHF`, `EUR`, ...) as a literal, never a
  symbol (`€`, `$`) — e.g. `"CHF 1'000.00"`.
- Render amounts in New York (Display role) with `.monospacedDigit()` so
  figures stay aligned in lists, cards, and the settlement summary (see
  Typography).

## Open Questions / Deferred Decisions

- Final app icon concept (A/B/C) — render all three at actual icon sizes
  before deciding.
- Exact mesh-gradient color stops, saturation, and contrast per mode — tune
  visually once the Dashboard is implemented.
- Papercraft illustration production: hand-drawn assets vs. procedurally
  generated via `Canvas`/`Path` — decide based on how many illustrations are
  needed (launch shape, empty states, onboarding, settlement check).
- On-device performance ceiling for simultaneous mesh gradient + glass +
  parallax — validate once Dashboard is buildable, adjust guardrails above if
  needed.

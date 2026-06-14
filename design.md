# design.md

Visual identity, motion, and copy guidelines for zahlmeischter. This is the
companion to CLAUDE.md: CLAUDE.md owns architecture, this file owns how the
app looks, moves, and sounds.

> **This is the V2 direction.** The visual language was reworked from the
> original "dark-is-the-hero, violet-accent" concept into a **light-only,
> teal-accent, single continuous mesh** system, validated in an interactive
> prototype (Claude Design → `Zahlmeischter Prototype v2`). Where a section
> below intentionally reverses an earlier rule, it is flagged
> **⟲ Deliberate reversal**. CLAUDE.md's data-model notes that still mention a
> per-group currency are superseded here (see Multi-Currency).

## Brand Personality & Voice

- **Personality**: warm but professional. Approachable and personable, but
  understated — no forced jokes about debt or "the bill master" gag. Clarity
  and trust come first; personality is a quiet undertone, not the headline.
- **Tagline**: **"Kosten geteilt, Laune gerettet."** — the official slogan,
  shown on the launch screen and the first onboarding page.
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
  - Settle-up framing: "Mit so wenigen Zahlungen wie möglich."
  - Generic error: "Das hat nicht geklappt. Versuch's gleich noch einmal."

## Color System — "Cool Premium" (light)

⟲ **Deliberate reversal:** the app is now **light mode only**. Dark mode (and
the dark-base mesh that was the original "hero" experience) is removed. Set
`.preferredColorScheme(.light)` app-wide; do not branch on `colorScheme`.

- **Universal mesh gradient background** (`MeshGradient`, continuous slow
  "breathing" drift, no user interaction): one **single, continuous, unbroken**
  mesh sits behind the *entire* app — Dashboard, Group detail, sheets — with no
  solid background breaks between titles and content. Glass surfaces float over
  it everywhere. Canonical light stops (soft, lightened):
  - `#C9BFFF` (violet) — radial, top-left (≈16% 12%)
  - `#9FE6DD` (teal) — radial, top-right (≈88% 16%)
  - `#FBD5E8` (dusty pink) — radial, bottom-right (≈84% 88%)
  - `#9FE0D6` (teal) — radial, bottom-left (≈10% 92%)
  - base wash: `linear-gradient(160deg, #E8F1F2, #E6EEF5)`
- **Breathing motion**: slow drift + scale, `18s` ease-in-out loop, scale
  roughly `1.08 → 1.28 → 1.2 → 1.08`. Deliberately a touch more *evident* than
  a barely-there shimmer. Static when Reduce Motion is on.
- **Primary accent — teal `#0FA28F`** (`AccentColor`): all interactive
  elements, tints, identity, and selected states (FAB, primary buttons, chips,
  checkmarks, the "Du" avatar, active tab).
  - ⟲ **Deliberate reversal:** the original violet-indigo accent is demoted.
    **Violet `#6C5CE7` / `#6C5CE0` is now a secondary / illustration hue** —
    the app-icon wallet, the launch/onboarding coins, papercraft moments.
  - **Teal is primary, but not *everywhere*.** Member avatars and category
    icons draw from the **full palette** (teal/rose/violet/amber/blue) so the
    app doesn't read as a teal wash; teal stays reserved for actions, identity,
    and selected states.
- **Semantic colors**: positive / "owed to you" = `#0E9E82`; negative /
  "you owe" = `#D14D74` (a rose, not an alarming red — keeps debt framing calm).
- **Neutrals (light)**: text `#172A30`; secondary text `rgba(23,42,48,.62)`;
  tertiary `rgba(23,42,48,.36)`; hairline `rgba(23,42,48,.1)`; opaque surface
  `#FFFFFF`. See the token table under Localization.

## Materials & Depth — Glass + Papercraft Hybrid

- **Liquid Glass** (native iOS 26 `.glassEffect()` / system materials) is the
  *everyday* material: floating cards, the tab bar, sheets, list rows, the
  balance cards, the settle-up bubbles. Glass surfaces use a white-tinted fill
  (`rgba(255,255,255,.5)` for cards, `.38` for nested wells) with a bright
  `rgba(255,255,255,.72)` hairline border, floating over the mesh.
- **Papercraft / isometric illustration** (custom `Canvas`/`Path` drawing, or
  static vector assets) is reserved for *moments*, not everyday chrome:
  - The launch animation's wallet + falling coins (see Motion).
  - Onboarding illustrations (3 screens — see Key Screens).
  - Empty states (e.g. "no expenses yet", "Alles ausgeglichen").
  - Settlement-complete micro-interaction (ring + morphing checkmark).
- **Shadows & blend modes**: soft, warm-tinted shadows under papercraft
  elements (tactile, lifted-paper feel); cool-tinted glow under glass elements
  (reinforces the "cool premium" mesh-gradient mood).

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
| **Display** | New York (serif) | `.largeTitle` | ~34pt | Bold/Semibold | Hero numbers and editorial titles — Dashboard total balance & "Übersicht", settlement amount, group name, the amount field in Add Expense. May render **larger** where it's the sole focal point (the Add-Expense amount entry is ≈54pt) — allowed by "can go larger, never smaller". |
| **Body** | SF (sans) | `.body` / `.headline` | ~17pt | Regular (content) / Semibold (titles, emphasis) | List rows (expense descriptions, member names), buttons, input field text, section headers, in-content titles. |
| **Caption** | SF (sans) | `.footnote` / `.caption` | ~11–13pt | Regular | Timestamps, dates, currency-code labels next to amounts, helper/error text, metadata. Never below 11pt. |

- Two typefaces (**New York** + SF), three size roles — both ship with iOS, no
  custom font files to bundle or license. New York is Apple's own editorial
  serif, SF's companion. (The HTML prototype substitutes Google *Newsreader*
  only because New York isn't a web font — on iOS use **New York**
  (`.serif` / `Font.system(..., design: .serif)`).)
- Render amounts in New York with `.monospacedDigit()` / tabular figures so
  columns stay aligned in lists, cards, bubbles, and the settlement summary.
- If a new screen seems to need a 4th size, treat that as a signal to re-check
  the screen's hierarchy against this table first — not a green light to add one.

## Iconography & App Icon

- Empty-state and onboarding illustrations: papercraft style, rendered in the
  cool-premium palette (violet lead + teal, pink as a third accent), consistent
  with the launch animation's visual language.
- **App icon — locked to Konzept A** (the papercraft coin-purse). The earlier
  "decide between A/B/C" question is resolved; B (Z-monogram) and C (bill-fold)
  are dropped. Spec:
  - A pink-cream rounded-rectangle **wallet/purse** (`#fef5fb → #f3d9ea →
    #e9c3dc`) with a lighter top flap and a small **violet snap** button
    (`#6C5CE7`).
  - A **teal coin** (`#9BEDE5 → #4ECDC4 → #33B3AA`) **cut in half**, sticking
    up out of the centre of the purse (peeking halfway out). Smooth disc —
    **no white inner ring**; a soft gradient gives it a slight 3-D feel.
  - Background: a **single-hue violet glow — no mesh** (the icon is the one
    place the mesh is deliberately *absent*).
  - Ships with a **New York wordmark lockup** ("zahlmeischter") for marketing /
    onboarding contexts.
  - Must stay legible down to ~40px.

## Motion Principles

- **Launch sequence**: ~3.5–4s animated sequence in a dedicated
  `LaunchScreenView`, over the moving mesh background. The launch *is the app
  icon assembling itself*:
  - The **violet wallet** sits centre with the **"zahlmeischter" wordmark below
    it the whole time**, and the tagline beneath.
  - **Three teal coins fall in from above**; the last one settles into the
    icon's signature half-out position, so the composition lands on the finished
    purse-and-coin. **No app-icon background** — just the purse and coins over
    the mesh (not the icon's violet glow).
  - Ends in a scale-and-fade transition into onboarding / Dashboard.
  - Plays **once per process lifetime** on a true cold launch (the `@main App`
    struct initializes once per process — no `scenePhase` suppression needed).
    Also **replayable on demand** from Profil → "Launch-Animation abspielen".
  - Must respect `accessibilityReduceMotion`: skip straight to the static
    end-state (or a near-instant fade), per Apple HIG.
- **Mesh gradient breathing**: continuous, slow, non-interactive drift of the
  universal background (`18s` loop). Paused/static when Reduce Motion is on.
- **Hero / parallax**: Dashboard hero papercraft/bubble elements may shift at a
  different rate than the content on scroll, giving the header depth.
- **Charts**: the Swift Charts spending-history bars **draw on with a staggered
  animation** (bars grow up one after another, not all at once, not too fast)
  when the view appears.
- **Onboarding illustrations**: each element animates in (cards sway, lines
  draw, donut spins into place, avatars pop, settle-beams travel slowly).
- **Cards & transitions**: glass cards float above the moving gradient; sheets
  and group-detail use spring-based slide/scale/fade, consistent with the
  launch sequence's motion language.

## Key Screens — Visual Treatment

- **Launch** (see Motion): wallet + falling coins + wordmark over the moving
  mesh; assembles into the app icon, then fades into onboarding.
- **Onboarding** — 3 swipeable pages over the mesh, each with an animated
  papercraft illustration (violet+teal+pink), a New York title, SF body, page
  dots, a teal CTA, and "Überspringen":
  1. **Kosten geteilt, Laune gerettet** — "Erfasse gemeinsame Kosten in
     Sekunden und behalt den Überblick, wer was ausgelegt hat." (a two-card
     receipt stack: line items draw in + an animated "splitting" donut chart
     inside the front sheet).
  2. **Lade deine Gruppe ein** — "Schick einen Link per iMessage oder E-Mail –
     auch an Leute, die die App noch nicht haben." (member avatars pop in next
     to a pulsing dashed "+" invite slot).
  3. **Gleicht clever aus** — "zahlmeischter rechnet aus, wer wem wie viel
     schuldet – pro Währung und mit so wenigen Zahlungen wie möglich." ("Du" on
     the right, two members (L teal, M pink) stacked on the left; a colored
     "beam" line draws slowly from each toward Du, then a teal check appears).
- **App shell**: a **floating glass tab bar** (Übersicht · [+] · Aktivität)
  with a **central teal circular FAB** raised above the bar. Profil is reached
  from the avatar in the Dashboard header. (The FAB is the
  "floating-circular-button when no keyboard is active" pattern from Text Input.)
- **Dashboard (Übersicht)**: greeting + large New York "Übersicht" title;
  a **glass hero balance card** showing the total **per currency on its own
  line** (never aggregated), plus "dir geschuldet" / "du schuldest" wells; a
  **Swift Chart** of monthly spending with staggered draw-on; then a **Gruppen**
  list of glass cards (tinted category icon, name, per-currency net, overlapping
  member avatars).
- **Group Detail**: a continuous-mesh screen (no solid header break) with a
  **Settle-Up "bubble" header** — organic, overlapping glass/mesh **bubbles**
  sized by each member's balance magnitude, "Du" highlighted in bright teal,
  debtors darker, each bubble showing its amount(s) per currency; an "Alles
  ausgeglichen" check-bubble when settled. Below: a glass **your-balance**
  summary (with **Ausgabe** + **Ausgleichen** buttons), a per-member **Salden**
  list, and **Ausgaben** grouped by `dd.MM.yyyy`. A **persistent "Einladen"
  button** and a **⋯ menu** (Leute einladen / Gruppe löschen) sit in the header.
- **Add Expense** (glass sheet): large New York **amount** entry as the focal
  point with a custom in-sheet **keypad**; **Währung** chips (CHF/EUR/USD);
  a **Beschreibung** field with the inline checkmark (see Text Input); a
  **Bezahlt von** dropdown (group-scoped member picker) + **Datum**; an
  **Aufteilung** selector (Gleich / Prozent / Benutzerdefiniert) as glass pills;
  an **editable participant list** (remove ✕, re-add a group member, or add a
  brand-new person inline); a **Beleg scannen** entry point (→ OCR).
- **Activity Feed**: glass rows grouped by date (`dd.MM.yyyy`), each showing
  description in SF and amount in New York with tabular figures.
- **Settlement Flow** (glass sheet): "Mit so wenigen Zahlungen wie möglich"
  framing; debt-simplification results as a **"from → avatar → to: amount"**
  list, **computed per currency** (never mixing currencies); confirm produces a
  papercraft **completion micro-interaction** (expanding ring + morphing
  checkmark) and "Alles ausgeglichen".
- **Invite** (glass sheet): a shareable **link card**, then a channel choice —
  **Nachrichten (iMessage)** (`#34C759`) or **E-Mail** (`#3B82F6`) — leading to
  a compose step (recipient field with inline checkmark) and a sent
  confirmation. This is the core "invite people to download via iMessage/email"
  App-Store feature.
- **Profile**: glass profile card (avatar, name, "iCloud · synchronisiert");
  settings (Bevorzugte Währung, Einführung erneut ansehen, Launch-Animation
  abspielen); version footer.
- **System chrome**: toasts (glass pill, top), confirm dialogs (centered glass
  card, destructive action in the rose `neg` color), and a group action sheet.

## Text Input & Forms

⟲ **Deliberate reversal of the original keyboard-toolbar rule:** for
**single-line text fields** (group name, expense description, invite recipient)
the confirm action is now a **custom inline checkmark button on the trailing
edge, inside the field** — a teal circular ✓ that confirms the input and
dismisses the keyboard. This replaces the "confirm/cancel live in the keyboard
toolbar" guidance for these fields.

- **Exception — the amount field.** The Add-Expense amount uses a distinct
  in-sheet **keypad** flow (no system keyboard), so it gets **no** inline
  checkmark.
- **Still in force (reaffirmed):**
  - **No example placeholder text** (no "z.B. Mallorca Reise"). Placeholder text
    disappears once typing starts and isn't reliably surfaced to VoiceOver.
  - **No label repetition** in the placeholder — if the persistent label above
    the field already says "Gruppenname", the placeholder is empty.
  - **No pre-filled / pre-captured text** in fields by default.
  - Use a **persistent label above** the field as the real guidance.
- Floating circular glass/icon buttons (FAB, the ⋯/‹ nav icons) remain a
  separate pattern, reserved for when the keyboard is *not* active — keeping
  "confirm this input" (inline ✓) visually distinct from "trigger this action".

## Accessibility & Performance Guardrails

- **Reduce Motion**: launch animation, mesh-gradient breathing, hero parallax,
  chart draw-on, and onboarding illustrations all need static/instant
  fallbacks — a hard requirement, not optional polish.
- **Contrast**: verify text/glass contrast against the light gradient meets
  WCAG AA — the soft mesh saturation/lightness may need tuning to keep
  New York/SF text legible.
- **Performance**: the universal mesh + glass materials + parallax running
  together should be profiled on a mid-range device (e.g. iPhone 12/13) — if
  frame rate suffers, prioritize reducing mesh resolution or animation
  complexity before cutting glass (glass is the everyday material; gradient
  motion is more negotiable).

## Multi-Currency

⟲ **Deliberate change (supersedes CLAUDE.md's per-group currency):** there is
**no group currency**. Each expense carries its **own booked currency**.

- **Never aggregate across currencies.** A member's total, a group's total, and
  the Dashboard hero are shown with **one line per currency** (e.g. line 1
  `CHF 1'200.00`, line 2 `EUR 450.00`) — never summed into a single figure.
- **Settle-up runs per currency.** Debt simplification computes an independent
  "who pays whom" set for each currency present in the group and never mixes
  them (no exchange-rate conversion in V1).
- **V1 currency set = CHF / EUR / USD.** The `CurrencyCode` type stays
  string-backed/extensible so adding more ISO codes later is a one-line change.
- Store all monetary values as **`Decimal`**, never `Double`.

## Localization & Formatting Conventions

These mirror CLAUDE.md's localization rules, restated here because they affect
the visual layout of almost every screen (number/date width, alignment) and
should be the first check when building any new view:

- **Language**: High German (Hochdeutsch) with **Swiss orthography** — always
  `ss`, never `ß` (e.g. "Strasse", "weiss"), throughout `Localizable.xcstrings`.
- **Dates**: always `dd.MM.yyyy`, regardless of device locale.
- **Numbers**: Swiss grouping — apostrophe thousands separator, period decimal,
  always two decimals, e.g. `1'000.00`. Use `Locale(identifier: "de_CH")`
  (or fixed format strings), never `Locale.current`.
- **Currency**: always the ISO code (`CHF`, `EUR`, `USD`, ...) as a literal,
  never a symbol (`€`, `$`) — e.g. `"CHF 1'000.00"`.
- Render amounts in New York (Display role) with `.monospacedDigit()`.

### Color token reference (light)

| Token | Value | Use |
|---|---|---|
| accent (teal) | `#0FA28F` | actions, identity, selected, FAB, ✓ |
| pos / neg | `#0E9E82` / `#D14D74` | owed-to-you / you-owe amounts |
| fg / fg2 / fg3 | `#172A30` · `rgba(23,42,48,.62)` · `rgba(23,42,48,.36)` | text / secondary / tertiary |
| glass / glass2 / border | `rgba(255,255,255,.5)` · `.38` · `.72` | cards / nested wells / hairline |
| sheet / solid / line / nav | `rgba(247,250,250,.9)` · `#fff` · `rgba(23,42,48,.1)` · `rgba(255,255,255,.62)` | sheets / opaque / hairline / tab bar |
| mesh stops | `#C9BFFF` `#9FE6DD` `#FBD5E8` `#9FE0D6` on `#E8F1F2→#E6EEF5` | universal background |
| violet (secondary) | `#6C5CE7` | icon wallet, coins, illustration |
| members | `#0FA28F` `#E16A93` `#6C5CE0` `#E0954E` `#3E8FD0` (+ `#C77DCE` `#D98E5A` `#3FB7A0`) | avatars |
| categories | Unterkunft/Miete `#6C5CE0` · Transport `#3E8FD0` · Essen `#E16A93` · Lebensmittel `#36A877` · Aktivität `#E0954E` · Fixkosten `#9B6CD0` · Ausgleich `#0FA28F` | category icon tints |

## Open Questions / Deferred Decisions

- Exact mesh-gradient stops, saturation, and contrast — fine-tune visually
  against real content (current stops above are the validated starting point).
- Papercraft illustration production: procedural `Canvas`/`Path` (as in the
  prototype) vs. exported vector assets — decide per illustration based on
  animation needs (launch coins, onboarding trio, settlement check).
- On-device performance ceiling for the simultaneous universal mesh + glass +
  parallax — validate once the Dashboard and Group-detail bubbles are buildable.
- Exchange-rate data source for any future cross-currency conversion (out of
  scope for V1 — currencies stay separate).

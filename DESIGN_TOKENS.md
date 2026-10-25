# Design tokens

"Warm Campus Harmony", the mobile app's design system (from the Stitch designs and the UI
alignment spec). The Super Admin console has its own, "Quiet Ledger", in its own repo. The two
share the brand teal and nothing else; there is no code or file shared between the repos.

Everything lives in `lib/core/theme/`. Tests in `test/core/theme/` pin the values below, so a
change shows up in review. A screen never writes a colour, font size or text style itself.

## Colours (`app_colors.dart`)

| Token | Value | Use |
| --- | --- | --- |
| `canvas` | #F6F5F1 | Screen background |
| `surface` | #FFFFFF | Cards, sheets, fields |
| `sunken` | #EFEDE7 | Disabled and recessed areas |
| `ink` | #16222C | Primary text |
| `inkSecondary` | #56626C | Secondary text |
| `inkTertiary` | #616B74 | Hints (4.5:1 on every surface) |
| `disabled` | #9AA3AA | Disabled text and icons |
| `border` / `divider` | #E0DDD5 / #ECE9E2 | Card and button outlines / separators |
| `focusRing` | #16222C (ink) | Keyboard and switch focus ring: 2 px on buttons, chips, fields, cards and list rows (`RingInkWell`). Shown only for keyboard/switch focus, not touch. |
| `fieldBorder` | #80878D | Text field outline; 3.64 on white, 3.34 on canvas, 3.11 on sunken (WCAG 1.4.11). A disabled field keeps the light `divider` outline. |
| `success`, `warning`, `error`, `info` | #1E7347, #9A5407, #B3261E, #2B5A94 | Status, each with a `...Bg` tint |
| `present`, `absent`, `late`, `leave` | success, error, warning, info | Attendance marks |
| `halfDay`, `holiday` | #6B4FA0, #FBA86F (dark text) | Attendance marks |

Status and attendance colours are fixed. They never follow the accent.

## Accents (`AppAccent`)

The only themed colour: primary buttons, accent text, tonal fills (selected chips, the attendance control, the nav indicator), the active tab and the focus ring. The accent header comes with the module-header widget. White text
on each passes WCAG AA (4.5:1). `AppTheme.light(accent: ...)` takes it as a parameter.

| Accent | Value |
| --- | --- |
| BravyNix Teal (default) | #0E5E5A |
| Forest Green | #3A8163 |
| Royal Purple | #8465B7 |
| Steel Blue | #3A79AD |
| Rose Pink | #C84277 |
| Sunset Orange | #B15F1F |
| Dark Cyan | #327F7F |

`pressed` is the accent 20% darker, and `text` (the same shade) is what accent-coloured text and icons use on light surfaces, since six of the seven accents are under 4.5:1 there; `tint` is a 12% wash of it over white.

## Text styles (`app_text_styles.dart`)

Plus Jakarta Sans, bundled as static weights 400, 500, 600 and 700 (`assets/fonts/plus_jakarta_sans/`, SIL Open Font
License; static files so the phone's Bold Text setting and bold spans pick the right file). Colour comes from the theme, not the style. Sizes scale with the phone's font setting.

| Style | Size / line | Weight |
| --- | --- | --- |
| `display` | 32 / 40 | 700 |
| `headlineLg` | 24 / 32 | 700 |
| `headlineMd` | 20 / 28 | 600 |
| `headlineSm` | 18 / 24 | 600 |
| `bodyLg` | 16 / 24 | 400 |
| `bodyMd` | 14 / 20 | 400 |
| `bodySm` | 13 / 18 | 400 |
| `labelLg` | 14 / 20 | 600 |
| `labelMd` | 12 / 16 | 600 |
| `labelSm` | 11 / 14, upper case | 700 |
| `number`, `code` | 16 / 24, 13 / 18 | 600, 500 (tabular figures) |

## Spacing, radius, size (`app_spacing.dart`, `app_shadows.dart`)

- Spacing: 4, 8, 12, 16, 20, 24, 32. Screen margin 16. Touch targets at least 48.
- Radius: 8 small, 12 buttons, 14 fields, 16 cards, 24 option chips, 25 bottom sheet top corners, 26 floating tab bar, full for pills.
- Heights: buttons 52 / 44 / 36, floating tab bar 64.
- Shadows: `card`, `sheet`, `floatingNav`.

## Not yet

- Dark mode. Tokens are named by job, so a dark set can be added without renaming anything.
- The accent picker screen and saving the choice on the device (with the Profile feature).

## Shared widgets (`lib/core/widgets/`)

Screens use these instead of building their own. Every one takes its colours from the theme, so the accent
switch reaches all of them, and every one is tested at large text. Text a person reads is passed in by the
screen (it knows the language and the error code); the widgets hold no copy. A required field is flagged with the
platform's required state and also takes `requiredLabel` (the word "Required" in the app's language) as its
spoken hint, because VoiceOver has no required trait. At large text
the widgets wrap or stack instead of shrinking the letters (attendance selector, person row, section header,
`StatTileRow`; `AppSegmentedControl` falls back to `ChoiceChipGroup` when its labels do not fit).

| Group | Widgets |
| --- | --- |
| Buttons | `AppButton` (primary, secondary, tonal, text, danger; large 52, medium 44, small 36; icon; loading), `AppIconButton` |
| Fields | `AppTextField` (label above, required star, helper or error, mono), `AppDropdownField`, `AppDateField`, `AppSearchField` |
| Choices | `ChoiceChipGroup` (draws its own chip so a wrapped label is never cut off; option pickers use it, not Material's `ChoiceChip`), `AppSegmentedControl`, `AttendanceStatusSelector` (P, A, L, HD, LV) |
| Cards and lists | `AppCard`, `SectionHeader`, `StatTile`, `PersonListTile`, `MenuListTile`, `AuditFooter` |
| Labels | `StatusChip` (five tones, each with an icon), `AppTag`, `AppAvatar` |
| Messages and states | `InlineMessage` (error, warning, info), `StatePanel` (empty, error, offline, forbidden, conflict), `SkeletonBox`, `SkeletonList` |
| Shell | `AppTopBar` (64 px, logo or back arrow, small label, actions; grows with text), `NotificationBell` (badge, "9+" above nine), `ModuleHeader` (pinned accent sliver, 260 px, hero card; shrinks to the back button and title), `FloatingPillNavBar` (64 px, radius 26, 2 to 5 tabs), `AppFab` (extended pill), `StickyBottomActions` (primary, or Cancel and primary) |
| Overlays | `showAppBottomSheet` (drag handle only when dismissible; clear of the home indicator), `showConfirmDialog` (optional 64 px tinted icon; scrolls) |

The component gallery (`/gallery`, debug and profile builds only) shows all of them with the accent switch.
The shell pieces are described below.

### Shell (App PR 3)

- **Top bar** is a normal widget (put it at the top of a Column), not `Scaffold.appBar`, because a fixed-height app bar would cut a title at large text.
- **Module header** is a sliver for a `CustomScrollView`. Expanded height is 260 px including the status bar, and more when large text needs it. It is pinned: scrolling shrinks it to a 56 px row with the back button and the title, and the hero card fades out. The hero card is the accent a little darker (`AppAccent.raised`), so white text on it keeps 4.5:1 on all seven accents.
- **Floating tab bar** is the accent at 100% opacity (BravyNix approved) with a `floatingNav` shadow. The chosen tab is a white pill with its icon and label in the accent text shade; the others are white icons 48 px wide, named for screen readers (and as a tooltip on long-press). If the chosen label cannot fit beside the icon (many tabs, very large text) the pill keeps the icon alone and the name is still spoken; layouts do not break a word or cut a line. Tabs carry the tab role and "Tab 2 of 5".
- **FAB** is one extended pill, bottom right, only when the role may add. The label wraps at large text.
- **Sticky actions** put Cancel on the left of the primary when both labels fit in half the width each, and stack with the primary on top when they do not. The bar clears the home indicator, and pads itself by the keyboard height (a `Scaffold` moves only its body for the keyboard, not `bottomNavigationBar`). A label word wider than its room is drawn smaller rather than broken (`AppButton.labelRoom`, `fitWordScaler`).
- **Focus on the accent header** is a white 2 px ring (ink is 2.13:1 on Teal). The top bar sets dark status bar icons, the module header light ones, both on a transparent bar. `reduceMotion(context)` (Android and iOS) is the one question every animated widget asks.
- Focus rings: ink on white or light surfaces, white on the accent (FAB and the icon tabs).


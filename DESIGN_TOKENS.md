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
| `border` / `divider` | #E0DDD5 / #ECE9E2 | Outlines / separators |
| `success`, `warning`, `error`, `info` | #1E7347, #9A5407, #B3261E, #2B5A94 | Status, each with a `...Bg` tint |
| `present`, `absent`, `late`, `leave` | success, error, warning, info | Attendance marks |
| `halfDay`, `holiday` | #6B4FA0, #FBA86F (dark text) | Attendance marks |

Status and attendance colours are fixed. They never follow the accent.

## Accents (`AppAccent`)

The only themed colour: header, primary buttons, the active tab and the focus ring. White text
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

`pressed` is the accent 20% darker; `tint` is a 12% wash of it over white.

## Text styles (`app_text_styles.dart`)

Plus Jakarta Sans, bundled as a variable font (`assets/fonts/plus_jakarta_sans/`, SIL Open Font
License). Colour comes from the theme, not the style. Sizes scale with the phone's font setting.

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
- Radius: 8 small, 12 buttons, 14 fields, 16 cards, 26 floating tab bar, full for pills.
- Heights: buttons 52 / 44 / 36, floating tab bar 64.
- Shadows: `card`, `sheet`, `floatingNav`.

## Not yet

- Dark mode. Tokens are named by job, so a dark set can be added without renaming anything.
- The accent picker screen and saving the choice on the device (with the Profile feature).

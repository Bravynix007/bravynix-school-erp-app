# Notes for AI assistants working in this repo

Read `README.md` first; its "Rules every change follows" section is binding.

- Design docs (PRD, SDD, DDD, API design) are the source of truth. When code and docs disagree,
  raise it; don't guess.
- Dart 3.13 with very_good_analysis 11: constructors use the `new` syntax (`const new(...)`,
  `factory fromJson(...)`). Run `dart fix --apply` after writing code; it converts older forms.
- New feature checklist: `features/<name>/{domain,data,presentation}`; a repository interface in
  `domain/` and its implementation in `data/` using `ApiClient`; register it in
  `app/di/injection.dart`; routes in `app/router/`; strings in `app_en.arb`; copy for every error
  code the endpoint can return; `bloc_test` tests for the bloc and a widget test for the screen,
  including a large text scale.
- Tests never touch the network or the phone: use `FakeHttpAdapter`, `InMemoryTokenStorage` and
  a fixed `AppDevice` (see `test/app/app_test.dart`).
- Never commit secrets, keystores, real personal data or seeded credentials.
- Before pushing: `dart format --output=none --set-exit-if-changed . && flutter analyze
  --fatal-infos && flutter test`.

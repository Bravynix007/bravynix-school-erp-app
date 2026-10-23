# bravynix-school-erp-app

The BravyNix School ERP **mobile app** (Android and iOS) for Society Owners, Institution Admins,
Teachers / Staff and Students / Parents. Super Admins use the web console instead.

Flutter 3.47 (Dart 3.13), **Bloc** for state, **GoRouter** for navigation, feature-first clean
architecture (system design 6, ADR stack row "Mobile app").

## Quick start

```bash
flutter pub get
# Local API from bravynix-school-erp-backend on the host; the emulator reaches it at 10.0.2.2.
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

| Flavor    | Android id                    | API                                   | Config file           |
| --------- | ----------------------------- | ------------------------------------- | --------------------- |
| `dev`     | `com.bravynix.schoolerp.dev`  | `http://10.0.2.2:3000/v1` (plain HTTP)| `config/dev.json`     |
| `staging` | `com.bravynix.schoolerp.stg`  | `https://api.staging.bravynix.in/v1`  | `config/staging.json` |
| `prod`    | `com.bravynix.schoolerp`      | `https://api.bravynix.in/v1`          | `config/prod.json`    |

The staging and production domains are placeholders until the domain is fixed at setup (API
design 5.1). Config values are compiled into the app: nothing secret goes in `config/`.

On iOS, flavors need Xcode schemes, which are set up with the first iOS build on a Mac. Until
then run iOS without `--flavor`: `flutter run --dart-define-from-file=config/dev.json`.

| Command                                         | What it does                                  |
| ----------------------------------------------- | --------------------------------------------- |
| `flutter analyze --fatal-infos`                 | very_good_analysis lints, strict types        |
| `dart format .`                                 | Formats at a 120-column page width            |
| `flutter test --coverage`                       | Unit, bloc and widget tests                   |
| `flutter gen-l10n`                              | Regenerates `lib/l10n/gen` from the ARB files |
| `flutter build apk --flavor dev --dart-define-from-file=config/dev.json` | Android build |

## Layout

```
lib/
  main.dart, bootstrap.dart   Entry point; error handlers, Bloc observer, DI, runApp
  app/
    config/                   AppConfig and Flavor from --dart-define-from-file
    di/injection.dart         get_it registrations (the composition root)
    router/                   GoRouter, the session redirect, route paths
    app.dart                  MaterialApp.router, theme, localisation, SessionBloc
  core/                       Shared by every feature; knows no feature
    network/                  ApiClient (Dio), envelope, ApiFailure, interceptors
    storage/                  Token storage (Keychain / Keystore)
    device/                   App version and platform for the version gate
    theme/, format/, l10n/, widgets/, bloc/
  features/<feature>/
    domain/                   Entities and repository interfaces (plain Dart)
    data/                     Repository implementations and JSON models
    presentation/             Blocs/cubits and widgets
  l10n/arb/                   Strings; app_en.arb is the template
test/                         Mirrors lib/; helpers/ has the fake HTTP adapter and mocks
```

A feature imports `core/`, its own folders and the app-wide session
(`features/auth/presentation/session`), never another feature's `data/` or screens. Shared pieces
move to `core/`.

## Rules every change follows

- **The API is the security boundary.** Screens are hidden by role for convenience only; every
  call is authorised by the API (system design 13).
- **All API calls go through `ApiClient`** in a repository. Blocs and widgets never see Dio.
  Failures are `ApiFailure`; branch on `failure.code`, never on `message` (API design 8).
- **Tokens live in secure storage only** (Keychain / Keystore, never backed up). The auth
  interceptor adds the access token, refreshes once on `TOKEN_EXPIRED` with refreshes
  serialised (a refresh token is single use), and signs out on any other 401.
- **Every request carries `X-App-Version`, `X-App-Platform`, `X-Request-Id` and
  `Accept-Language`.** A 426 opens the "Update required" screen.
- **State lives in blocs and cubits** with `Equatable` states; dependencies come through
  constructors (get_it is read only in `app/di`, the router and page `BlocProvider`s). Time comes
  from an injectable clock where it matters.
- **Every string is in `lib/l10n/arb/app_en.arb`.** Seven languages are supported (en, hi, kn,
  ml, mr, ta, te); translations are added per module once reviewed. Layouts must survive 40%
  longer labels and large text sizes.
- **Money is a decimal string** from the API, formatted without `double`. Dates are DD-MM-YYYY,
  times 24 h in IST.
- **No passwords anywhere.** Login is email plus a 6-digit code.
- Comments cite the doc section they implement, e.g. "API design 6.2".

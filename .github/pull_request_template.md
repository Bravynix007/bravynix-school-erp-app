## What and why

<!-- One or two sentences. Link the PRD / API design sections this implements. -->

## Changes

-

## Screenshots

<!-- Android and iOS, at the default and the largest text size, for any visible change. -->

## How it was tested

- [ ] `flutter analyze --fatal-infos` and `dart format` clean
- [ ] Bloc/cubit tests (`bloc_test`) for every new state change
- [ ] Widget tests for new screens, including a large text scale
- [ ] Ran on a device or emulator against the local API (`--flavor dev`)

## QA entry criteria (QA strategy 10)

- [ ] Builds, unit tests pass
- [ ] Every API error code the screen can receive has copy in `app_en.arb`
- [ ] Screens hidden by role match the PRD 3.2 matrix (the API still checks every call)

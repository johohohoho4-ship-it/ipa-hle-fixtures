# ipa-hle fixtures

Small iOS test apps used as build inputs for the ipa-hle CI. Each directory under
`fixtures/` is built unsigned for arm64 by `fixtures/template/build-fixture.sh`,
run once in the iOS Simulator with an XCUITest, and uploaded as a workflow artifact.

This repository contains only the test apps, the build script and the workflow.
It does not contain the emulator itself.

Run a build: Actions → "Build unsigned iOS fixture and simulator reference" →
Run workflow, with the fixture directory name (for example `uikit-form`).

# 🚀 Campaign Tools Extension: Development Milestones

This document outlines the phased roadmap for transitioning the existing Google Sheets extension to 
a more maintainable and testable TypeScript-based architecture.

---

## ✅ Milestone 1: Minimal Hello World Extension

- [x] Create a new container-bound Google Sheets script with TypeScript + Webpack build pipeline.
- [x] Set up `maps_config.env` and store `SCRIPT_ID` / `SHEET_ID`.
- [x] Deploy a minimal working version (e.g. `sayHello()` function via custom menu).
- [x] Automatically inject and run `Init.js` to set script properties.
- [x] Push code via `clasp push` with no manual steps required.

---

## ⏳ Milestone 2: Jest Unit Testing Infrastructure

- [ ] Add Jest to the project and configure it to run as part of the build/test cycle.
- [ ] Write and pass a simple unit test for a “pure” function (e.g. `formatAddress()`).
- [ ] Intentionally introduce a test failure to confirm Jest’s error reporting.
- [ ] Add a helper script (`test-runner.sh`) to quickly run build + tests in one step.

---

## ⏳ Milestone 3: Port Original Campaign Extension Code

### Milestone 3A: TypeScript Port
- [ ] Move real logic from `ui/` to `ui2/` and convert to TypeScript.
- [ ] Ensure TypeScript compiles cleanly and deploys via `push_content_to_script_by_id.sh`.

### Milestone 3B: Functional Validation
- [ ] Manually validate deployed functionality in Google Sheets matches original extension.
- [ ] Confirm UI and sidebar behavior works with no regressions.

---

## ⏳ Milestone 4: Refactor for Testability

- [ ] Isolate all direct spreadsheet access (`SpreadsheetApp.getActiveSheet()`, `.getRange()`, etc.) into a `spreadsheetUtils.ts` module.
- [ ] Replace direct calls with wrapper functions across the codebase.
- [ ] Write unit tests using mocks to simulate spreadsheet data (e.g. 2D arrays).
- [ ] Verify test coverage includes all key logic paths.

---

## ⏳ Milestone 5: Optional Integration Testing

- [ ] Optionally implement tests that interact with a known test spreadsheet.
- [ ] Simulate real sheet contents with hybrid mocks or sandbox sheets.
- [ ] Add tests for end-to-end flows like distance filtering or lat/lng population.

---

## 📌 Notes

- The `--update` flag in the deploy script disables first-time initialization for faster iteration.
- At this stage, no manual edits to the script in the Apps Script editor are expected.
- Marketplace compliance (e.g. OAuth scopes, manifest structure) will be addressed in later stages.

---



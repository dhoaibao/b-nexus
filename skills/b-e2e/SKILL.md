---
name: b-e2e
description: >
  Browser-based end-to-end testing. ALWAYS invoke when the user asks to test the UI, run end-to-end tests, use the browser, or verify frontend flows: "test UI", "chạy E2E", "test trên trình duyệt", "browser test". Uses Playwright to navigate, interact, and assert state. Unlike b-test (which handles unit/integration code tests), b-e2e drives a real browser to test user-facing functionality.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-e2e

$ARGUMENTS

Drives a real browser using Playwright to verify frontend user flows, inspect the DOM/accessibility tree, manage UI evidence, and author or debug Playwright E2E test scripts.

## When to use
- Running end-to-end (E2E) tests in the browser.
- Verifying UI state, visuals, or frontend workflows.
- Writing or debugging Playwright test files.
- Interacting with a running web application to reproduce a bug.

## When NOT to use
- Writing or fixing unit tests → use `/b-test`.
- Debugging backend logic or API failures without UI involvement → use `/b-debug`.
- Planning the user flow before implementation → use `/b-plan`.

## Tools required

- `playwright_browser_navigate` — from `playwright` MCP server *(Primary)*
- `playwright_browser_snapshot` — from `playwright` MCP server *(Primary)*
- `playwright_browser_click` / `playwright_browser_fill_form` / `playwright_browser_type` / `playwright_browser_press_key` — from `playwright` MCP server *(Primary)*
- `playwright_browser_wait_for` / `playwright_browser_resize` — from `playwright` MCP server *(Primary for stable waits and responsive checks)*
- `playwright_browser_take_screenshot` — from `playwright` MCP server *(Secondary, for visual evidence)*
- `playwright_browser_evaluate` — from `playwright` MCP server *(optional, for complex DOM assertions)*
- `playwright_browser_network_requests` / `playwright_browser_network_request` — from `playwright` MCP server *(optional, for asserting API calls)*
- `playwright_browser_console_messages` — from `playwright` MCP server *(optional, for surfacing frontend errors)*
- `playwright_browser_close` — from `playwright` MCP server *(used in cleanup)*
- `find_symbol`, `get_symbols_overview`, `insert_before_symbol`, `insert_after_symbol`, `replace_symbol_body` — from `serena` MCP server *(optional, for writing test code in Step 5)*
- `bash`, `apply_patch` — for managing temporary artifacts, dev-server health checks, and creating/updating test files when needed.
- **GitNexus is intentionally outside the core `b-e2e` workflow.** If graph-level impact analysis becomes necessary (e.g., a backend failure with cross-module scope), hand off to **b-debug** or **b-review** instead.

If `playwright` MCP is unavailable: stop and inform the user that E2E browser interactions require the Playwright MCP server.
If `serena` is unavailable in Step 5: write test code with `apply_patch` instead.

Graceful degradation: ❌ Not possible — this skill inherently requires browser automation.

## Steps

### Step 1 — Setup environment and navigate

Use `bash` to ensure a session-specific artifact directory exists: `.opencode/b-skills/b-e2e/[timestamp-or-flow-slug]/`. Never write screenshots or snapshots directly into the shared `.opencode/b-skills/b-e2e/` root.

Determine the target URL (local dev server, preview URL, or staging). If the flow writes data on staging/production-like systems, ask for explicit confirmation and test-data guidance before interacting.

If the URL is a `localhost` address, verify the dev server is reachable before navigating. Use the exact host/port from the target URL:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:PORT | grep -qE "^[23]" || echo "Server not responding"
```
If the server is not reachable, ask the user to start it or approve a project-specific start command discovered from manifests. Do not start servers implicitly, and do not attempt `playwright_browser_navigate` to a non-responding host.

Before navigation, clarify only the state that blocks the flow:
- Auth/session: credentials, pre-authenticated state, or whether the flow is public.
- Test data: seed records, disposable accounts, reset expectations, and cleanup responsibility.
- Environment safety: whether writes are allowed against the target URL.

Once confirmed reachable (or for remote URLs), call `playwright_browser_navigate` to load the application.

---

### Step 2 — Map the UI and capture visuals

Call `playwright_browser_snapshot` to capture the accessibility tree and `playwright_browser_take_screenshot` for visual evidence when needed. Save artifacts using each Playwright MCP tool's supported `filename` parameter when available; otherwise record the returned artifact path. Use the session-specific `.opencode/b-skills/b-e2e/[run]/` directory for native notes and generated test files. Always use the accessibility snapshot to find exact target references before attempting to click or type.

---

### Step 3 — Execute interactions

Execute the requested user flow by calling `playwright_browser_click`, `playwright_browser_fill_form`, `playwright_browser_type`, or `playwright_browser_press_key` using the precise targets mapped in Step 2. Keep interactions sequential and use `playwright_browser_wait_for` for expected text/state instead of arbitrary sleeps. Verify state after major actions (form submission, navigation, async loading).

---

### Step 4 — Verify state

Capture a new snapshot/screenshot with the Playwright MCP tools or use `playwright_browser_evaluate` to assert that the expected text, elements, or state changes have appeared. Use `playwright_browser_console_messages` to surface client-side errors when the UI misbehaves. Optionally use `playwright_browser_network_requests` and `playwright_browser_network_request` for API-level assertions when the UI depends on backend calls.

Responsive check:
- For visual/layout work or user-facing flows, verify at least one desktop viewport and one mobile viewport with `playwright_browser_resize` unless the user explicitly scoped the test to one viewport.
- Suggested viewports: desktop `1280x720`, mobile `390x844`.

Flake check:
- Prefer stable UI assertions over timing-only waits.
- If a generated E2E test fails after passing manually, rerun once. If results differ, report it as flaky with the failing step and evidence.

---

### Step 5 — Author or fix test code *(optional)*

If the user asked to write or fix a test file:

1. Locate the appropriate spec file:
   - Use Glob to find existing specs (`**/*.spec.ts`, `**/*.e2e.ts`, or this repo's Playwright convention).
   - Use `find_symbol` on existing describe blocks to identify the right insertion point.
2. Map the successful manual interactions from Steps 3–4 into Playwright code:
   - Mirror selectors from the snapshot (prefer accessible roles/names over CSS).
   - Mirror assertions from Step 4 verification.
3. Insert the test:
   - Existing describe block → `insert_after_symbol` on the last test in the block.
   - New describe block needed → `insert_after_symbol` on the last describe in the file.
   - No spec file exists → use `apply_patch` to create one in the conventional location for this project.
4. Run the new test once via bash to confirm it passes, then rerun once only if the first result conflicts with the manual browser result:
   ```bash
   npx playwright test path/to/spec.ts
   ```

If no test code is requested, skip this step and just report the verified flow.

---

### Step 6 — Cleanup

When testing, verification, and code generation are complete:

1. Close the browser session: `playwright_browser_close`.
2. Clean up only test data that this run created and that the user approved for cleanup. Do not mutate shared staging/prod data without explicit confirmation.
3. Report the artifact directory path. Do not delete artifacts by default; they are useful evidence for failed UI checks. If the user asks to clean up artifacts, delete only the session-specific directory created by this run.

---

## Output format

```
### b-e2e: [flow name]

**URL**: [target URL]
**Scope**: [user flow tested — e.g. "checkout flow", "login → dashboard redirect"]

#### Interactions
- [Action 1: navigate / click / type / fill]
- [Action 2: ...]

#### Assertions
✅ [expected state confirmed — description]
❌ [unexpected state — description and screenshot reference if captured]

#### Network requests *(optional — only if playwright_browser_network_requests was used)*
- [Method + URL] — [status / payload note]

#### Test code *(optional — only if writing or fixing a test file)*
\`\`\`ts
// Playwright test code
\`\`\`
Saved to: `[path/to/test.spec.ts]`

#### Cleanup
✅ Browser closed
Artifacts: `.opencode/b-skills/b-e2e/[run]/`
```

---

## Rules
- Always use `playwright_browser_snapshot` to get exact element targets before interacting; never guess selectors blindly.
- Save Playwright MCP artifacts with the tool-supported `filename` parameter when available; otherwise record the returned path. Keep native notes and generated test files in the session-specific `.opencode/b-skills/b-e2e/[run]/` directory.
- Always close the browser when the testing flow finishes. Do not delete artifacts unless the user asks, and only delete this run's directory.
- Ensure the local dev server is running before attempting to navigate to `localhost`.
- Do not start a dev server unless the user approves the discovered command.
- Clarify auth/session and test-data requirements before executing stateful flows.
- Never mutate production-like environments unless the user explicitly confirms it is safe.
- Keep interactions sequential and verify state changes after major actions.
- Avoid arbitrary sleeps; wait for specific text, elements, URL changes, or network state.
- Run desktop and mobile checks for visual/user-facing flows unless scoped otherwise.
- Prefer accessible roles/names from the snapshot over brittle CSS selectors when authoring tests.
- Never trigger destructive git commands.

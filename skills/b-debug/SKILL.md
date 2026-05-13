---
name: b-debug
description: >
  Systematic hypothesis-driven debugging. ALWAYS invoke when the user says "debug", "bug", "lỗi", "không chạy", "fix this", "why is X not working", or pastes an error message. Traces execution paths, confirms root cause, then fixes and verifies by default. Unlike b-test, b-debug owns runtime behavior failures, not test mechanics.
compatibility: opencode
metadata:
  suite: b-skills
---

# b-debug

$ARGUMENTS

Systematic, hypothesis-driven bug tracing: understand code structure first, form
ranked hypotheses, locate root cause, then fix and verify. Never jump straight to patching.

Default behavior is the full loop: **trace → confirm root cause → fix → verify**.
Only stop earlier when the user explicitly asks for diagnosis-only, root-cause-only, or investigation-only output. Do not stop after reporting the cause if a safe, minimal fix is available.

If `$ARGUMENTS` is provided, treat it as the error message or symptom — skip asking for symptoms in Step 1 and proceed directly with what was given.
If `$ARGUMENTS` explicitly limits scope to investigation-only, honor that limit and stop after Step 4.

## When to use

- User pastes an error message or stack trace.
- Something "should work" but doesn't, with no clear error.
- Bug appears in one place but root cause may be elsewhere (middleware, config, async).
- Previous fix attempts didn't work.
- User says: "debug", "lỗi", "tại sao", "không hoạt động", "fix bug", "why is X not working".

## When NOT to use

- Building a new feature or multi-file change → use **b-plan**
- Test-specific failure (assertion, mock, setup, async timing) → use **b-test**
- Need library API details before writing code → use **b-research**

## Tools required

From `serena` MCP server:
- `check_onboarding_performed` / `onboarding` — initialize project knowledge when needed.
- `find_symbol` — locate the entry point or suspicious symbol.
- `get_symbols_overview` — inspect file structure before opening source.
- `find_referencing_symbols` — trace callers/usages of a function or class.
- `replace_symbol_body`, `insert_before_symbol`, `insert_after_symbol`, `rename_symbol`, `safe_delete_symbol` — apply symbol-level fixes once root cause is confirmed.

Use native bash search for exact error strings, config keys, and repeated patterns. Use native `read` for narrow source chunks after Serena identifies relevant symbols/files.

From `sequential-thinking` MCP server:
- `sequentialthinking` — structured reasoning to form and rank hypotheses.

From `context7` MCP server *(optional)*:
- `resolve-library-id` + `query-docs` — verify correct library API behavior when a hypothesis points to API misuse or version mismatch. Faster than invoking full /b-research for a single API question.

From `brave-search` MCP server *(optional)*:
- `brave_web_search` — look up known library errors, GitHub issues, changelogs.

From `firecrawl` MCP server *(optional)*:
- `firecrawl_scrape` — scrape full content of relevant GitHub issue pages, Stack Overflow answers, or changelogs found via web search.
- `firecrawl_map` — map all URLs on a site when `firecrawl_scrape` returns empty content; use to discover the correct URL before retrying scrape.

From `gitnexus` MCP server *(optional, preferred for large-codebase tracing and cross-module impact — only after `gitnexus analyze`)*:
- `gitnexus query` / `gitnexus context` / `gitnexus impact` — graph-level repo intelligence for multi-file debugging.

If Serena is unavailable: use bash search and `read` to map files manually. Always note: "⚠️ Serena unavailable — analysis based on bash/read; cross-file tracking incomplete."
If sequential-thinking is unavailable: reason inline as `Hypothesis N → Evidence for → Evidence against → Cheapest verification → Confirmed/Rejected`.
If context7 is unavailable: invoke /b-research for library API questions instead.
If gitnexus is unavailable, stale, unindexed, or missing FTS: warn once and continue with Serena and native tools. Note: "⚠️ GitNexus unavailable — using Serena/bash for cross-file tracing."

Graceful degradation: ✅ Possible — if Serena is unavailable, use bash/read for file analysis. Quality is reduced but the skill remains functional.

## Steps

### Step 1 — Gather symptoms

Before touching any code, collect enough information to start, not a perfect bug report:

- **Error message / stack trace**: exact text, not paraphrased.
- **Expected behavior**: what should happen.
- **Actual behavior**: what actually happens.
- **Reproduction**: consistent or intermittent? Under what conditions?
- **Recent changes**: anything changed before the bug appeared?

If `$ARGUMENTS` includes a concrete symptom, error, or stack trace, begin tracing immediately. Ask only for missing expected behavior, reproduction, environment, or recent changes when that information blocks the next verification step. A missing "recent changes" answer is useful, but not a reason to stall when the code path can be inspected.

---

### Step 2 — Map the code structure

**Graph-level fast path** *(when gitnexus is connected and the repo is indexed)*:
- Call `gitnexus query` or `gitnexus context` to understand the module or subsystem where the bug surfaces.
- Use `gitnexus impact` to identify upstream/downstream dependencies of the entry point.
- If GitNexus reports the repo is unindexed, stale, or missing FTS, warn once and continue immediately with Serena/bash tracing.
- After GitNexus narrows the problem space, confirm exact symbols and references with Serena below.

Use `serena` to trace the execution path in this order:

0. **Serena preflight** — call `check_onboarding_performed`; if onboarding has not been performed, call `onboarding` before tracing.
1. `find_symbol` on the chosen entry point (route handler, CLI command, event listener) — locate the best starting symbol.
2. `get_symbols_overview` on the relevant file — confirm which symbols are worth reading.
3. `find_referencing_symbols` on the relevant function — trace callers/usages across files.
4. Use native bash search on the error string, config key, or suspicious behavior.
5. Use native `read` on any function or file section that still looks suspicious.

**read-order rule**: never jump to native `read` before completing the supported Serena symbol and reference steps unless the target is prose/config or no relevant symbol exists.

From this, identify:
- All layers the request/data passes through (middleware, validators, handlers, services, DB).
- Any async boundaries, error handlers, or silent failure points (try/catch that swallows errors, `.catch(() => {})`).
- Hidden choke points: auth middleware, rate limiters, interceptors, event listeners.

**Goal**: understand the full execution path, not just the file where the error surfaces.
The bug is often one layer above or below where it appears.

---

### Step 3a — Form hypotheses

Use `sequential-thinking` to reason through possible causes:

- Generate 3–5 hypotheses ranked by likelihood.
- For each hypothesis, state: *what would cause this symptom*, *evidence for*, *evidence against*, and *cheapest verification step*.
- Bias toward the simplest explanation first (Occam's razor).
- Common categories to consider:
  - **Wrong layer**: error surfaces in A but is caused by B upstream.
  - **Silent failure**: exception caught and swallowed without logging.
  - **State/order issue**: async race, middleware order, initialization timing.
  - **Config/env**: wrong env var, missing secret, wrong port/host.
  - **Version mismatch**: library API changed between versions.
  - **Data shape**: unexpected null, wrong type, missing field.

Report the ranked hypotheses as a brief progress update, then continue verification without waiting unless the user explicitly asked for diagnosis-only mode.

Skip `sequentialthinking` if the stack trace or code path already identifies one clear root cause with no meaningful competing hypothesis.

---

### Step 3b — Fast-path lookups

Run before verifying hypotheses — these often eliminate wrong hypotheses immediately.

**Library error shortcut** — if the error message or stack trace references a specific library or framework:
- `brave_web_search` with the exact error message in quotes to find known issues, GitHub issues, or changelog entries.
- If results include a GitHub issue, Stack Overflow answer, or changelog URL that looks relevant → `firecrawl_scrape` on the top 1–2 most relevant URLs (`formats: ["markdown"]`). Cap at 2 URLs. If a page returns empty or <200 words → `firecrawl_map` on the domain root to find the correct URL, then retry scrape. If still empty, proceed with snippets only.
- If results point to API misuse → `resolve-library-id` + `query-docs` with the specific method/behavior in question. Faster than /b-research for a single API question. Escalate to /b-research only if context7 has no index for the library.

**Error string search** — if the error text is short and specific → native bash search with the exact error string to find all places in the codebase that produce or handle this error. Often reveals the true origin faster than tracing the call graph.

After Step 3b, re-rank hypotheses if findings shifted the picture.

---

### Step 4 — Verify root cause

Test hypotheses starting from the most likely:

- Add targeted logging at the suspected choke point (not scattered everywhere).
- Check config/env values if hypothesis points there.
- Use `get_symbols_overview` first when narrowing within a large file; then native `read` to re-examine the suspicious function.
- Use `find_referencing_symbols` for semantic references or native bash search when the bug pattern may exist in multiple text locations.
- If the hypothesis points to library API misuse: `resolve-library-id` + `query-docs` directly.
- **Regression detection**: if the bug appeared after a recent change, compare current symbol/file content against the recent git diff before changing code.

**Dynamic verification** — if static analysis is insufficient to confirm root cause:

1. Add one or two targeted log statements at the suspected choke point — not scattered across files.
2. Instruct the user to run the failing scenario and paste the output.
3. Analyze the output: does it confirm or eliminate the hypothesis?
4. If confirmed → proceed to Step 5. If eliminated → mark hypothesis as ruled out, advance to the next ranked hypothesis, restart from sub-step 1.
5. After root cause is confirmed, remove all debug logging added during this loop.
6. Inspect the diff or touched lines to confirm all temporary instrumentation was removed before writing the fix or reporting completion.

Cap at **3 iterations** — if root cause is not confirmed after 3 instrumentation rounds, remove any debug logging added during the loop, then surface evidence to the user:

> "Root cause unconfirmed after 3 instrumentation rounds — here's what we know: [evidence gathered]. Consider: adding APM/profiler, reproducing in isolation, or escalating."

**Stop when root cause is confirmed** — don't continue investigating other hypotheses once found.

State clearly: *"Root cause: [X] because [Y]"* before writing any fix.

---

### Step 5 — Fix

Default behavior: implement the minimal safe fix immediately.

- write the minimal fix — don't refactor unrelated code in the same change.
- Prefer Serena symbolic edits in this order: `replace_symbol_body` → `insert_before_symbol` / `insert_after_symbol` → `rename_symbol` / `safe_delete_symbol`; use `apply_patch` when the fix is a small line-level patch inside a larger symbol.
- If the fix touches a non-obvious API or behavior, add a comment explaining why.
- If the bug reveals a broader pattern (same silent-catch in 3 other places), flag it as a separate follow-up — don't fix everything at once.
- Keep the change scoped to the confirmed symbol/file only.

---

### Step 6 — Verify fix

- State what behavior should now change and how to confirm it.
- **Detect test command** from the project: `package.json` scripts, `pytest.ini`, `Makefile`, `Cargo.toml`, or equivalent. Suggest the specific command scoped to the affected module — e.g. `npm test -- --testPathPattern=auth`, `pytest tests/test_auth.py`, `go test ./internal/auth/...`. Do not just say "run your tests".
- If the fix involved a config/env change, remind the user to restart the process.
- If the fix changed more than 2 files or introduced new functions/modules → suggest running `/b-review` before committing.
- Close the loop with the applied fix and the exact verification step unless the caller explicitly requested diagnosis-only mode.

---

## Output format

```
### Debug report: [short description of bug]

**Symptoms**
- Error: `[exact error or "no error — silent failure"]`
- Expected: ...
- Actual: ...

**Code path** *(from [Serena / manual analysis])*
[Entry point] → [Layer 1] → [Layer 2] → [Failure point]
Note any silent catch blocks or unexpected stops in the path.

**Hypotheses** *(ranked)*
1. [Most likely] — [how to verify]
2. ...
3. ...

**Fast-path findings** *(only if Step 3b returned signal)*
- [Library/issue/error-string discovery] → [hypothesis confirmed/rejected]

**Root cause**
[Confirmed cause — one clear sentence]

**Fix**
\`\`\`[lang]
// the fix
\`\`\`

**Verification result / Verify by**: [what was checked, or exact steps to confirm it works]
```

---

## Rules

- Never patch before confirming root cause — a wrong fix wastes time and introduces new bugs.
- Default to full execution: trace → confirm root cause → fix → verify. Only stop at diagnosis when the caller explicitly requests that narrower scope.
- Always map the full execution path first — the bug is often not where it surfaces.
- If 2+ hypotheses seem equally likely, verify the cheaper one first.
- Silent failure points (swallowed exceptions, missing logs) are the most common cause of "no error but not working" bugs — check these first.
- If the fix requires understanding a library's behavior: use context7 first (`resolve-library-id` + `query-docs`); escalate to /b-research only if context7 has no index.
- Keep fixes minimal — one bug, one fix.
- If temporary logging or probes were added, inspect the final diff and confirm they were removed before reporting success.
- Never trigger destructive git commands.

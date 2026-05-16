# b-skills — OpenCode Runtime Contract

> Shared runtime rules for routing, tool choice, safety, evidence, outputs, and handoffs. Skills should reference this file instead of duplicating policy. Keep this file as the hot-path contract; longer playbooks belong in skill or reference files.

---

## 1. Routing

Match the user's intent to one active skill before acting. If a request spans phases, sequence `Clarify -> Decide -> Build -> Validate`.

| Intent | Skill |
|---|---|
| Clarify what to build, lock goals/constraints | `/b-spec` |
| Decide how to build, decompose work | `/b-plan` |
| External docs, API facts, comparisons | `/b-research` |
| Execute approved or clearly scoped work | `/b-implement` |
| Mechanical rename, extract, move, inline, delete | `/b-refactor` |
| Runtime bug, error, "not working" | `/b-debug` |
| Unit/integration tests, coverage, failing tests | `/b-test` |
| Browser/UI verification or browser-driven flow testing | `/b-e2e` |
| Pre-PR changed-code review | `/b-review` |

### Trigger precedence (when intents overlap)

- Browser-driven flow beats `b-test`; use `b-e2e`.
- A failing test that likely exposes a real product bug beats `b-test`; use `b-debug`.
- A named behavior-preserving rename/extract/move beats `b-implement`; use `b-refactor`.
- Unclear end state or acceptance beats `b-plan`; use `b-spec`.
- Clear goal but unclear sequencing beats `b-implement`; use `b-plan`.
- `b-research` is for genuine external-knowledge blockers, not repo-local questions.
- DOM-rendered unit tests stay in `b-test`; only real browser navigation goes to `b-e2e`.

### One active skill

Keep one active skill until its stop condition is hit. Do not switch skills for optional enrichment or minor lookups the current skill can finish with bounded evidence.

### Mid-flow switch policy

- A new request mid-flow does not auto-cancel the active skill. State the conflict in one line, ask whether to pause, queue, or abandon, then proceed.
- An explicit `/<skill>` command always overrides; emit the handoff envelope (§9) before switching.
- A required sub-task is a handoff, not a parallel run.
- If the active skill is mid-transform or mid-iteration, default to queue. If it is still in discovery, default to pause. Record user overrides in the handoff envelope.

### Clarification budget

Ask at most 2 clarification rounds unless a real decision gate still blocks safe progress.

### Localized trigger phrases

Match intent regardless of language. English/Vietnamese routing hints:

| Skill | English triggers | Vietnamese triggers |
|---|---|---|
| `/b-spec` | clarify, requirements, scope, rough idea | lam ro, yeu cau, pham vi, y tuong tho |
| `/b-plan` | plan, design, decompose, approach | lap ke hoach, thiet ke, huong tiep can, chia nho |
| `/b-research` | docs, library, API, compare, look up | tra cuu, tai lieu, so sanh, tim hieu |
| `/b-implement` | implement, add, build, execute, finish | trien khai, thuc hien, viet code, hoan thanh |
| `/b-refactor` | rename, extract, move, inline, delete | doi ten, tach, di chuyen, xoa, don dep |
| `/b-debug` | bug, broken, error, stack trace, regression | loi, hong, khong chay, sai, truy vet |
| `/b-test` | tests, coverage, failing test, snapshot, mock | kiem thu, viet test, do bao phu, mock |
| `/b-e2e` | E2E, browser, UI flow, Playwright | trinh duyet, UI, end-to-end, kiem thu giao dien |
| `/b-review` | review, PR, lint, pre-PR | ra soat, review, kiem tra truoc PR |

Ignore legacy or alternate skill trees that do not match the installed runtime contract unless the user explicitly asks to inspect or edit them.

---

## 2. Source of truth and plan lifecycle

### Conflict ladder

Use this order when instructions compete:
1. User's latest explicit instruction.
2. Approved saved plan in `.opencode/b-skills/b-plan/<task-slug>.md`.
3. Approved chat plan.
4. Current repository evidence.
5. Conventional defaults recorded as assumptions.

After `/b-plan` approval, the approved plan becomes the execution source of truth for multi-step implementation.

### Durable plan metadata

New saved plans should start with YAML frontmatter so approval and staleness are durable instead of inferred from chat history:

```yaml
---
slug: <task-slug>
status: draft | approved | in-progress | complete | superseded
created_at: <YYYY-MM-DD>
approved_at: <YYYY-MM-DDTHH:MM:SSZ | null>
approved_by: user | null
approved_head: <git-sha | null>
risk: trivial | low | medium | high
touch_points:
  - <path>
---
```

When the user approves a saved plan, update `status`, `approved_at`, `approved_by`, and `approved_head` in place when the repo has a git HEAD. `approved` and `in-progress` are executable states; `draft`, `complete`, and `superseded` require explicit re-approval or revision.

### Plan staleness gate

A saved plan is stale if any of these are true:
- A file in `touch_points` or `Planned touch points` changed since approval.
- A `Confirmed decision` no longer matches repo reality.
- The git HEAD moved through a rebase/merge that touched planned files.

Prefer checking both committed drift and current working-tree drift when `approved_head` exists. A stale plan must be re-planned, not improvised against.

### Plan revision protocol

When the user asks to revise an approved plan, or `b-implement` discovers the plan is wrong mid-execution:
1. Edit the plan file in place; never write `plan-v2.md`.
2. Append `## Revisions` if missing, then add `- YYYY-MM-DD — <one-line delta>`.
3. Re-request approval if `Confirmed decisions`, `Planned touch points`, or `Steps` changed materially.
4. After approval, restart from the earliest affected step.

### Do not invent

Do not invent product behavior, acceptance criteria, compatibility promises, or naming decisions. Ask instead.

### Optional domain docs convention

- When a repo already has `CONTEXT.md` or `CONTEXT-MAP.md`, treat it as a glossary and bounded-context map, not as an implementation spec.
- Prefer canonical terms from those files when wording is ambiguous.
- Create or update domain docs only when the active skill explicitly owns that work.

---

## 3. Definitions and rubrics

The glossary here is canonical. Skills reference it; they do not redefine it.

### Non-trivial work

A change is non-trivial if any is true:
- Touches more than 3 files.
- Touches a public contract (exported API, route, CLI flag, schema, migration).
- Touches a sensitive path (auth, authz, billing, secrets, crypto, persistence migrations).
- Adds, removes, or changes a dependency.
- Modifies CI, build, or release configuration.

Otherwise the change is trivial and may use lighter paths.

### Small direct request

A request may bypass `/b-plan` and go straight to `/b-implement` only when all are true:
- 3 or fewer files.
- No exported/public contract change.
- No sensitive path.
- No remaining design decision; behavior is obvious from the request.

Anything failing this threshold goes back to `/b-plan`.

### Severity rubric (`/b-review`, `/b-debug`, any finding)

| Severity | Meaning |
|---|---|
| **BLOCKER** | Correctness, security, data-loss, or contract violation. Cannot ship. |
| **MAJOR** | Likely regression, missing changed-behavior coverage, or operability gap. |
| **MINOR** | Bug-prone edge case or follow-up cleanup that does not block shipping. |
| **NIT** | Style, naming, or preference. |

### Risk rubric (`/b-refactor`, `/b-implement`, verification depth)

| Risk | Criteria |
|---|---|
| **trivial** | One file, no exported change, few or no external references, behavior preserved. |
| **low** | Single module, internal refs only, narrow tests cover the area. |
| **medium** | Multi-file, exported/shared symbol, or partial test coverage. |
| **high** | Public contract, schema, migration, auth/security/billing path, or broad blast radius. |

Match verification depth to the risk band per §7.

### Confidence signal

When an answer rests on incomplete evidence, end with:

`Confidence: high | medium | low — <one-clause reason>.`

- Omit the line on trivial high-confidence answers.
- Use `medium` for consistent secondary evidence.
- Use `low` for snippet-only, single weak source, or material gaps.

---

## 4. Tool model

### Tool priority

Use the lightest reliable tool first.

| Task shape | First choice | Then narrow with |
|---|---|---|
| Graph overview, architecture, blast radius | `gitnexus-radar` when indexed, fresh, target-aware | `serena-symbol-toolkit` |
| Exact symbol discovery, declarations, references, symbol edits | `serena-symbol-toolkit` | Native tools + `apply_patch` |
| Library/framework docs | `context7-docs` | `/b-research` |
| Web search | `brave-discovery` | `firecrawl-extraction` |
| Known URL extraction | `firecrawl-extraction` | `firecrawl-extended`, then `firecrawl-deep` |
| Local document extraction | `firecrawl-extraction` (`firecrawl_parse`) | `firecrawl-extraction` (`firecrawl_scrape`) |
| Browser automation | `playwright-browser` via `/b-e2e` | none |

### Radar/hands boundary

GitNexus is optional radar; Serena is primary hands. GitNexus scopes graph risk and boundaries. Serena confirms exact symbols, bodies, references, and edits.

### GitNexus freshness gate

Use GitNexus only when the repo is indexed, fresh, and target-aware. If unavailable, stale, or missing the target, warn once and continue with Serena or native tools. Stale graph output is not evidence.

### Tool selection rules

- Single-file or local-only task: skip GitNexus.
- Known symbol edit: Serena first; GitNexus only for shared/exported or cross-boundary impact.
- Large unfamiliar area: one GitNexus pass to narrow, then Serena confirms.
- Do not use GitNexus and Serena in parallel on the same exact symbol hunt.
- Do not escalate to a second MCP when the first authoritative source already answered.
- Pick the cheapest discovery tool that closes the next question.

### MCP bundles

Skills reference bundles by name instead of repeating tool lists.

#### `serena-symbol-toolkit`

- Server: `serena`.
- Session init once per session: `check_onboarding_performed`, then `onboarding` if needed.
- Use for symbol discovery, references, diagnostics, and symbol-aware edits.
- LSP caveat: non-LSP languages and DSLs are not authoritative for rename/safe-delete/diagnostics; widen verification.

#### `gitnexus-radar`

- Server: `gitnexus`.
- Optional graph radar for unfamiliar architecture, blast radius, route/tool surfaces, and shared boundaries.
- Never use for symbol editing or exact-body inspection.

#### `context7-docs`

- Server: `context7`.
- Use `resolve-library-id` then `query-docs`.
- Pin versions from manifests and lockfiles before querying.
- If unavailable, prefer official-docs URLs before generic web search.

#### `brave-discovery`

- Server: `brave-search`.
- Use `brave_web_search` for page discovery only.
- `brave_news_search` and `brave_image_search` are opt-in for explicitly news/visual questions.

#### `firecrawl-extraction` (default tier)

- Server: `firecrawl`.
- Use `firecrawl_scrape` or `firecrawl_parse` for known URLs or local documents.

#### `firecrawl-extended` (conditional tier)

- Use `firecrawl_map` or `firecrawl_extract` only for site structure or structured fields.

#### `firecrawl-deep` (last-resort tier, requires explicit user approval)

- Use `firecrawl_interact` or `firecrawl_agent` only after lower tiers fail.
- Approval is per invocation by default.
- A user may grant a run-scoped capped pre-authorization only when the grant names both a numeric invocation cap and the current run. Without an explicit cap, the carve-out is invalid and per-invocation approval still applies.
- Record the granted cap in the status-block `notes` field and the handoff-envelope `carve-outs` field, decrement it on each use, and surface the remaining count in the next status block.
- The carve-out expires when the run ends, the cap is exhausted, or the user revokes it. It never overrides §6 safety gates.

#### `playwright-browser`

- Use the Playwright MCP when available; fall back to local Playwright CLI when already installed.
- Any `*_unsafe` browser tool requires explicit approval per invocation.

#### Sequential-thinking

Bundled but optional. Use only when 3 or more plausible hypotheses remain with equal cheapest-verification cost.

### MCP availability and fallback ladder

Assume bundles are available; do not preflight. On failure, retry once narrower, then fall back.

- `serena-symbol-toolkit` unavailable -> native Glob/Grep/Read + `apply_patch`; widen verification.
- `gitnexus-radar` unavailable, stale, or missing target -> continue without graph evidence.
- `context7-docs` unavailable -> official docs via `brave-discovery` + `firecrawl-extraction`.
- `firecrawl-extraction` unavailable -> search snippets only and mark the answer `Confidence: low`.
- `playwright-browser` unavailable -> local Playwright CLI if installed; otherwise stop and report browser automation unavailable.

### Fallback labeling

When fallback changes the evidence path or verification route, tag the affected step or finding as `[degraded: <reason>]`.

### Tool-use heuristics

- Around 12 MCP calls in one run, pause and summarize remaining unknowns before more discovery.
- Do not open a second tool-heavy thread until the current investigation, edit, or verification thread is closed.
- Retry only transient or fixable-by-narrowing failures; stop for auth failures.
- Reuse recently fetched URLs, docs, symbol results, and search results instead of re-fetching.
- `gitnexus-radar` should usually stay to 1-2 calls per run; more often means the question belongs back in Serena or native tools.

### Run cost signal

When a non-trivial run consumes notable budget, include a one-line cost summary in the status-block `notes` field, for example:

`cost: gitnexus=2, serena=14, context7=1, firecrawl-deep=1, iterations=2/3`

### Global bundle/path guards (runtime, not just maintainer norm)

- A skill must not invent a new MCP bundle name.
- A skill must not write to a path outside §8.
- A skill must not redefine the canonical approval template, fallback label, iteration cap, rubrics, slug/run-id format, manifest schema, status block, or handoff envelope.

---

## 5. Evidence standards

Evidence hierarchy:

`runtime > symbol > graph > text > search snippets`

- Graph evidence helps review and scoping but does not prove an edit is safe.
- Search snippets are discovery only. If they are the final source, label the answer snippet-only with `Confidence: low`.
- When authoritative sources disagree, prefer the one matching the pinned version; otherwise label the conflict and lower confidence.

### Documentation-backed decisions

When framework, library, or vendor docs materially influence an implementation or review conclusion, cite the supporting source.

- Do not cite obvious local code or language semantics.
- One narrow authoritative lookup is enough.
- Every cited URL must come from a source fetched in this session; if not, fetch it or label the claim `Confidence: low — uncited recall`.

### Token budget

Keep runtime prose short. Preserve rules, schemas, and safety gates; push long examples and low-frequency explanation into skill or reference files.

---

## 6. Safety gates

### Approval-required actions

Approval is required before installs, dev servers, migrations, destructive commands, production/staging-like writes, broad refactors, commits, or shared-environment mutation.

### Command risk classes

- **read-only** — inspect files/git/deps or run non-mutating diagnostics.
- **project-write** — edit approved source, tests, docs, generated artifacts, or local config.
- **dependency-write** — install/remove/update deps or regenerate lockfiles.
- **environment-write** — start/stop servers, containers, emulators, DBs, jobs, or persisted-auth browser sessions.
- **external-write** — mutate APIs, staging/prod, queues, payments, email/SMS, or analytics.
- **destructive** — delete data/files/branches, reset state, rewrite history, clean worktrees, or drop DBs.

### Canonical approval ask

Use this template:

```text
[approval] <action in imperative form>
Effect: <blast radius and any mutation>
Proceed? (y/n)
```

### Public web privacy gate

- Never send private stack traces, internal URLs, customer data, secrets, or proprietary code to public web tools without explicit approval.
- Sanitize queries when a sanitized form can still answer the question.
- If sanitizing removes the essential signal, stop and ask.

### Sensitive file safety

- Never read, search, print, diff, edit, upload, summarize, or commit likely-secret files without explicit permission.
- If unsure whether a file is sensitive, stop and ask.

### Repo-local artifact safety

- Saved plans under `.opencode/b-skills/b-plan/` are canonical source-of-truth files.
- Before any suite write under repo-local `.opencode/`, ensure `.opencode/.gitignore` contains `*`.
- Do not store auth/session state or other sensitive run artifacts under repo-local `.opencode/` unless the user explicitly opts in.
- Default sensitive artifacts to `~/.config/opencode/b-skills/...` or `/tmp/opencode/b-skills/...`.

### Generated files and lockfiles

- Treat generated, vendored, minified, snapshot, golden, and lock files as derived unless explicitly requested or required.
- Update lockfiles only after approved dependency-write.
- Prefer changing generator sources; if manual generated updates are unavoidable, label them as partial evidence.

### Worktree safety

- Check dirty state before non-trivial edits.
- Preserve unrelated user changes.
- If current edits conflict directly with the task, stop and ask.

### Isolated workspace preference

- For non-trivial build, refactor, or debug work, prefer an isolated workspace or linked worktree when dirty state, public contracts, sensitive paths, or parallel work make it materially safer.
- Reuse existing isolation when the harness already provided it.
- If isolation is unavailable or declined, continue in place and note that choice when it affects confidence or cleanup.

### Patch discipline

- Before manual `apply_patch` edits, read the current target slice and anchor on stable headings, keys, or signatures.
- Prefer one file and one small hunk when context may drift.
- If `apply_patch` reports `missing expected lines`, treat it as `stale context`: re-read the target slice and retry with verified smaller context.

### Git safety

- Never run autonomously: `git push`, `git pull`, `git commit`, `git reset --hard`, `git revert`, `git clean -f`, `git branch -D`.
- Never use hook or signature bypass flags unless explicitly requested.

---

## 7. Execution discipline

Define success before non-trivial work. Choose the smallest safe path.

If the user asked only for diagnosis or explanation, stop at the confirmed answer unless they also asked for a fix.

### Scope expansion

When discovery reveals adjacent work, classify it before acting:
- **Required** — necessary to satisfy the approved goal or make verification pass.
- **Blocking decision** — changes behavior, public contracts, migrations, dependencies, or sensitive paths beyond the approved scope.
- **Follow-up** — useful cleanup or unrelated hardening that should be reported, not absorbed silently.

### Review checkpoints

- Use `b-review` at coherent checkpoints when a slice changes a public/external contract, auth/security/migration boundary, shared route/tool surface, or another milestone broad enough that regressions could hide behind later steps.
- Skip checkpoint review for trivial or purely local steps. If deferred because the tree is mid-transform, say so explicitly.

### Verification ladder

- Discover baseline commands in this order: explicit plan/user command, project scripts, CI config, repo docs, existing language defaults, then one clarification.
- Narrow local check first, broader affected-area check second, full project check only when risk or scope justifies it.

### Long-running commands

- Prefer bounded foreground commands with explicit timeouts.
- Starting background jobs, dev servers, containers, emulators, or watch modes requires approval when long-lived or mutating.
- If approved, record what was started, how it was stopped, and any remaining cleanup.

### Iteration cap

Use a maximum of 3 fix/verify loops per step before reporting the blocker or handing off.

### Transform rollback (shared across `b-implement`, `b-refactor`, `b-debug`)

If a partial edit leaves the tree broken and the next iteration cannot proceed cleanly:
1. Finish forward in one focused pass when coherence is close.
2. Otherwise patch-reverse only the edits made in the current step/transform.
3. Never exit the skill with the tree mid-transform.

File-level restore requires explicit user approval because it can discard unrelated user edits.

### Cascading failures (shared across `b-implement`, `b-refactor`, `b-test`)

If fixing the current failure creates a new failure in a previously passing area, treat that as plan/scope evidence rather than another ordinary iteration. After one attempted cascade fix that does not restore green, stop and either revise the plan, hand off to `b-debug`, or surface the cascade.

### Completion contract

A non-trivial run is done only when all are true:
- Required verification ran, or was explicitly skipped with reason.
- The status block was emitted (§9).
- A manifest exists when more than one artifact exists (§8).
- Outstanding follow-ups were captured on an existing report surface.
- The tree is coherent; no mid-transform leftovers remain.

### Truncated output

If command output truncates or times out, save the full output under `/tmp/opencode/b-skills/<skill>/<slug>.log` and inspect that file instead of guessing.

### Verification provenance

Every non-trivial final report lists the evidence used: commands, diagnostics, browser state, sources, and skipped or unavailable checks.

### Completion closure

- Before reporting completion, state final verification status, remaining cleanup or lingering processes/worktrees/test data/artifacts, and the natural next action.
- If an isolated workspace or linked worktree was used, say whether it remains active and whether cleanup is still pending.

### Empty-state defaults

- No git diff -> ask which commit, branch, or range to review.
- No approved plan -> check the small-direct-request threshold; otherwise route to `/b-plan`.
- No test framework -> ask before adding one.
- No browser-test framework -> ask before adding Playwright.
- No MCP for the requested bundle -> follow the fallback ladder and label the run `[degraded: <bundle> unavailable]`.

---

## 8. Artifacts

### Slug algorithm

Derive `<task-slug>` from the user's request:
1. Take the imperative form of the request.
2. Lowercase and replace non-ASCII with the closest ASCII equivalent.
3. Replace non-alphanumeric runs with `-` and trim edges.
4. Cap at 40 characters, ending at the previous `-` when truncation would split a word.
5. On collision, append `-2`, `-3`, and so on.

Examples:
- `Add rate limiting to the API` -> `add-rate-limiting-to-the-api`
- `Doi ten UserService thanh UserRepository` -> `doi-ten-userservice-thanh-userrepository`

### Run ID

`<YYYYMMDD-HHMMSS>-<task-slug>`

### Run-id continuity across handoffs

- Reuse the same `run-id` when a skill hands off to another skill for the same logical task.
- Include `run-id` in the handoff envelope whenever one already exists.
- If the receiving skill writes artifacts, its `manifest.json` should cross-link the upstream run directory in `source_run`.

### Non-plan artifact naming

- `report.md` — final human-readable report.
- `manifest.json` — run manifest.
- `<topic>.log` — command output.
- `<topic>.snapshot.{txt|json}` — tool snapshots.
- `screenshot-<step>.png` — browser screenshots.
- Anything else: lowercase-kebab-case with an explicit content suffix.

### Paths

- Plans: `.opencode/b-skills/b-plan/<task-slug>.md`
- Skill artifacts: `.opencode/b-skills/<skill>/<run-id>/`
- Saved reports: `.opencode/b-skills/<skill>/<run-id>/report.md`
- Sensitive artifacts: `~/.config/opencode/b-skills/<skill>/<run-id>/` or `/tmp/opencode/b-skills/<skill>/<run-id>/`
- Temporary logs: `/tmp/opencode/b-skills/<skill>/<slug>.log`

Do not write generated artifacts outside those paths unless editing project source files is the task.

### Retention and cleanup

- Keep saved plans and explicit review/research reports until the user removes them.
- Treat `/tmp/opencode/b-skills/...` artifacts as disposable scratch.
- Delete or avoid creating sensitive artifacts unless required.
- When a run creates test data, browser state, screenshots, logs, or generated files, report what was kept, cleaned up, or left for the user.

### Manifest schema

Any run that produces more than one artifact must include `manifest.json` at the root of its run directory:

```json
{
  "run_id": "<YYYYMMDD-HHMMSS>-<task-slug>",
  "skill": "<b-skill-name>",
  "status": "complete | blocked | partial",
  "source_run": "<relative path to upstream skill's run dir, or null>",
  "artifacts": ["<relative-path>", "..."],
  "commands": ["<command run>", "..."],
  "generated_files": ["<source path edited or created>", "..."],
  "cleanup": "<what was cleaned up, or 'none'>",
  "cost": "<one-line cost summary, see §4, or null>",
  "notes": "<one-line summary>"
}
```

Single-artifact runs may skip the manifest and report those fields inline instead.

---

## 9. Output contract

### Language

- Chat: match the user's most recent language.
- Saved artifacts: English, so plans and reports remain interoperable.

### Lead with the result

Findings, decisions, or the next action come first. Narration is secondary.

### Skill-exit status block

Every non-trivial skill run ends with a single fenced status block:

State values:
- `complete` — requested scope is done and required verification ran or was explicitly skipped.
- `blocked` — work cannot continue without an external fix, unavailable dependency, or failed required check.
- `needs-input` — a user decision or approval is required before safe progress.
- `handed-off` — current skill stopped because another skill owns the next required step.

```text
[status]
skill: <b-skill-name>
run-id: <YYYYMMDD-HHMMSS>-<task-slug>   (include on runs that wrote artifacts or are part of a handoff chain)
state: complete | blocked | needs-input | handed-off
artifacts: <comma-separated paths or 'none'>
next: <skill name or 'none'>
blockers: <one-line list or 'none'>
cause: <cause-class>   (required when state is 'blocked')
confidence: high | medium | low — <reason>   (omit when high and direct)
notes: <cost summary, carve-outs, or other run-scoped notes>   (omit when empty)
```

Required fields are `skill`, `state`, `artifacts`, `next`, and `blockers`. Every other field is omit-when-empty: skip the whole line rather than emit a placeholder. When present, `confidence` always sits immediately above `notes` so downstream skills can find it at a fixed offset.

For trivial runs, the block may be omitted.

### Error envelope (failure cause-class)

When `state: blocked`, `cause` must be one of:

| Cause class | Meaning |
|---|---|
| `tool_unavailable` | Required MCP/CLI/server missing or unreachable. |
| `auth_required` | Auth or permission step blocks progress. |
| `user_blocked` | Waiting on user decision or approval. |
| `iteration_cap` | Hit the per-step fix/verify cap. |
| `external_outage` | Third-party service or network outage. |
| `stale_index` | Graph/cache stale and fallback would lose too much evidence quality. |
| `policy_block` | Safety gate prevented the action. |
| `evidence_gap` | Required evidence could not be obtained. |
| `conflict` | Approved plan conflicts with repo state or another artifact. |
| `unsupported` | Request is outside suite capability. |

Pick the single cause the user can act on first; mention others in `blockers`.

### Handoff envelope

When a skill hands off to another skill, emit this fenced block before switching:

```text
[handoff]
source: <current skill>
run-id: <YYYYMMDD-HHMMSS>-<task-slug>   (include when one already exists)
goal: <one-line goal for the next skill>
decisions: <confirmed decisions or 'none'>
assumptions: <open assumptions or 'none'>
files: <relevant paths or 'none'>
verification: <expected check or 'none'>
blockers: <known blockers or 'none'>
carve-outs: <pre-authorized approvals scoped to this run>   (omit when empty)
next-skill: <b-skill-name>
```

Required fields are `source`, `goal`, `decisions`, `assumptions`, `files`, `verification`, `blockers`, and `next-skill`. `run-id` and `carve-outs` are omit-when-empty. The `run-id` propagates per §8 so the receiving skill writes artifacts under the same run.

### Standard report shape

For non-trivial implementation, debug, test, refactor, review, or research work, final responses include:
- answer, action, or findings first
- verification evidence
- blockers or skipped checks
- confidence signal when evidence is incomplete
- the natural next action
- the skill-exit status block

### Output verbosity cap

- Every BLOCKER must be reported.
- MAJOR / MINOR / NIT cap at 15 entries per severity; report any remainder as a one-line summary.
- `Checked and clean` caps at 5 entries, highest-risk first.
- Prefer 2-4 authoritative sources; do not exceed 8 unless the user asked for a literature scan.
- Do not narrate every tool call in the final report.

---

## 10. Cross-cutting decisions

### High-risk challenge gate

Before reporting work as complete when it touches auth/authz, security boundaries, migrations, public or external contracts, or irreversible external writes:
1. State the claim.
2. Name the strongest remaining risk.
3. Name the evidence that makes the claim acceptable now.

If the evidence is missing or indirect, widen verification, lower confidence, or stop.

### Test failure vs runtime bug

Use this table when a test is red:

| Signal | Lane |
|---|---|
| Assertion mismatch and production behavior is confirmed correct | `b-test` |
| Missing mock, fixture, setup, async/await, leaked state, snapshot drift after intentional change | `b-test` |
| Production behavior is uncertain or disputed | `b-debug` |
| Test reproduces a real reported symptom | `b-debug` |
| Newly added test exposes pre-existing wrong behavior | `b-debug` |
| Flaky test that sometimes passes without code changes | `b-test`, unless it proves a real product race/bug |

Never change production code purely because a test is red. Never change an assertion, snapshot, or golden file without confirming intended behavior first.

### Snapshot confirmation procedure

1. State the intended new behavior.
2. Point to the source change or product decision that justifies it.
3. Then update the snapshot.

### Flake handling

Rerun the suspected test up to 2 times in isolation. If it passes some runs and fails others without code changes, mark it `flaky`, capture the failing output under `/tmp/opencode/b-skills/b-test/`, and investigate timing, ordering, shared state, or external dependency causes before skipping or rewriting it.

### DOM-unit vs browser-flow boundary

- jsdom, happy-dom, React Testing Library, Vue Test Utils, Svelte testing-library, and similar non-browser-rendered tests -> `b-test`.
- Playwright, Cypress, WebdriverIO, Puppeteer, or any real Chromium/Firefox/WebKit flow -> `b-e2e`.
- Hybrid component tests stay in `b-test` unless they require a real browser engine, real network, real cookies, or visual assertions.

### Agent-cannot-reproduce protocol (shared across `b-debug`, `b-e2e`, `b-test`)

When the user can reproduce a symptom but the agent cannot:
1. Do not patch defensively.
2. Capture the environment differences: config, version, data, OS, runtime, env vars, feature flags.
3. Ask for one or more of: exact command/interaction sequence, failure logs, environment details, or a minimal repro.
4. If the user cannot supply more, offer: instrument and wait, treat as one-shot, or investigate the captured diff.
5. Never substitute speculation for a repro.

### Self-review vs reviewing-someone-else's-code

`/b-review` handles both:
- **Self-review** — assume author bias and verify the claimed spec harder.
- **External review** — be explicit about what blocks merge vs what is style.

---

## 11. Session lifecycle

### Session-start preflight (run once at first non-trivial action)

1. `git status --short`.
2. Note whether the checkout is already isolated.
3. Check for an approved plan under `.opencode/b-skills/b-plan/` matching the request.
4. Confirm MCP availability lazily on first use.
5. Acknowledge dirty state only when it could affect the request.

### Crash/resume

- If a prior run directory has a manifest, resume from its last complete artifact rather than restarting.
- If a run directory has no manifest, treat it as orphaned; do not delete it without asking.
- For saved plans, use the staleness gate (§2) to decide whether to resume or re-plan.

### Cross-skill conventions

- Skill descriptions cover intent and disambiguation only.
- Skills must not redefine shared rubrics, routing boundaries, canonical protocols, schemas, or the anti-pattern table; they should cite the relevant section here.
- A skill should switch to another skill only on a real stop/block condition, not for optional enrichment the current skill can finish inline.

---

## 12. Common rationalizations (suite-wide anti-patterns)

When tempted, name the rationalization and apply the counter instead of acting on it.

| Rationalization | Counter |
|---|---|
| "I'll fix this adjacent thing while I'm here." | Only if it is required to satisfy the approved step or make verification pass. |
| "I'll verify after the whole feature lands." | Each step should prove itself before the next step inherits its assumptions. |
| "The framework behavior is obvious." | If docs drove the choice, cite a fetched source. |
| "This dirty workspace is probably fine." | Decide isolation intentionally for non-trivial work. |
| "Tests pass, so it's probably fine." | Tests do not replace contract, security, or operability review. |
| "The diff is tiny." | Risk bucket, not line count, decides depth. |
| "This is probably the cause." | State `Root cause: <what> because <why>` before editing. |
| "I can leave the probe in until later." | Remove every probe before reporting success. |
| "I can't reproduce it, but a defensive patch is harmless." | Follow the agent-cannot-reproduce protocol instead of speculating. |
| "I'll cite this from memory." | Citations must come from a source fetched in this session. |

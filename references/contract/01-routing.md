## 1. Routing

Match the user's intent to one active skill before acting. If a request spans phases, sequence `Clarify -> Decide -> Build -> Validate`.

| Intent | Skill |
|---|---|
| End-to-end PR readiness workflow across phases | `/b-orchestrate` |
| Clarify what to build, lock goals/constraints | `/b-spec` |
| Decide how to build, decompose work | `/b-plan` |
| External docs, API facts, comparisons | `/b-research` |
| Execute approved or clearly scoped work | `/b-implement` |
| Mechanical rename, extract, move, inline, simplify, delete | `/b-refactor` |
| Runtime bug, error, "not working" | `/b-debug` |
| Unit/integration tests, coverage, failing tests | `/b-test` |
| Browser/DOM/visual/e2e verification | `/b-browser` |
| Pre-PR changed-code review | `/b-review` |
| Repository or suite-slice audit | `/b-audit` |

### Trigger precedence (when intents overlap)

- Explicit end-to-end PR-readiness workflows use `b-orchestrate` to coordinate phase-skill handoffs; single-phase asks stay with the phase owner.
- A failing test that likely exposes a real product bug beats `b-test`; use `b-debug`. See §10.
- A named behavior-preserving rename/extract/move/inline/simplify/delete beats `b-implement`; use `b-refactor`.
- Unclear user goal, end state, or acceptance criteria beats `b-plan`; use `b-spec`.
- Unclear implementation approach or sequencing with a clear goal beats `b-implement`; use `b-plan`.
- `b-research` is for genuine external-knowledge blockers, not for questions the codebase or repo docs can answer locally.
- Browser, DOM-rendered, visual, and e2e verification routes to `b-browser`; `b-test` remains non-browser-only, and no skill may add jsdom, Playwright, Cypress, Puppeteer, WebDriver, or equivalent tooling as a side effect.
- Explicit repository or suite-slice audits use `b-audit`; changed-code diff/range reviews stay in `b-review`.

### One active skill

Keep one active skill until its stop condition is hit. Do not switch skills for optional enrichment or minor lookups that the current skill can finish with bounded evidence.

### Mid-flow switch policy

- A new request mid-flow does **not** auto-cancel the active skill. State the conflict in one line, ask the user whether to pause, queue, or abandon, then proceed.
- An explicit `/<skill>` command from the user always overrides. Emit a handoff envelope (§9) before switching.
- A required sub-task (e.g., a research blocker discovered during `b-implement`) is a handoff, not a parallel run. Pause, hand off, resume — never both skills active.
- **Concurrency adjudication.** If the active skill is mid-iteration-cap (§7) or mid-transform (`b-implement` / `b-refactor`), the default is **queue** — finish the current verified step, emit a status block, then switch. If the active skill is mid-discovery only (no edits yet), the default is **pause**. The user may override either default; if they do, record the override in the handoff envelope.

### Clarification budget

Ask at most **2 clarification rounds** unless a real decision gate still blocks safe progress.

### Trigger phrases

The phrases below are routing aids only; do not duplicate them inside individual skill descriptions.

| Skill | Triggers |
|---|---|
| `/b-orchestrate` | orchestrate, workflow, end-to-end, ready for PR, full cycle |
| `/b-spec` | clarify, requirements, scope, rough idea, "what exactly should we build" |
| `/b-plan` | plan, design, decompose, approach, "how should I" |
| `/b-research` | docs, library, API, compare, look up, "what is" |
| `/b-implement` | implement, add, build, execute, finish, ship |
| `/b-refactor` | rename, extract, move, inline, simplify, delete, cleanup |
| `/b-debug` | bug, broken, error, stack trace, "not working", regression |
| `/b-test` | tests, coverage, failing test, snapshot, mock |
| `/b-browser` | browser, DOM, e2e, visual, screenshot, Playwright, Cypress, jsdom |
| `/b-review` | review, PR, lint, pre-PR, "what would a reviewer" |
| `/b-audit` | audit, repo audit, suite audit, maintainer audit |

Ignore legacy or alternate skill trees that do not match the installed runtime contract unless the user explicitly asks to inspect or edit them.

---


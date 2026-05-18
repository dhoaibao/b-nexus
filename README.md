# b-skills

A lean 9-skill suite for **OpenCode**, optimized around scoped workflows, Serena-backed symbol work, optional GitNexus graph radar, and explicit safety rules when work crosses risky boundaries.

Browser, DOM-rendered, visual, and e2e tests are intentionally unsupported. The suite handles non-browser unit, integration, and contract tests, but it does not add or drive jsdom, Playwright, Cypress, Puppeteer, WebDriver, or equivalent browser/DOM tooling.

## Install & Update

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash
```

Preview an install without writing into `~/.config/opencode/`:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash -s -- --dry-run
```

Uninstall b-skills-managed files from OpenCode config:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-skills/main/install.sh | bash -s -- --uninstall
```

The installer deploys this source repo into OpenCode's global config:
- `skills/` -> `~/.config/opencode/skills/`
- `commands/` -> `~/.config/opencode/commands/`
- `references/` -> `~/.config/opencode/references/b-skills/`
- `global/AGENTS.md` -> `~/.config/opencode/b-skills/AGENTS.md`
- `global/AGENTS.md` -> `~/.config/opencode/AGENTS.md` only when missing or approved

This repository is an install-only source layout. OpenCode does not load the checked-in `skills/`, `commands/`, or `references/` directories directly from this repo root.

## Token-Saving Defaults

- Keep OpenCode compaction and pruning enabled unless you are intentionally debugging context retention.
- Ignore generated outputs, caches, logs, and suite artifacts in watchers so they do not become background context.
- Disable broad, always-on MCP servers by default; enable project-specific MCPs per agent or task when they close an evidence gap.
- Use Serena for symbol work and Context7 for versioned library docs instead of broad file reads or generic web searches.
- Prefer structured extraction or query for specific web/document fields; reserve full-page markdown for source understanding or summaries.

## Skills

| Skill | Phase | When to use |
|---|---|---|
| `/b-spec` | Clarify | Clarify unclear end states, constraints, acceptance criteria, non-goals, and assumptions before planning or coding |
| `/b-plan` | Decide | Turn a clear goal into a short chat plan or saved execution plan |
| `/b-research` | Decide | Fetch external docs, API facts, config keys, method signatures, comparisons, recency-sensitive evidence, or approved local document evidence with structured extraction when specific fields are enough |
| `/b-implement` | Build | Execute approved plans or small direct requests in coherent verified steps |
| `/b-refactor` | Build | Execute concrete behavior-preserving transforms: rename, extract, move, inline, simplify, or delete |
| `/b-debug` | Validate | Confirm runtime root cause, apply approved containment when urgent, fix minimally, verify, and remove probes |
| `/b-test` | Validate | Write non-browser unit/integration/contract tests, fix test-only failures, evaluate coverage gaps, and route product bugs out of the test lane |
| `/b-review` | Validate | Review changed-code diffs, ranges, checkpoints, and in-scope untracked files for blockers, regressions, security, and coverage |
| `/b-audit` | Validate | Audit named repository or suite surfaces for systemic risk, sampled coverage, and residual risk |

Typical flow:

```text
/b-spec [rough idea] -> /b-plan [scoped task] -> approve plan -> /b-implement -> /b-test -> /b-review
/b-research [question]  # external docs, API facts, comparisons, or recent information
/b-debug [symptom]      # runtime bugs, errors, broken behavior, slow paths
/b-refactor [target]    # mechanical behavior-preserving transforms
/b-audit [surface]      # repository, maintainer, or suite-slice audit
```

## Repository Map

```text
b-skills/
├── AGENTS.md              # maintainer guidance for this source repo
├── global/AGENTS.md       # runtime kernel source installed into OpenCode config
├── references/            # shared runtime references installed under references/b-skills/
├── skills/<name>/         # skill instructions and optional per-skill reference.md files
├── commands/<name>.md     # thin slash-command wrappers
├── install.sh             # installer, updater, and uninstaller
└── scripts/               # validation and smoke-test helpers
```

## Docs

- `README.md` is the brief repo overview.
- `AGENTS.md` is the maintainer guide for editing this source repo.
- `REFERENCE.md` is the skill-by-skill reference guide.
- `global/AGENTS.md` is the runtime kernel source.
- `references/runtime-contract.md` is the detailed runtime contract.
- `references/domain-glossary.md` and `references/performance-checklist.md` are reusable cross-skill references.

Run `scripts/validate-skills.sh` before installing or committing suite changes.

# b-agentic

**An 11-skill agent workflow kernel for Claude Code.**

`b-agentic` turns rough developer intent into disciplined loops: clarify, plan, build, validate, debug, review, and audit. It is optimized around scoped execution, repo evidence, MCP tools, verification, and clean handoffs.

Claude Code is the reference runtime. Skills install as native Claude skills and appear as `/b-*` slash commands.

## Install & Update

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash
```

Preview without writing into `~/.claude/`:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --dry-run
```

Replace an existing `~/.claude/CLAUDE.md` after reviewing the managed snapshot:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --replace-memory
```

Uninstall managed files:

```bash
curl -fsSL https://raw.githubusercontent.com/dhoaibao/b-agentic/main/install.sh | bash -s -- --uninstall
```

The installer deploys this repo into Claude Code's personal config:
- `global/CLAUDE.md` -> `~/.claude/CLAUDE.md` when missing or approved
- `skills/<name>/` -> `~/.claude/skills/<name>/`
- `references/*.md` -> `~/.claude/b-agentic/references/`
- `references/*.md` -> `~/.claude/skills/<name>/references/b-agentic/` for each skill
- `claude/*.json` -> `~/.claude/b-agentic/templates/`
- install metadata and backups -> `~/.claude/b-agentic/`

If an existing `~/.claude/CLAUDE.md` is preserved, the installer exits with `activationState: pending`. Review `~/.claude/b-agentic/CLAUDE.md`, then rerun with `--replace-memory` or merge the kernel manually.

Settings and MCP configuration are installed as templates only in this release:
- `claude/settings.recommended.json` contains suggested `permissions`, `skillOverrides`, and `disableSkillShellExecution` settings.
- `claude/mcp.safe.template.json` contains Serena for local semantic code work.
- `claude/mcp.research.template.json` contains Context7, Brave Search, and Firecrawl for external evidence.
- `claude/mcp.browser.template.json` contains isolated Playwright MCP for browser/DOM/visual/e2e evidence.
- `claude/mcp.architecture.template.json` contains Serena plus optional GitNexus graph radar.
- `claude/mcp.project.template.json` remains the full convenience example for the original non-GitNexus MCP surfaces in one project config.

To apply those templates instead of only installing copies under `~/.claude/b-agentic/templates/`, use explicit flags after review:

```bash
install.sh --install-settings        # writes ~/.claude/settings.json only when missing
install.sh --replace-settings        # backs up and replaces ~/.claude/settings.json
install.sh --install-project-mcp     # writes project profile to .mcp.json only when missing
install.sh --replace-project-mcp     # backs up and replaces the current project's .mcp.json
install.sh --install-project-mcp --mcp-profile safe
```

Available MCP profiles are `safe`, `research`, `browser`, `architecture`, and `project`. The default profile for `--install-project-mcp` is still `project` for compatibility. Profiles use environment placeholders such as `${BRAVE_API_KEY}` and `${FIRECRAWL_API_KEY}`; set secrets in your environment, not in tracked files.

The first Claude-native release supports personal-global install only. Project-local `.claude/` installs, plugin packaging, hooks, and dynamic context injection are deferred until validator and smoke coverage prove global parity.

## Skills

| Skill | Phase | Use |
|---|---|---|
| `/b-orchestrate` | End-to-end | Coordinate phase handoffs until PR-ready, ready with follow-ups, or blocked |
| `/b-spec` | Clarify | Clarify unclear goals, constraints, acceptance criteria, non-goals, and assumptions |
| `/b-plan` | Decide | Turn a clear goal into an execution plan |
| `/b-research` | Decide | Fetch external docs, API facts, comparisons, or recent evidence |
| `/b-implement` | Build | Execute approved plans or small direct requests |
| `/b-refactor` | Build | Rename, extract, move, inline, simplify, or delete behavior-preserving code |
| `/b-debug` | Validate | Confirm runtime root cause and fix minimally |
| `/b-test` | Validate | Write or fix unit, integration, and contract tests |
| `/b-browser` | Validate | Collect browser, visual, screenshot, live UI, or e2e evidence |
| `/b-review` | Validate | Review changed code for blockers, regressions, security, and coverage |
| `/b-audit` | Validate | Audit named repo or suite surfaces for systemic risk |

Typical flow:

```text
/b-orchestrate [feature/fix request]  # full PR-readiness workflow
/b-spec [rough idea] -> /b-plan [scoped task] -> approve plan -> /b-implement -> /b-test -> /b-review
/b-browser [UI/e2e verification]
/b-research [question]  # external docs, API facts, comparisons, or recent information
/b-debug [symptom]      # runtime bugs, errors, broken behavior, slow paths
/b-refactor [target]    # mechanical behavior-preserving transforms
/b-audit [surface]      # repository, maintainer, or suite-slice audit
```

Mutating or coordinating skills are manual-only in Claude Code with `disable-model-invocation: true`: `b-orchestrate`, `b-plan`, `b-implement`, `b-refactor`, `b-debug`, `b-test`, and `b-browser`. Read-only clarification, research, review, and audit skills may be model-invocable when their descriptions match the request.

## Repository Map

```text
b-agentic/
├── CLAUDE.md              # Claude Code maintainer guidance for this source repo
├── global/CLAUDE.md       # Claude Code runtime kernel source
├── claude/                # settings and MCP templates
├── references/            # shared runtime references copied into skill support dirs
├── skills/<name>/         # Claude skill instructions and optional reference.md files
├── install.sh             # Claude Code installer, updater, and uninstaller
└── scripts/               # validation and smoke-test helpers
```

## Docs

- `README.md` is the brief repo overview.
- `CLAUDE.md` is the Claude Code maintainer guide for editing this source repo.
- `REFERENCE.md` is the skill-by-skill reference guide.
- `global/CLAUDE.md` is the runtime kernel source.
- `references/runtime-contract.md` is the detailed runtime contract; referenced sections are required read gates when a skill needs their schemas, checklists, or protocols.
- `references/performance-checklist.md` is a reusable cross-skill reference.
- `claude/README.md` documents the Claude Code runtime layout and first-release non-goals.

Run `scripts/validate-skills.sh` and `scripts/smoke-install.sh` before installing or committing suite changes.

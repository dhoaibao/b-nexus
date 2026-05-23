# b-agentic - Claude Code Runtime Authoring

Guidelines for creating, editing, and maintaining the Claude Code native `b-agentic` workflow kernel in this repository.

## Scope

- This file is the Claude Code maintainer guidance for the source repository.
- Claude Code is the reference runtime. Do not preserve OpenCode behavior as a product requirement unless a new plan explicitly asks for migration compatibility.
- Keep root docs targeted: `README.md` is the brief repo overview and install guide, and root `CLAUDE.md` is maintainer guidance for this repo. Do not add a root mirror reference doc.
- For runtime-facing behavior in this repo, source of truth is: registry-owned metadata in `skills/registry.yaml` and `runtimes/registry.yaml`, canonical prompt/kernel sources in `skills/*/prompt.md` and `references/contract/kernel.template.md`, then rendered outputs in `runtimes/<name>/kernel.md` and `skills/*/SKILL.md`, then `README.md` for overview-only orientation.
- Optional `skills/*/reference.md` files are skill-local support material; they must not become a second root doc surface.
- `install.sh` is the bootstrap orchestrator. It clones/updates the repo, then sources `tooling/install/common.sh` plus `runtimes/<name>/scripts/install.sh`. Shared install and uninstall behavior lives in the common core; each runtime driver defines destination paths, adapter-specific config hooks, wrapper behavior, manifest format, and install report wording.
- `scripts/validate-skills.sh` and `scripts/smoke-install.sh` are stable wrapper entrypoints only. The shared validation harness lives under `tooling/validate/`, and the shared smoke harness lives under `tests/smoke/` with adapter-owned `runtimes/<name>/tests/smoke.sh` lanes.
- Shared runtime-facing content under `skills/` and `references/contract/` must stay runtime-neutral. Runtime-specific paths, kernel filenames, install-layout details, and adapter caveats belong under `runtimes/<name>/*`, not in shared skills or shared contract prose.
- In shared runtime-facing prompt sources, `{{skill_support_path}}` is the only intentional bridge marker in this iteration; the renderer maps it to `${CLAUDE_SKILL_DIR}` in generated `SKILL.md` outputs. Do not add other Claude- or OpenCode-specific path assumptions to shared skills or shared contract files.
- When authoring runtime-facing skill prose in `prompt.md`, `CLAUDE.md` refers to the active runtime kernel, never this source-repo maintainer guide. Long-form schemas, rubrics, and edge-case protocols live in `references/contract/`; when a skill depends on one of them, phrase the instruction as a required read gate using the rendered installed skill support path `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/<section-file>.md`.
- Runtime conformance depends on explicit read gates plus the runtime gate checklist, not passive reminders. Keep those gates local to the step that uses the shared schema, checklist, or protocol.

## Registry Source Of Truth

- `skills/registry.yaml` owns skill metadata and rendered `SKILL.md` frontmatter; `skills/*/prompt.md` owns canonical skill bodies.
- `runtimes/registry.yaml` owns runtime metadata that generators and validators use for adapter inventory, kernel destinations, wrapper support, and kernel rendering.
- Both registry files intentionally stay within the JSON-compatible subset of YAML so shared repo tooling can validate and render them with Python standard library only.
- When registry-owned metadata changes, edit the registry first, rerun `python3 tooling/generate/registry_sync.py`, then update only the surrounding prose that is intentionally hand-authored.
- Registry order is user-facing order for generated tables and wrappers unless a renderer documents a narrower surface.

## Quick Links

- `skills/b-orchestrate/prompt.md` - coordinate full PR-readiness workflows across phase skills
- `skills/b-plan/prompt.md` - task decomposition and planning
- `skills/b-research/prompt.md` - library docs and multi-source research
- `skills/b-implement/prompt.md` - approved-plan execution
- `skills/b-refactor/prompt.md` - behavior-preserving code transforms
- `skills/b-debug/prompt.md` - hypothesis-driven debugging
- `skills/b-test/prompt.md` - test writing, coverage, and test-only failures
- `skills/b-browser/prompt.md` - browser/DOM/visual/e2e evidence
- `skills/b-review/prompt.md` - pre-PR changed-code review
- `skills/b-audit/prompt.md` - b-agentic suite self-audits (suite-only)
- `skills/b-ship/prompt.md` - commit, push, and open PR after READY FOR PR
- `references/` - reusable checklists and the detailed runtime contract
- `references/contract/kernel.template.md` - canonical runtime-kernel template source
- `runtimes/claude-code/configs/` - Claude Code settings and MCP templates
- `runtimes/claude-code/kernel.md` - rendered Claude Code runtime kernel output
- `runtimes/opencode/kernel.md` - rendered OpenCode runtime kernel output
- `runtimes/opencode/configs/` - OpenCode runtime layout docs
- `tooling/validate/` - shared validation runner and runtime-neutral checks
- `tests/smoke/` - shared smoke harness reused by runtime lanes
- `runtimes/runtime-template/` - scaffold for adding a new runtime adapter

## Claude Skill Frontmatter

Every rendered `skills/<name>/SKILL.md` must begin with YAML frontmatter:

```yaml
---
name: b-skill-name
description: >
  [Trigger-focused description, <=80 words. Answer only: when should Claude
  Code load or list this skill? Include the ALWAYS trigger condition and one
  sentence distinguishing this from similar skills.]
argument-hint: "[optional arguments]"
---
```

Required fields:
- `name` - kebab-case, prefixed with `b-`, matching the directory name.
- `description` - trigger-focused and concise; the combined `description` plus `when_to_use` text should stay comfortably below Claude Code's listing cap.

Supported optional fields used by this repo:
- `argument-hint` - concise autocomplete help for user-invocable skills.
- `when_to_use` - only when the description needs extra matching context.
- `user-invocable` - use only when a skill is background knowledge and should be hidden from the slash menu.
- `context` and `agent` - use only for approved forked-subagent skills.
- `paths` - use only when a skill should activate for specific file globs.
- `shell` - use only when a skill intentionally uses Claude Code dynamic shell context.

Repo conventions:
- Do not use legacy OpenCode-only compatibility or suite metadata fields.
- All skills are model-invocable when their descriptions match the request.
- Canonical frontmatter values live in `skills/registry.yaml` under each skill's `prompt` object; do not hand-edit generated `SKILL.md` frontmatter.

## Skill Directory Structure

```text
skills/<name>/
├── prompt.md          # Canonical runtime-neutral skill body (required)
├── SKILL.md           # Generated Claude-shaped delivery asset
├── reference.md       # Detailed skill-local reference (optional)
├── examples.md        # Usage examples (optional)
└── scripts/           # Utility scripts (optional)
```

Claude Code exposes each skill directory as `/b-*` after install. The old command-wrapper directory is removed because Claude skills create slash commands directly. `SKILL.md` is generated; edit `prompt.md` and `skills/registry.yaml`, then rerender.

Use supporting files when they materially improve token hygiene. Reference them from `prompt.md` with `{{skill_support_path}}/...`; the renderer converts that bridge marker into `${CLAUDE_SKILL_DIR}/...` in generated `SKILL.md` so installs continue to work from personal-global installs, project installs, and plugin packaging.

## Shared References

Top-level `references/*.md` files are allowed when two or more skills need the same checklist or pattern guidance.

- Keep them short, task-oriented, and reusable across skills.
- They may define optional conventions, such as glossary/domain-doc layouts, when adding a whole new skill would be overkill.
- `install.sh` copies shared references to `~/.claude/b-agentic/references/` and to each installed skill under `references/b-agentic/`.
- Treat shared reference-file changes like runtime-facing guidance: keep `README.md` and affected maintainer/runtime docs aligned in the same commit.

## Skill File Structure Template

Canonical source lives in `skills/<name>/prompt.md`; frontmatter metadata lives in `skills/registry.yaml`.

```markdown
# b-example

$ARGUMENTS

[1-2 sentence summary of what this skill does and why it exists.]

## When to use
- [Scenario]

## When NOT to use
- [Scenario that should trigger a different skill]

## Tools required
- `bundle-name` (see `CLAUDE.md` §4)

Tool fallback rules are centralized in the kernel; skills do not restate them.

## Steps

### Step 1 - [Name]
[Imperative instructions. Every step must have action verbs.]

## Output format
[Template or example]

## Rules
- [Task-specific constraints only; shared schemas live in CLAUDE.md or the runtime contract.]
```

When a canonical prompt needs a support-file read gate, use `{{skill_support_path}}/reference.md` or `{{skill_support_path}}/references/b-agentic/...`; do not hardcode `${CLAUDE_SKILL_DIR}` in `prompt.md`.

## MCP Selection Criteria

Skills declare MCP usage by referencing bundles summarized in `runtimes/claude-code/kernel.md` §4 and fully defined in `references/contract/` §4. Do not enumerate per-tool MCP lists inside skills. Native tools such as Glob/Grep/Read/Bash are not MCP bundles and may be listed separately when useful.

MCP user-scope configuration lives in the runtime-specific `runtimes/<name>/configs/mcp.user.template.json` templates. Claude Code copies its template to `~/.claude/b-agentic/templates/` and merges the user-scope MCP set into `~/.claude.json`; OpenCode copies its template to `~/.config/opencode/b-agentic/templates/` and merges into `~/.config/opencode/opencode.json`. The global set contains Serena, Context7, Brave Search, Firecrawl, Playwright, and GitNexus; runtime skills still use MCP lazily by evidence need. Keep MCP template changes documented in the corresponding runtime `configs/README.md` and root `README.md`, and covered by `scripts/validate-skills.sh` plus `scripts/smoke-install.sh`.

Rules:
- Never add a bundle just to increase coverage; every bundle must have a clear use case in the Steps section.
- Reference the bundle name. The bundle definition owns session-init steps, fallback behavior, cost/approval caveats, and language-coverage caveats.
- Label each bundle in "Tools required" with its role when it is conditional.
- Tool fallback rules are centralized in the kernel (see `runtimes/claude-code/kernel.md` §4); skills do not restate graceful degradation lines.
- Prefer the lightest capable tool. Do not force MCP-first behavior for exact strings, manifests, prose, small file reads, or other cases where native tools are cheaper and equally reliable.
- Do not list unsafe tool variants in skill workflows; approval is required per invocation.
- Do not commit API keys or secret-looking placeholders in MCP templates. Use Claude Code environment expansion such as `${CONTEXT7_API_KEY:-}`, `${BRAVE_API_KEY}`, and `${FIRECRAWL_API_KEY}` in templates; installer prompts may write user-provided keys only to user-scope `~/.claude.json`.

GitNexus-specific criteria:
- GitNexus is always optional radar. It is never a primary dependency and never acts as the editing layer.
- Serena is primary hands for exact symbol discovery, source inspection, references, and symbol-aware edits.
- Add `gitnexus-radar` only when graph-level intelligence materially improves the workflow.
- If the target symbol or file is already known, or the task is local to a single file/module, skip GitNexus and go straight to Serena or native tools.

## File Sync Rules

Canonical skill sources live in `skills/<name>/prompt.md` plus the matching `prompt` metadata in `skills/registry.yaml`. The renderer writes `skills/<name>/SKILL.md`. When changing skill files:

| Change type | Action |
|---|---|
| Create skill | Add a `skills/<name>/prompt.md`, registry metadata, optional supporting files, then rerender `SKILL.md` |
| Update skill | Edit `skills/<name>/prompt.md` and/or registry metadata; update supporting files only when they improve token hygiene |
| Delete skill | Delete the prompt, generated `SKILL.md`, optional supporting files, registry entry, and the directory if empty |

Runtime contract sync:
- When always-on runtime behavior changes, update `references/contract/kernel.template.md` and rerender `runtimes/<name>/kernel.md` for every affected runtime.
- When detailed schemas/rubrics/protocols change, update `references/contract/`.
- When registry-owned metadata changes, update the registries first and keep generated skill/kernel/wrapper/doc surfaces in sync in the same commit.
- Keep related repo docs aligned in the same commit.

Root `CLAUDE.md` remains maintainer guidance for this source repository.

## Runtime Adapters

Each supported runtime has its own adapter directory under `runtimes/<name>/`. The adapter holds delivery artifacts for that runtime only. Shared skills and shared contract files live outside `runtimes/` and must stay runtime-neutral. Runtime-specific paths, kernel filenames, install layouts, and bridge caveats belong in the adapter docs and adapter scripts. In this iteration, `{{skill_support_path}}` is the only intentional shared prompt bridge marker and renders to `${CLAUDE_SKILL_DIR}` in generated delivery assets.

### Adapter directory structure

```text
runtimes/<name>/
├── kernel.md      # Always-on runtime rules (installed as the runtime's memory/context file)
├── configs/       # Runtime-specific config templates (settings, MCP, etc.)
├── scripts/       # Install and validate drivers for this adapter
└── tests/         # Smoke lane sourced by tests/smoke/install.sh
```

`claude-code` and `opencode` adapters exist end-to-end. Do not create adapters for other runtimes without an approved plan.

### What is wired today vs. what is still TODO

`install.sh` is a bootstrap orchestrator that parses arguments, clones/updates the repo, then sources `tooling/install/common.sh` plus `runtimes/$RUNTIME/scripts/install.sh`. The shared core owns skill/reference sync, managed-kernel handling, JSON merge and cleanup helpers, shared prompt flows, and install/uninstall control flow. Each runtime driver owns destination paths, adapter-specific config hooks, wrapper behavior, manifest format, and install report wording. `scripts/validate-skills.sh` now delegates to `tooling/validate/run.sh`, and `scripts/smoke-install.sh` now delegates to `tests/smoke/install.sh`, which sources the registered runtimes' `runtimes/<name>/tests/smoke.sh` lanes.

Completed:
- Source-side runtime selection (`--runtime`, `B_AGENTIC_RUNTIME`).
- Shared installer core under `tooling/install/common.sh` with thin runtime drivers.
- Per-runtime install scripts under `runtimes/<name>/scripts/install.sh`.
- Per-runtime validators under `runtimes/<name>/scripts/validate.sh`.
- Shared validation harness under `tooling/validate/` with stable root wrappers.
- Shared smoke harness under `tests/smoke/` with adapter-owned runtime lanes.
- OpenCode adapter with kernel, configs, install, and validate scripts.
- Runtime scaffold under `runtimes/runtime-template/` for future adapter onboarding.
- Smoke tests cover both `--runtime=claude-code` and `--runtime=opencode` through registered runtime lanes.

Bridge constraints that still exist:
- Shared prompt sources stay runtime-neutral, but rendered `SKILL.md` outputs remain Claude-Code-shaped so both runtimes can consume the same tree.
- `{{skill_support_path}}` remains the only intentional shared prompt bridge marker, and it currently renders to `${CLAUDE_SKILL_DIR}` for all installed skill assets.
- OpenCode owns the bridge-specific install layout and command-wrapper behavior under `runtimes/opencode/*` until a future native re-templating pass exists.

### Adding a new runtime adapter

1. Start from `runtimes/runtime-template/` and copy it to `runtimes/<name>/`.
2. Add the runtime entry to `runtimes/registry.yaml`, then rerun `python3 tooling/generate/registry_sync.py` so `runtimes/<name>/kernel.md` renders from the shared kernel template.
3. Implement any new shared installer behavior in `tooling/install/common.sh` first when it is adapter-agnostic.
4. Create `runtimes/<name>/scripts/install.sh` as a thin driver with the runtime's destination paths, adapter-specific config hooks, wrapper behavior, manifest format, and report wording.
5. Create `runtimes/<name>/scripts/validate.sh` with the runtime's required invariants.
6. Create `runtimes/<name>/tests/smoke.sh` so the shared harness can load the new runtime lane without root-script edits.
7. Extend the canonical prompt/kernel renderers only when the new adapter needs a different delivery shape or bridge token.
8. Update `README.md`, `CLAUDE.md`, and any affected adapter/runtime docs in the same commit.

### Runtime file sync rule

When always-on runtime behavior changes, update `references/contract/kernel.template.md`, rerender `runtimes/<name>/kernel.md`, and keep `README.md` and `CLAUDE.md` aligned in the same commit. When runtime config templates change, update `runtimes/<name>/configs/`.

## Doc Sync Rule

Any change to a skill prompt, generated skill file, or skill metadata requires updating the maintained docs that actually describe that surface in the same commit. Do not create or revive a root mirror reference doc.

| Change type | Required doc follow-through |
|---|---|
| Create skill | Add it to `README.md` and any affected routing, runtime, or install docs |
| Update skill | Update `README.md` only if the public overview, install story, or source layout changed; otherwise update only the affected skill-local or shared references |
| Delete skill | Remove it from `README.md` and any affected routing, runtime, install, or support docs |

Never leave `README.md`, routing docs, or affected support files out of sync with a skill change.

## Quality Checklist

Before merging any skill prompt/frontmatter change, verify:

1. Description <=80 words.
2. Every step uses imperative verbs.
3. Fallbacks are explicit without duplicating global MCP fallback rules.
4. Inter-skill handoffs have trigger conditions and resume expectations.
5. No trigger keyword regression.
6. `scripts/validate-skills.sh` passes.
7. No avoidable churn or repeated preflights.
8. Token hygiene is preserved.
9. No duplicated global concepts from `CLAUDE.md` or `references/contract/`.
10. Reference gates are explicit at the point of use.
11. Runtime enforcement is preserved through `runtimes/*/kernel.md`, skill read gates, validator checks, and install smoke tests for every supported runtime.

# b-skills — Repo conventions & skill authoring

Guidelines for creating, editing, and maintaining the install-only OpenCode skill suite in this repository.

## Scope

- This file is maintainer guidance for the source repository.
- Runtime suite behavior lives in `global/AGENTS.md` and the individual `skills/*/SKILL.md` files.
- `install.sh` deploys the runtime files into `~/.config/opencode/`.

## Quick links

- `skills/b-plan/SKILL.md` — Task decomposition and planning
- `skills/b-research/SKILL.md` — Library docs and multi-source research
- `skills/b-implement/SKILL.md` — Approved-plan execution
- `skills/b-debug/SKILL.md` — Hypothesis-driven debugging
- `skills/b-review/SKILL.md` — Pre-PR changed-code review
- `global/AGENTS.md` — Runtime rules source installed as OpenCode's global `AGENTS.md`
- `commands/` — Thin slash-command wrappers that load the matching skills

---

## Frontmatter spec

Every `skills/<name>/SKILL.md` must begin with YAML frontmatter:

```yaml
---
name: b-skill-name
description: >
  [Trigger-focused description, <=80 words. Answer only: "when should OpenCode load this skill?"
  Include: ALWAYS trigger condition, key Vietnamese + English trigger phrases,
  and one sentence distinguishing this from similar skills.
  Do NOT include usage instructions — those go in the skill body.]
compatibility: opencode
metadata:
  suite: b-skills
---
```

**Required fields:**
- `name` — kebab-case, prefixed with `b-`
- `description` — <=80 words, trigger-focused only

**OpenCode-supported optional fields:**
- `license`
- `compatibility`
- `metadata`

**Repo conventions:**
- Set `compatibility: opencode`
- Set `metadata.suite: b-skills`

**Do not carry forward Claude-only frontmatter fields** such as top-level `effort`, `model`, `disable-model-invocation`, `user-invocable`, or `paths`.

**Description rules:**
- Start with a one-line summary of what the skill does
- Include `ALWAYS invoke when...` with specific trigger phrases
- Include both Vietnamese and English trigger keywords
- End with disambiguation from the most similar skill
- No step-by-step instructions, no tool lists, no output format details

---

## Skill directory structure template

```text
skills/<name>/
├── SKILL.md           # Main instructions (required)
├── reference.md       # Detailed reference (optional)
├── examples.md        # Usage examples (optional)
└── scripts/           # Utility scripts (optional)
    └── helper.sh

commands/<name>.md     # Matching slash-command wrapper (required in this repo)
```

For this repo, each skill currently uses a single `SKILL.md` file plus a thin command wrapper. Add extra files only when they materially improve maintenance.

---

## Skill file structure template

```markdown
---
name: b-example
description: >
  [<=80 words, trigger-focused]
compatibility: opencode
metadata:
  suite: b-skills
---

# b-example

$ARGUMENTS

[1-2 sentence summary of what this skill does and why it exists.]

## When to use
- [Bullet list of scenarios]

## When NOT to use *(optional but recommended)*
- [Scenarios that should trigger a different skill instead]

## Tools required
- `tool_name` — from `mcp-server` MCP server
- `tool_name` — from `mcp-server` MCP server *(optional, for [condition])*

Fallbacks: reference the global MCP rules and add only skill-specific stop/degrade behavior.

Graceful degradation: [✅ Possible / ⚠️ Partial / ❌ Not possible] — [brief explanation]

## Steps

### Step 1 — [Name]
[Imperative instructions. Every step must have action verbs.]

### Step 2 — [Name]
...

---

## Output format
[Template or example of expected output]

---

## Rules
- [Bullet list of constraints and guardrails]
```

---

## Command wrapper template

Every skill in this repo must have a matching `commands/<name>.md` wrapper:

```markdown
---
description: Run the b-example skill for [short purpose]
---

Load the `b-example` skill and follow it exactly for this request.

$ARGUMENTS
```

Keep command wrappers thin. They are entrypoints, not duplicate logic stores.

---

## MCP selection criteria

When deciding which MCPs a skill should use:

| Role | When to add | Example |
|---|---|---|
| **Primary** | Skill cannot function without it | brave-search for b-research |
| **Secondary** | Skill uses it conditionally for a specific step | context7 for b-research (HOWTO queries only) |
| **Optional** | Enhances quality but skill works without it | sequential-thinking for b-review |

**Rules:**
- Never add an MCP just to increase coverage — every MCP must have a clear use case in the Steps section
- Document skill-specific fallback behavior; do not duplicate global MCP fallback text
- Label each MCP in "Tools required" with its role: required vs `*(optional, for [condition])`*
- Always include a `Graceful degradation:` line summarizing fallback behavior
- Serena-using skills in this repo must assume OpenCode's generic `ide` context: prefer Serena for symbol-aware code work, keep overlapping basic file/shell tasks on native OpenCode tools, and avoid multi-project assumptions unless the runtime contract changes

**GitNexus-specific criteria:**
- GitNexus is always **optional radar** for this suite. It is never a primary dependency of any skill and never acts as the editing layer.
- Serena is the primary **hands** layer for exact symbol discovery, source inspection, references, and symbol-aware edits.
- Add GitNexus to a skill only when graph-level intelligence (cross-file impact, architecture context, execution-flow discovery, stale-index detection, route/API consumers, multi-repo mapping) materially improves the workflow. GitNexus should be the preferred first step for graph-shaped tasks only when the repo is indexed, fresh, and the target file/symbol is represented; Serena then handles exact symbol inspection and edits.
- If the target symbol or file is already known, or the task is local to a single file/module, skip GitNexus and go straight to Serena. Use GitNexus only when cross-file, architectural, execution-flow, or blast-radius context is needed.
- Every skill that uses GitNexus must use the global indexing/freshness/target gate and fall back to Serena/native tools when the gate fails.
- GitNexus must never replace Serena for precise symbol-level edits (`rename_symbol`, `safe_delete_symbol`, `replace_symbol_body`, etc.).

---

## File sync rules

All skills live in `skills/<name>/SKILL.md`. When changing skill files:

| Change type | Action |
|---|---|
| **Create** new skill | Create `skills/<name>/SKILL.md` and `commands/<name>.md` |
| **Update** skill | Edit `skills/<name>/SKILL.md` and keep `commands/<name>.md` aligned |
| **Delete** skill | Delete `skills/<name>/SKILL.md`, `commands/<name>.md`, and the directory if empty |

**`global/AGENTS.md` sync** — when runtime behavior changes, update `global/AGENTS.md` in the same commit and keep any related repo docs aligned.

**Root `AGENTS.md`** — keep repo-level maintainer guidance in the root `AGENTS.md` so it remains available when working in this source repository.

---

## Doc sync rule

**Any change to a skill file — create, update, or delete — requires updating both `README.md` and `REFERENCE.md` in the same commit.**

| Change type | README.md | REFERENCE.md |
|---|---|---|
| **Create** skill | Add row to skills overview table | Add full reference section |
| **Update** skill | Update the skill overview and install/source-layout notes if changed | Rewrite the skill's reference section to match |
| **Delete** skill | Remove the skill from the overview and source-layout docs | Remove the skill's reference section entirely |

Never leave README or REFERENCE out of sync with a skill file change.

---

## Quality checklist

Before merging any skill file change, verify:

1. **Description <=80 words** — verify with `wc -w` on the extracted description text
2. **Every step has imperative verbs** — "Call X", "Extract Y", "Check Z" — not "X is called" or "Y should be extracted"
3. **Fallbacks are explicit without duplication** — global MCP fallbacks cover shared behavior; skills state only local stop/degrade differences
4. **Inter-skill handoffs have trigger conditions** — "if [condition] -> use /b-[other]" with the specific condition, not just "consider using"
5. **No trigger keyword regression** — before rewriting a description, list all current trigger keywords and verify all survive in the new version
6. **Suite validator passes** — run `scripts/validate-skills.sh` before installing or committing skill changes

---

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **b-skills** (260 symbols, 255 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, first ensure sensitive files and local private artifacts are excluded, then run `gitnexus analyze` only when indexing is safe.

## Always Do

- Use GitNexus as optional radar for graph-shaped code tasks only when the repo is indexed, fresh, and target-aware: architecture context, blast radius, route/API consumers, changed-scope validation, execution-flow discovery, or multi-repo mapping.
- If GitNexus is unavailable, stale, unindexed, missing FTS, or missing the target, warn once and continue with Serena/native tools.
- Use Serena as the primary hands layer for precise symbol discovery, source inspection, references, edits, and renames.
- Run `gitnexus_detect_changes()` before committing only when GitNexus is available, fresh, indexed, and relevant to the changed scope.
- Warn the user before editing if GitNexus impact analysis returns HIGH or CRITICAL risk.

## Never Do

- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER use GitNexus as a replacement for Serena's precise symbol-level edits.
- NEVER rename symbols with plain find-and-replace; use Serena symbol rename when available, or GitNexus/manual reference checks when Serena is unavailable.
- NEVER commit without checking changed scope; use `gitnexus_detect_changes()` only when GitNexus is fresh, indexed, and relevant to the changed scope, otherwise inspect `git diff` and relevant references manually.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/b-skills/context` | Codebase overview, check index freshness |
| `gitnexus://repo/b-skills/clusters` | All functional areas |
| `gitnexus://repo/b-skills/processes` | All execution flows |
| `gitnexus://repo/b-skills/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

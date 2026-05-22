---
name: b-orchestrate
description: >
  End-to-end PR readiness orchestration for workflows spanning plan,
  implementation, optional tests, review, and review-fix loops until ready
  for PR. Invokes phase skills via the Skill tool, parses their status
  blocks, and stops at approval, blocker, or readiness. Unlike b-implement,
  b-orchestrate owns sequencing across multiple skills rather than changing
  code itself.
argument-hint: "[workflow-goal]"
---

# b-orchestrate

$ARGUMENTS

Coordinate a complete PR-readiness workflow across the phase skills. `b-orchestrate` owns phase selection, checkpoint manifests, handoff envelopes, and final synthesis only; the phase owner does the actual plan, implementation, test, debug, refactor, research, or review work. Invoke each phase skill via the Skill tool and resume from its returned status block.

If `$ARGUMENTS` is present, treat it as the workflow goal plus any explicit constraints such as skipped tests, required verification, or a known plan path.

## When to use

- The user asks for one end-to-end workflow from unclear request through PR readiness.
- The work needs plan, build, optional tests, review, and review-fix sequencing.
- The user wants review findings fixed and re-reviewed until ready for PR or blocked.

## When NOT to use

- The user asks for only one phase -> use that phase skill directly.
- The request is a simple scoped edit with no workflow loop -> use **b-implement**.
- The user asks only for a code review or audit -> use **b-review** or **b-audit**.
- The user asks only to diagnose a runtime bug -> use **b-debug**.
- The user asks only for a named behavior-preserving transform -> use **b-refactor**.

## Tools required

- Native tools - inspect status, diffs, docs, and verification commands.
- Phase skills - **b-plan**, **b-implement**, **b-test**, **b-browser**, **b-review**, plus **b-debug**, **b-refactor**, and **b-research** when a phase routes there. These skills receive the actual work; `b-orchestrate` only coordinates transitions by emitting handoff envelopes and checkpoint manifests.
- `serena-symbol-toolkit` *(optional, through the active phase skill when symbol work matters)*
- `gitnexus-radar` *(optional, through the active phase skill for graph-shaped risk)*


## Steps

### Step 1 - Start the workflow

Run `git status --short`, name the source of truth, and define success as a **b-review** verdict of **READY FOR PR** with required verification complete for suite-supported scope. If UI/browser-relevant work needs browser, DOM, visual, or e2e evidence, require **b-browser**-verified evidence from supplied/CI evidence, existing repo tooling, or approved live-browser operation before **READY FOR PR**; if the user explicitly accepts skipped checks or follow-ups, success may be **READY WITH FOLLOW-UPS** instead.

For non-trivial workflows, read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/08-artifacts.md`, mint a run-id, and write a checkpoint manifest under `.b-agentic/b-orchestrate/<run-id>/manifest.json` when the workflow pauses or needs durable resume state.

Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/01-routing.md` and `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/09-output.md` before routing across phase skills. Keep exactly one phase owner active at a time; every phase transition is a stop condition plus handoff, not parallel execution.

For each phase transition, emit the handoff envelope in chat as audit trail, then invoke the next phase skill via the Skill tool with the workflow goal, source of truth, and any prior phase output. Parse the returned status block. Branch on its `state`: `complete` -> continue to the next phase; `blocked` -> surface the blocker and stop; `needs-input` -> relay the question to the user, resume on answer; `handed-off` -> follow the envelope's `next-skill`. If the returned state is absent or ambiguous, ask the user once instead of simulating the phase inside `b-orchestrate`.

### Step 2 - Route the plan phase

If the goal, constraints, acceptance criteria, non-goals, or intended behavior are unclear, emit a handoff envelope and invoke `/b-plan` (Clarification mode) via the Skill tool; resume only after the returned spec is concrete enough to plan. If external feasibility blocks the spec, invoke `/b-research` via the Skill tool and resume only after the returned evidence is sufficient or the blocker is reported.

For non-trivial work, sequencing, risk, public contracts, multi-file edits, or any workflow that needs durable coordination, invoke `/b-plan` via the Skill tool. Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/03-definitions.md` before applying the small-direct threshold. For a small direct workflow, invoke `/b-implement` via the Skill tool with the current source of truth, expected scope, and verification need; do not write an execution outline inside `b-orchestrate`.

Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/02-source-of-truth.md` before treating a saved or chat plan as approved. Do not invoke `/b-implement` from an unapproved non-trivial plan unless the user explicitly delegated that exact approval after seeing the plan.

### Step 3 - Route implementation and verification

Invoke `/b-implement` via the Skill tool for approved build steps. If its returned status block reports a runtime root-cause problem, invoke `/b-debug`. If the needed change is a concrete behavior-preserving rename, extract, move, inline, simplify, or delete, invoke `/b-refactor`.

After each build phase, require the phase skill's verification result before continuing. If verification fails because the plan is wrong, invoke `/b-plan` instead of widening implementation scope silently.

### Step 4 - Route test coverage work

Invoke `/b-test` via the Skill tool when changed behavior needs non-browser unit, integration, or contract coverage, when the user requested tests, or when review confidence depends on tests. Invoke `/b-browser` via the Skill tool when browser, DOM-rendered, visual, screenshot, browser-session, live UI, or e2e evidence is required. Skip this phase when the change is docs-only or tests are explicitly skipped; record any accepted browser follow-up instead of treating it as covered.

If `/b-test` returns a likely product behavior failure, invoke `/b-debug` before changing assertions, snapshots, or fixtures.

### Step 5 - Route review and fix findings

Invoke `/b-review` via the Skill tool against the current diff with the spec or approved plan as baseline. Its findings decide the next invocation:

- Implementation gap -> `/b-implement`.
- Runtime behavior failure -> `/b-debug`.
- Test-only gap or harness failure -> `/b-test`.
- Browser/DOM/visual/e2e evidence gap -> `/b-browser`.
- Concrete behavior-preserving transform, including simplify -> `/b-refactor`.
- New product decision or broad redesign -> `/b-plan` (Clarification mode).

Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/07-execution.md` before applying the review-fix loop or stopping on repeated failures. Re-invoke `/b-review` after each coherent fix set until it returns **READY FOR PR**, returns **READY WITH FOLLOW-UPS** accepted by the user, or reports a blocker.

### Step 6 - Close the workflow

Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/09-output.md` before reporting non-trivial workflow status or handing off unresolved work. Report the final review verdict, verification run, skipped checks, blockers, and remaining follow-ups. Do not claim **READY FOR PR** when the review had no baseline, required verification was skipped, or browser/DOM/e2e evidence remains relevant but absent.

## Output format

```text
Goal: <workflow-goal>
Phase: <current-phase or "closed">
Verification: <result or "n/a">
Verdict: <READY FOR PR | READY WITH FOLLOW-UPS | BLOCKED | IN PROGRESS>
Blockers: <list or "none">
Next: <next-phase invocation or "stop">
```


## Rules

- Orchestrate phases; do not bypass phase-skill rules or required read gates.
- Do not plan, implement, test, debug, refactor, research, or review inside `b-orchestrate`; invoke the owning phase skill via the Skill tool and resume from its returned status block.
- Do not auto-approve a plan the user has not seen.
- Keep review fixes scoped to findings or approved follow-up decisions.
- Do not add browser, DOM-rendered, visual, or e2e test tooling as part of the optional test phase.
- Do not treat browser, DOM, visual, or e2e checks as covered without **b-browser**-verified supplied/CI evidence, existing-tool evidence, approved live-browser evidence, or an accepted follow-up.
- Emit the handoff envelope as audit trail before each Skill-tool invocation; on `blocked` or `needs-input` returns, surface to the user instead of simulating phase work.

---
name: b-orchestrate
description: >
  End-to-end PR readiness orchestration. ALWAYS invoke when the user asks for
  one workflow that spans spec, plan, implementation, optional tests, review,
  and review-fix loops until ready for PR. Coordinates phase skills and stops
  at approval, blocker, or readiness. Unlike b-implement, b-orchestrate owns
  sequencing across multiple skills rather than changing code itself.
compatibility: opencode
metadata:
  suite: b-nexus
---

# b-orchestrate

$ARGUMENTS

Coordinate a complete PR-readiness workflow across the phase skills. The phase owner still does the actual spec, plan, implementation, test, debug, refactor, or review work.

If `$ARGUMENTS` is present, treat it as the workflow goal plus any explicit constraints such as skipped tests, required verification, or a known plan path.

## When to use

- The user asks for one end-to-end workflow from unclear request through PR readiness.
- The work needs spec, plan, build, optional tests, review, and review-fix sequencing.
- The user wants review findings fixed and re-reviewed until ready for PR or blocked.

## When NOT to use

- The user asks for only one phase -> use that phase skill directly.
- The request is a simple scoped edit with no workflow loop -> use **b-implement**.
- The user asks only for a code review or audit -> use **b-review** or **b-audit**.
- The user asks only to diagnose a runtime bug -> use **b-debug**.
- The user asks only for a named behavior-preserving transform -> use **b-refactor**.

## Tools required

- Native tools - inspect status, diffs, docs, and verification commands.
- Phase skills - **b-spec**, **b-plan**, **b-implement**, **b-test**, **b-review**, plus **b-debug**, **b-refactor**, and **b-research** when a phase routes there.
- `serena-symbol-toolkit` *(optional, through the active phase skill when symbol work matters)*
- `gitnexus-radar` *(optional, through the active phase skill for graph-shaped risk)*

If required tools are unavailable, read `references/b-nexus/runtime-contract.md` §4 before applying fallbacks. Graceful degradation: possible when native evidence and phase-skill handoffs can still prove progress; stop rather than simulating a phase whose required evidence is unavailable.

## Steps

### Step 1 - Start the workflow

Run `git status --short`, name the source of truth, and define success as a **b-review** verdict of **READY FOR PR** with required verification complete. If the user explicitly accepts skipped checks or follow-ups, success may be **READY WITH FOLLOW-UPS** instead.

Read `references/b-nexus/runtime-contract.md` §1 before routing across phase skills. Keep exactly one phase owner active at a time; every phase transition is a stop condition plus handoff, not parallel execution.

### Step 2 - Lock the spec

If the goal, constraints, acceptance criteria, non-goals, or intended behavior are unclear, hand off to **b-spec** and resume only after the spec output is concrete enough to plan. If the request is already clear, record the compact spec in chat and continue.

If external feasibility blocks the spec, hand off to **b-research** and resume only after the evidence is sufficient or the blocker is reported.

### Step 3 - Plan before build

Use **b-plan** for non-trivial work, sequencing, risk, public contracts, multi-file edits, or any workflow that needs durable coordination. Read `references/b-nexus/runtime-contract.md` §3 before applying the small-direct threshold. For a small direct workflow, record a short execution outline with scope, expected touch points, and verification, then continue from the user's request as the source of truth.

Read `references/b-nexus/runtime-contract.md` §2 before treating a saved or chat plan as approved. Do not implement from an unapproved non-trivial plan unless the user explicitly delegated that exact approval after seeing the plan.

### Step 4 - Implement and verify the plan

Hand off approved build steps to **b-implement**. If a step becomes a runtime root-cause problem, route that phase to **b-debug**. If the needed change is a concrete behavior-preserving rename, extract, move, inline, or delete, route that phase to **b-refactor**.

After each build phase, require the phase skill's verification result before continuing. If verification fails because the plan is wrong, return to **b-plan** instead of widening implementation scope silently.

### Step 5 - Add or assess tests

Use **b-test** when changed behavior needs non-browser unit, integration, or contract coverage, when the user requested tests, or when review confidence depends on tests. Skip this phase when the change is docs-only, tests are explicitly skipped, or only browser/DOM/e2e tooling would satisfy the request.

If **b-test** finds likely product behavior failure, route to **b-debug** before changing assertions, snapshots, or fixtures.

### Step 6 - Review and fix findings

Run **b-review** against the current diff with the spec or approved plan as baseline. Findings decide the next phase:

- Implementation gap -> **b-implement**.
- Runtime behavior failure -> **b-debug**.
- Test-only gap or harness failure -> **b-test**.
- Concrete behavior-preserving transform -> **b-refactor**.
- New product decision or broad redesign -> **b-spec** or **b-plan**.

Read `references/b-nexus/runtime-contract.md` §7 before applying the review-fix loop or stopping on repeated failures. Re-review after each coherent fix set until **b-review** returns **READY FOR PR**, returns **READY WITH FOLLOW-UPS** accepted by the user, or reports a blocker.

### Step 7 - Close the workflow

Read `references/b-nexus/runtime-contract.md` §9 before reporting non-trivial workflow status or handing off unresolved work. Report the final review verdict, verification run, skipped checks, blockers, and remaining follow-ups. Do not claim **READY FOR PR** when the review had no baseline or required verification was skipped.

## Output format

```text
Workflow goal -> Phase state -> Changes/verification -> Review verdict -> Blockers/follow-ups -> Next
```

Read `references/b-nexus/runtime-contract.md` §9 before closing a non-trivial orchestration with status or handoff schemas.

## Rules

- Orchestrate phases; do not bypass phase-skill rules or required read gates.
- Do not auto-approve a plan the user has not seen.
- Preserve unrelated worktree changes and stop on direct conflicts.
- Keep review fixes scoped to findings or approved follow-up decisions.
- Do not add browser, DOM-rendered, visual, or e2e test tooling as part of the optional test phase.
- Do not commit unless explicitly asked.

---
name: b-ship
description: >
  Commit, push, and open a pull request after the suite reaches READY FOR PR.
  Invoked by the user or b-orchestrate when a reviewed diff is ready to ship.
  Safety-gates each git action (commit, push, PR creation); never force-pushes.
  Stops after the PR URL is printed; post-PR automation is out of scope.
argument-hint: "[--draft] [--title=<title>] [--base=<branch>]"
---

# b-ship

$ARGUMENTS

Commit the reviewed diff, push, and open a pull request. Each destructive git action requires confirmation unless it was already approved in the current session.

Flags: `--draft` (open as draft PR), `--title=<title>` (skip interactive prompt), `--base=<branch>` (target branch, default: main).

## When to use

- The user asks to commit, push, open a PR, or ship after a review verdict of `READY FOR PR` or `READY WITH FOLLOW-UPS`.
- `b-orchestrate` closes a workflow with `Next: /b-ship`.

## When NOT to use

- The diff is not reviewed -> use **b-review** first.
- The user asks only to stage files or inspect the diff -> use `bash` directly.
- The task needs post-PR automation (deploy, tag, release) -> out of scope; address separately.
- Merge, rebase, or branch management -> handle with direct `git` commands after user confirms.

## Tools required

- `bash` - git and gh CLI for all actions.

## Steps

### Step 1 - Confirm the diff and branch

Run `git status --short` and `git diff --staged`. Report changed files, branch, and any untracked staged items. If the tree is dirty with unstaged changes that were not expected, stop and ask whether to stage them.

Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/06-safety.md` before any commit or push action.

### Step 2 - Commit

Ask for a commit message unless `--title` was provided or the user already gave one. Confirm:

```text
[approval] git commit -m "<message>"
Effect: creates a new commit on <branch> with <N> changed files.
Proceed? (y/n)
```

Never amend an existing commit unless the user explicitly asks. Never use `--no-verify` unless the user explicitly asks.

### Step 3 - Push

Check whether the branch has an upstream with `git rev-parse --abbrev-ref @{u}` and whether the remote is ahead with `git status -sb`. If the remote is ahead, stop and ask the user to resolve the divergence before pushing.

Confirm:

```text
[approval] git push origin <branch>
Effect: pushes <N> new commits to remote <branch>.
Proceed? (y/n)
```

Never push with `--force` or `--force-with-lease` unless the user explicitly asks.

### Step 4 - Open PR

Check that `gh` is available (`gh auth status`). If not, print the push URL and manual PR creation command, then stop.

Draft the PR title from the commit message or `--title`. Draft the body from the diff context (summary + test plan stub). Confirm before creating:

```text
[approval] gh pr create --title "<title>" --base <base>
Effect: opens a new PR on <repo>. Output: PR URL.
Proceed? (y/n)
```

Pass `--draft` if requested. After creation, print the PR URL.

## Output format

```text
Branch -> Staged files -> Commit -> Push -> PR URL
```

## Rules

- Ask before every destructive git action unless explicitly pre-approved.
- Never force-push, amend published commits, or skip hooks without explicit user instruction.
- Stop after printing the PR URL. Do not continue to merge, deploy, or tag.
- If any step fails, surface the error and stop; do not silently retry.
- Read `${CLAUDE_SKILL_DIR}/references/b-agentic/contract/06-safety.md` at Step 1 before any git mutation.

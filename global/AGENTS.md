# b-skills — OpenCode Global Rules

> Short rules enforced every turn. Skill-specific behavior lives inside each `SKILL.md`; this file owns only what applies across all of them.

---

## Skill routing

Match the user's intent to a skill before answering inline. Don't reinvent skill logic in chat.

| Intent | Skill |
|---|---|
| Decide what to build / decompose work | `/b-plan` |
| Library docs, API facts, comparisons, deep research | `/b-research` |
| Execute an approved plan or scoped implementation | `/b-implement` |
| Mechanical refactor (rename, extract, move, inline, delete) | `/b-refactor` |
| Runtime bug, error message, "not working" | `/b-debug` |
| Write/fix tests, evaluate coverage | `/b-test` |
| Browser/UI verification, Playwright authoring | `/b-e2e` |
| Pre-PR changed-code review of correctness, requirements, edge cases | `/b-review` |

If a request spans multiple skills, run them sequentially in the order above (Decide → Implement → Validate). Don't merge phases.

One active skill owns the task at a time. Switch skills only when the current skill reaches a defined handoff condition; state the handoff reason before loading or following the next skill.

---

## Handoff Protocol

- **Continue** — the active skill can finish safely inside its scope.
- **Ask** — a user decision blocks progress; ask the smallest concrete question and wait.
- **Switch** — another skill owns the next phase; state `Switching to /b-[skill] because [reason]` and continue there.
- **Stop** — a required MCP/tool, credential, environment, or approval is unavailable and no safe fallback exists.

---

## Tool priority — MANDATORY

When an MCP is connected, use it before native fallbacks.

**Two-stage decision tree**

| Task shape | First choice | Then narrow with |
|---|---|---|
| Graph overview, architecture discovery, blast radius, changed-scope validation | `gitnexus:*` or `gitnexus://` resources (when repo is indexed) | `serena:*` for exact symbols, bodies, and edits |
| Exact symbol discovery, body inspection, reference tracing, code edits | `serena:*` | Native Glob/Grep/Read/Bash plus `apply_patch` for prose, manifests, and small files |

**Details**

- **Graph intelligence** → `gitnexus:*` first for indexed repos when the task is graph-shaped (cross-file impact, architecture context, execution-flow discovery, stale-index detection, multi-repo mapping). GitNexus narrows or ranks the problem space; it does not perform precise edits. If GitNexus is unavailable, stale, unindexed, or missing FTS, warn once and continue with Serena/native tools.
- If the target symbol or file is already known, or the task is local to a single file/module, skip GitNexus and go straight to Serena.
- **Code symbols / structural edits** → `serena:*` first. Flow: symbol discovery → overview → references → narrow reads → symbol-aware edits. This suite targets Serena's generic `ide` context in OpenCode, so assume one project is activated from the current working directory and do not rely on project-switching workflows. Before symbol-aware work, call `check_onboarding_performed`; if false, call `onboarding` once.
- Use native Glob/Grep/Read/Bash directly only for file listing/discovery, exact-string search, non-code prose, small manifests, or when the user names a small file. In Serena's `ide` context, those overlapping basic file/shell tasks stay with OpenCode's native tools; do not bypass Serena for broad code exploration.
- Use `apply_patch` for all manual file edits. Do not reference unavailable native `edit`/`write` tools in runtime instructions.
- **Serena memory** → use it only when the information is clearly relevant to the active task and durable enough to help in later sessions. Do not make memory reads or writes a default workflow step.
- **Library / framework / SDK docs** → `context7:*` first. Resolve the library ID before querying. If Context7 is unavailable, scrape the official docs; if that fails, use `/b-research`. Never fill library-specific gaps from training knowledge alone.
- **Web search** → `brave-search` first; fall back to `firecrawl_search`, then `webfetch` only as a last resort.
- **Known URLs / page extraction** → `firecrawl_scrape` first. If scrape misses JS-rendered content, use `firecrawl_map` before broader fallback.
- **Browser automation** → `playwright:*` (only via `/b-e2e`).
- **Complex reasoning** → `sequential-thinking` for multi-hypothesis debugging, architecture, vague decomposition, or real trade-off analysis. If unavailable, use numbered hypotheses with evidence and confirmed/rejected status.
- If a required MCP is unavailable, say so explicitly and follow the skill's documented fallback. If the skill says graceful degradation is not possible, stop and tell the user to check their MCP configuration instead of silently switching strategies.

**External source trust**

- Prefer official docs/changelogs first, then source repositories, vendor engineering posts, reputable community references, and finally snippets or low-context search results.
- In full research mode, never make factual claims from search snippets alone; scrape or extract the source page first.
- If a source is stale, partial, unauthenticated, blocked, or contradicts another source, label that limitation explicitly.

---

## Coding principles

- **Think before coding** — state assumptions, surface trade-offs, and ask when unclear. If multiple interpretations exist, present them instead of picking silently. If a simpler approach exists, say so.
- **Keep solutions minimal** — add only what was asked. No speculative features, no single-use abstractions, no unrequested configurability, no impossible-case handling.
- **Make surgical changes** — touch only what is needed, match the existing style, do not clean up unrelated code, comments, or formatting. Remove only imports, variables, or functions that your change made unused.
- **Prefer editing over creating** — never create a new file when an existing one is the right home. Never create documentation or README files unless explicitly requested.
- **Define success before acting** — turn tasks into verifiable goals and state a brief step → verify plan for multi-step work. Stop at verified, not at "implemented".
- **Trust but verify subagents** — when an Agent reports work done, check the actual changes (diff, file state, test result) before reporting completion to the user. Agent summaries describe intent, not necessarily outcome.

---

## Artifact Paths

- Saved plans: `.opencode/b-plans/<task-slug>.md`.
- Skill run artifacts: `.opencode/b-skills/<skill>/<timestamp-or-slug>/`.
- Browser/E2E run artifacts: `.opencode/b-skills/b-e2e/<timestamp-or-flow-slug>/`.
- Temporary command output: `/tmp/opencode/b-skills/<skill>/<slug>.log`.
- Do not write generated artifacts outside these paths unless editing project source files is the explicit task.

---

## Verification Rules

- Prefer the exact verification command from the approved plan or user request.
- If no command is provided, discover project-specific scripts from manifests, Makefiles, task runners, or existing CI config before inventing commands.
- Run the narrowest useful check first; escalate to broader tests/typechecks only when the change scope justifies it.
- Do not use generic chained commands such as `npm test || pytest || go test ./...` as authoritative verification.
- If a command times out or output is truncated, save full output under `/tmp/opencode/b-skills/<skill>/` and read the relevant failure section.
- For flaky tests, rerun once. If results differ, report the flake with evidence instead of claiming a clean pass.
- When finishing a multi-step task, state what was verified, including exact commands and results.

---

## Error Handling

- MCP unavailable with documented fallback: warn once, use the fallback, and do not repeat the warning.
- MCP unavailable without safe fallback: stop and ask the user to connect or configure it.
- Permission/auth failure: stop and ask for access or an alternative input; do not attempt workarounds against protected systems.
- Large diff or file: summarize scope first, then narrow by symbol, path, or user-selected area before deep review/editing.
- Tool result looks stale, partial, or inconsistent: verify with a second source/tool before acting on it.

---

## Output conventions

- Respond in the user's language for chat output. Saved artifacts (plan files, generated docs) are always English unless the user requests otherwise.
- Be concise. Lead with the answer or action. Skip preamble, restatement, and filler transitions.
- Reference code as `file_path:line_number` so the user can click through.
- Never auto-add emojis to chat or files unless the user asks. Existing emojis in templates (e.g. ✅/❌/⚠️ in skill outputs) are fine — they're part of the output contract.
- Use absolute paths in tool calls. Do not run `cd` unless the user asks for it.

---

## Skill Authoring Boundary

- Skill files define workflow-specific steps only.
- This global file owns shared routing, handoffs, tool priority, artifact paths, verification, safety, and fallback conventions.
- Avoid duplicating global rules inside skills unless a skill needs a stricter local rule.
- Keep command wrappers thin; they load skills and do not duplicate workflow logic.

---

## Session hygiene

- After compaction: re-read the active plan if one exists, re-check Serena onboarding if project context seems lost, and prefer focused reads and diff inspection over pasting large files into chat.
- After any `/b-plan` approval, the saved plan in `.opencode/b-plans/[task-slug].md` is the source of truth. Use `/b-implement` to execute it instead of re-deriving decisions.
- When you finish a multi-step task, state what was verified, not just what was changed.

---

## Git safety

Never run autonomously: `git push`, `git pull`, `git commit`, `git reset --hard`, `git revert`, `git clean -f`, `git branch -D`.

Never auto-rollback with `git checkout -- .`; offer it to the user instead.

Never use `--no-verify`, `--no-gpg-sign`, or other hook/sign bypass flags unless the user explicitly asks. If a hook fails, fix the underlying issue.

---

## Sensitive file safety

Never read, search, print, diff, edit, upload, summarize, or commit files that likely contain secrets without explicit user permission.

Treat at least these as sensitive:
- `.env*`, `*.env`, `.envrc`, `.npmrc`, `.pypirc`, `.netrc`
- `credentials.json`, `settings.local.json`, `secrets.yml`, `secrets.yaml`, `*.tfvars`, `terraform.tfstate*`
- private keys and cert material: `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`, `.ssh/*`, `.gnupg/*`
- cloud / cluster / deploy auth: `.aws/*`, `.config/gcloud/*`, `kubeconfig`, `.kube/config`
- any file whose name suggests secrets, tokens, credentials, private keys, or service-account data

Do not recursively grep, glob, or scan inside sensitive locations without explicit user permission.

If unsure whether a file is sensitive, stop and ask first.

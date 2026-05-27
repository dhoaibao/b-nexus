# b-review — reference

Security checklist for `b-review` when changed code touches auth, untrusted input, sensitive data, file uploads, webhooks, or external integrations.

## Boundary checks

- Validate input at the first boundary that accepts it.
- Reject or normalize unexpected fields before business logic runs.
- Treat data from APIs, config, logs, and webhooks as untrusted until checked.

## Auth and authorization

- Confirm every protected path checks both authentication and authorization.
- Check owner/resource scoping, not just role presence.
- Verify new admin or elevated actions fail closed.

## Injection and encoding

- Confirm queries are parameterized.
- Confirm shell, template, and HTML sinks do not receive unsanitized input.
- Confirm output encoding is preserved across new rendering paths.

## Sensitive data

- Remove secrets, tokens, and internal details from logs and responses.
- Check that new responses do not expose internal fields by accident.
- Verify session and auth state stay in approved storage.

## Resource and abuse controls

- Check rate limits, retry bounds, upload size limits, pagination, or similar resource controls.
- Look for regex or parsing paths that can go pathological on hostile input.
- Check idempotency and replay safety where writes can be repeated.

## Dependency and config hygiene

- Question new dependencies on sensitive paths.
- Confirm security-relevant config changes fail closed when missing or mis-set.
- Check that error handling does not expose stack traces or implementation details.

## Audit-suite checklists ( `--audit-suite` )

Use these checklists when `b-review` is invoked with `--audit-suite` for a b-agentic suite self-audit. Pick the smallest matching surface and sample highest-risk paths first.

### Sampling Strategy

- Name the audited surface and baseline before inspecting details.
- Sample entry points, generated consumers, install/runtime outputs, and docs that define user-facing behavior.
- Prefer source files over generated files unless the generated output is the public contract.
- For no-findings audits, list checked-and-clean samples plus skipped areas and residual risk.

### Surface Checklists

#### Installer Or Update Path

- Check install, update, dry-run, uninstall, idempotency, backup/restore, and partial-failure behavior.
- Verify managed-file markers, pruning rules, and user-owned file preservation.
- Confirm paths match README and runtime contract paths.

#### Runtime Contract Or Governance

- Check routing precedence, source-of-truth order, safety gates, approval lifetime, artifact paths, status blocks, and handoff envelopes.
- Look for duplicated global rules inside skill files.
- Confirm examples and schemas use the current contract version placeholder or concrete version as appropriate.

#### Validator Or Tool Boundary

- Check that validator rules enforce documented invariants without forcing duplicated runtime policy.
- Confirm failures are actionable and tied to maintained files.
- Verify generated skill frontmatter, docs coverage, installed support files, and source-to-generated sync are checked.

#### Route, Tool, Or Public Contract Boundary

- Identify consumers before judging a route/tool/schema/CLI change safe.
- Check request/response shapes, auth or permission gates, error behavior, and documented fields or flags.
- Treat examples, docs, generated clients, and tests as consumers when they shape user expectations.

#### Dependency Or Lockfile Surface

- Check why the dependency changed, whether lockfile updates were approved, and whether install/runtime compatibility is documented.
- Verify security, license, engine, and package-manager implications when they are material.

#### Generated Artifact

- Find the generator source or command before trusting the generated output.
- If generated output was edited manually, label evidence as partial and name regeneration follow-up.
- Check snapshots, goldens, docs, and installed outputs against their source inputs.

#### Security-Sensitive Rule

- Check auth/authz, secrets, private data, destructive commands, external writes, and public-web privacy gates.
- Require direct evidence for any safe/ready claim; otherwise lower confidence or block.

#### b-agentic Suite Audit

- Check `skills/registry.yaml`, `skills/*/prompt.md`, and generated `skills/*/SKILL.md` for trigger boundary, stop conditions, task-specific workflow, and global-rule duplication.
- Check that generated `skills/*/SKILL.md` files and `runtimes/opencode/commands/*.md` wrappers still expose the same `/b-*` skill surface from shared metadata.
- Check `references/contract/kernel.template.md`, `references/contract/`, and `runtimes/*/kernel.md` for conflicting schemas, paths, tool priorities, and safety gates.
- Cross-check `README.md`, `skills/registry.yaml`, `skills/*/prompt.md`, generated `skills/*/SKILL.md`, `runtimes/*/kernel.md`, and `references/contract/` only where they define overlapping runtime-facing behavior.
- Run `scripts/validate-skills.sh` unless explicitly skipped.

# Claude Code Runtime Layout

This directory contains Claude Code runtime templates that are copied or referenced by `install.sh`.

## Supported distribution mode

The first Claude-native release supports a personal-global install only:

- Kernel memory: `~/.claude/CLAUDE.md`
- Skills: `~/.claude/skills/<skill-name>/SKILL.md`
- Skill-local shared references: `~/.claude/skills/<skill-name>/references/b-agentic/*.md`
- Suite metadata, backups, and source snapshots: `~/.claude/b-agentic/`
- Shared reference snapshot: `~/.claude/b-agentic/references/*.md`
- Recommended settings template: `~/.claude/b-agentic/templates/settings.recommended.json`
- MCP profile templates: `~/.claude/b-agentic/templates/mcp.*.template.json`
- Sensitive artifacts: `~/.claude/b-agentic/<skill>/<run-id>/` or `/tmp/claude-code/b-agentic/<skill>/<run-id>/`
- Temporary logs: `/tmp/claude-code/b-agentic/<skill>/<slug>.log`

Project-local `.claude/` install, plugin packaging, hooks, and dynamic context injection are non-goals for the first migrated release. Add them only after validator and smoke coverage prove global parity.

## Invocation policy

Claude Code exposes each skill directory as `/b-*`. Mutating or coordinating skills are manual-only through `disable-model-invocation: true`. Read-only discovery and review skills may remain model-invocable when their descriptions are tight and do not grant tools.

## Safety policy

The installer never overwrites an existing `~/.claude/CLAUDE.md` without `--replace-memory`. Settings and MCP templates are copied as inert templates by default. Users may apply them with `--install-settings`, `--replace-settings`, `--install-project-mcp`, `--replace-project-mcp`, or `--mcp-profile <name>`; replace modes create timestamped backups first.

## MCP Profiles

MCP profiles are project `.mcp.json` templates. They are not installed into a project unless the user passes an explicit project MCP flag. Keep profiles small so MCP is a lazy capability rather than a default context source.

| Profile | Template | Use |
|---|---|---|
| `safe` | `mcp.safe.template.json` | Serena semantic code navigation/editing for local source work. |
| `research` | `mcp.research.template.json` | Context7 docs plus Brave Search and Firecrawl for external evidence. |
| `browser` | `mcp.browser.template.json` | Playwright MCP for browser/DOM/visual/e2e evidence with isolated state. |
| `architecture` | `mcp.architecture.template.json` | Serena plus optional GitNexus graph radar for architecture and blast-radius work. |

`mcp.project.template.json` is a full convenience example for the original non-GitNexus MCP surfaces in one project config. Prefer the smaller profiles for ordinary setup; use `architecture` when you intentionally want GitNexus radar.

Profile safety rules:
- Use environment-variable placeholders such as `${BRAVE_API_KEY}` and `${FIRECRAWL_API_KEY}`; never commit real API keys.
- Keep Playwright configured with `--isolated` unless a user explicitly opts into persistent browser state outside the tracked worktree.
- Do not include Claude hooks, generated root guidance, indexes, memories, or setup commands in MCP templates.
- Treat GitNexus as optional power-user radar. Users must run `gitnexus analyze` or `gitnexus setup` themselves if they want indexing, generated skills, hooks, or global MCP config.
- Context7 may also offer CLI + Skills setup through `npx ctx7 setup`; b-agentic profiles use the MCP HTTP endpoint to avoid writing user config during install.

Apply a profile intentionally:

```bash
install.sh --install-project-mcp --mcp-profile safe
install.sh --replace-project-mcp --mcp-profile research
```

The default profile for `--install-project-mcp` remains `project` for compatibility with the original full template.

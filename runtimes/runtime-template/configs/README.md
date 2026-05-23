# <Runtime> Runtime Layout

Use this file as the adapter-owned runtime layout doc for `runtimes/<name>/configs/`.

Document:

- the installed memory/kernel path
- where skills, references, templates, manifests, and backups land
- whether the runtime needs command wrappers or compatibility outputs
- the MCP/config schema family and merge semantics
- any adapter-specific constraints that must not leak into shared skills or shared contract files

Keep runtime-specific paths and caveats here, not in shared skill prompts or shared contract prose.

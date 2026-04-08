# Claude Code (dotfiles package)

[Claude Code](https://code.claude.com/) config stowed to `~/.claude/`.

## Settings: shared vs local

Claude Code uses a single user-level file: `~/.claude/settings.json`. To keep secrets and machine-specific values out of git, this package splits config into:

| File | Committed? | Use for |
|------|------------|--------|
| `.claude/settings.json` | Yes | Safe defaults: permissions, plugins, marketplaces, status line, flags |
| `.claude/settings.local.json` | No (gitignored) | Env vars (AWS profile, Bedrock ARNs), API keys, machine-specific overrides |

### Setup after stow

1. Copy the example and edit with your values:
   ```bash
   cp ~/.claude/settings.local.json.example ~/.claude/settings.local.json
   # edit ~/.claude/settings.local.json (env, model ARNs, etc.)
   ```

2. **Merging with `settings.json`**: Official docs define `settings.local.json` for **project** scope (inside a repo’s `.claude/`), not for the **user** directory `~/.claude/`. So:
   - If your Claude Code version merges `~/.claude/settings.local.json` with `~/.claude/settings.json`, you’re done.
   - If it does not, merge manually: keep shared bits in `settings.json` (repo) and put all env/secrets in `settings.local.json`, then combine them into a single `~/.claude/settings.json` and avoid committing that file (e.g. by not stowing this package’s `settings.json`, or by using a post-stow script that merges and writes `~/.claude/settings.json`).

### Reference

- [Claude Code settings (Anthropic)](https://docs.anthropic.com/en/docs/claude-code/settings)
- Scopes: Managed → Command line → **Local** (`.claude/settings.local.json`) → **Project** (`.claude/settings.json`) → **User** (`~/.claude/settings.json`). Local overrides project; both can override user.

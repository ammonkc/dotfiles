# Obsidian Implementation Prompts for Tinycast

Search implementation prompts captured by `ammonkc/claude-fiyah`'s
`obsidian-capture` mod. Notes appear newest first by their `created` date
(MM/DD/YYYY or ISO), with filename date and filesystem creation time as fallbacks.
Editing or recapturing an old prompt does not change its position.

Type to filter by title, note filename, source file path, or prompt content.
Multiple search words must all match. Press Return to copy the selected note's
`## Prompt` content, including your edits and Markdown, without frontmatter or
plan-link metadata. The action menu also offers a preview and opens the note
in Obsidian. Notes are reloaded each time you open the command.

## Build and import

From the development checkout:

```sh
task dot:tinycast:prompts
```

In Tinycast Settings > Extensions, enable extensions and choose **Add from
folder**, then select the absolute `build` directory printed by the task.
After dotfiles deployment, run `dotfiles dot:tinycast:prompts` to build from
`~/.dotfiles`. Extension sources and build artifacts are excluded from Stow.

The optional **Obsidian Vault Path** preference accepts an absolute path or
`~/path`. By default, the extension reads Obsidian's macOS vault registry at
`~/Library/Application Support/obsidian/obsidian.json`, selects the first open
vault, or falls back to the first registered vault, matching the capture mod.
If the mod uses its `vault` option, set this preference to that vault's path.
Obsidian does not need to be running to search or copy prompts.

The extension reads `implement-plan-*.md` directly from
`Projects/Engineering/Prompts`. Empty notes and notes without a `## Prompt`
section are omitted. It never modifies notes. A missing prompts folder shows
an empty list; an inaccessible vault or note reports a loading error.

## Validation

```sh
npm ci
npm run lint
npm test
npm run build
```

Tests use temporary synthetic vaults and never read your real notes.

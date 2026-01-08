# IDL Docker - Raycast Extension

Manage IDL Docker containers across git worktrees.

## Features

- **Dynamic worktree discovery** - Automatically lists all worktrees
- **Start/Stop commands** - Quick container management
- **Configurable** - Set base directory and default worktree in preferences

## Setup

1. Add an extension icon (required):
   - Add a 512x512 PNG icon as `assets/extension-icon.png`
   - You can use any Docker-related icon or create one

2. Install dependencies:
   ```bash
   cd packages/raycast/extensions/idl-docker
   npm install
   ```

3. Start development mode:
   ```bash
   npm run dev
   ```

4. Configure preferences in Raycast:
   - **Worktrees Directory**: Base path containing worktrees (default: `~/Developer/code/indirect`)
   - **Default Worktree**: Worktree shown first in list (default: `main`)

## Commands

- **Start Containers** - Start Docker containers for a selected worktree
- **Stop Containers** - Stop Docker containers for a selected worktree

## Development

```bash
npm run dev      # Start development mode
npm run build    # Build extension
npm run lint     # Run linter
npm run fix-lint # Fix lint issues
```

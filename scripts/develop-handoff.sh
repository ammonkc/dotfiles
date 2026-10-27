#!/usr/bin/env bash
# Print a Markdown handoff for a local Git worktree. No network calls or writes.
set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

repo=${1:-.}
repo=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) || {
  printf 'Not inside a Git worktree: %s\n' "$repo" >&2
  exit 1
}
branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD || git -C "$repo" rev-parse --short HEAD)
head_commit=$(git -C "$repo" rev-parse HEAD)

base_ref=${HANDOFF_BASE:-}
if [[ -z "$base_ref" ]]; then
  base_ref=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
fi
if [[ -z "$base_ref" ]]; then
  for candidate in origin/main main origin/master master; do
    if git -C "$repo" rev-parse --verify "$candidate^{commit}" >/dev/null 2>&1; then
      base_ref=$candidate
      break
    fi
  done
fi
if [[ -n "$base_ref" ]]; then
  base_commit=$(git -C "$repo" merge-base HEAD "$base_ref") || {
    printf 'Could not find a merge base with %s\n' "$base_ref" >&2
    exit 1
  }
else
  base_ref='first commit'
  base_commit=$(git -C "$repo" rev-list --max-parents=0 HEAD | tail -n 1)
fi

printf '# Worktree handoff\n\n'
printf -- '- Worktree: `%s`\n' "$repo"
printf -- '- Branch: `%s`\n' "$branch"
printf -- '- HEAD: `%s`\n' "$head_commit"
printf -- '- Base: `%s` (`%s`)\n' "$base_ref" "$base_commit"
printf '\n## Summary\n\n%s\n' "${HANDOFF_SUMMARY:-Add a brief description of the task and current result.}"

printf '\n## Commits since base\n\n'
commits=$(git -C "$repo" log --format='%h %s' "$base_commit"..HEAD)
if [[ -n "$commits" ]]; then printf '%s\n' "$commits"; else printf 'None.\n'; fi

printf '\n## Changed files since base\n\n'
changes=$(git -C "$repo" diff --name-status "$base_commit" HEAD)
if [[ -n "$changes" ]]; then
  printf '```text\n%s\n```\n' "$changes"
else
  printf 'None committed.\n'
fi

printf '\n## Uncommitted work\n\n'
status=$(git -C "$repo" status --short --untracked-files=normal)
if [[ -n "$status" ]]; then
  printf '```text\n%s\n```\n' "$status"
else
  printf 'Clean worktree.\n'
fi

printf '\n## Checks run\n\n%s\n' "${HANDOFF_CHECKS:-Not recorded.}"
printf '\n## Next steps\n\n%s\n' "${HANDOFF_NEXT:-Add next steps before handing this to another agent.}"

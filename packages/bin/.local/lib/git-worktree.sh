#!/usr/bin/env bash
# Shared helpers for git-worktree-* scripts.
# Sourced by: git-worktree-setup, git-worktree-copy-ignored, git-worktree-copy-untracked
#
# Path resolution is editor-agnostic. Works with:
#   - explicit SOURCE/DEST args (CLI, hooks, CI)
#   - git CLI worktrees (run from the new worktree, or pass DEST)
#   - optional editor env hints when present (e.g. Zed create_worktree)

# Absolute, physical path for reliable comparisons
_gwt_abspath() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  elif [[ -e "$path" ]]; then
    local dir base
    dir="$(cd "$(dirname "$path")" && pwd -P)"
    base="$(basename "$path")"
    echo "$dir/$base"
  else
    echo "$path"
  fi
}

# Primary (main) worktree path for a repo containing START
_gwt_primary_worktree() {
  local start="${1:-.}"
  local primary
  primary="$(git -C "$start" worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }')"
  [[ -n "$primary" ]] || return 1
  _gwt_abspath "$primary"
}

# Optional editor-provided paths (never required)
_gwt_editor_main() {
  if [[ -n "${ZED_MAIN_GIT_WORKTREE:-}" && -d "$ZED_MAIN_GIT_WORKTREE" ]]; then
    _gwt_abspath "$ZED_MAIN_GIT_WORKTREE"
    return 0
  fi
  return 1
}

_gwt_editor_dest() {
  if [[ -n "${ZED_WORKTREE_ROOT:-}" && -d "$ZED_WORKTREE_ROOT" ]]; then
    _gwt_abspath "$ZED_WORKTREE_ROOT"
    return 0
  fi
  return 1
}

# Resolve SOURCE (primary) and DEST (new worktree).
# Usage: _gwt_resolve_paths [SOURCE] [DEST]
#   0 args → DEST = cwd (or editor hint); SOURCE = primary of that repo
#   1 arg  → DEST = arg; SOURCE = primary of that repo
#   2 args → SOURCE DEST
# Empty args are ignored (editors may expand missing vars to "").
# Sets: GWT_SRC GWT_DEST
_gwt_resolve_paths() {
  local src="" dest=""
  local -a args=()
  local a

  for a in "$@"; do
    [[ -n "$a" ]] && args+=("$a")
  done

  case ${#args[@]} in
    0)
      # Prefer git cwd; fall back to optional editor env (Zed create_worktree, etc.)
      if dest="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        dest="$(_gwt_abspath "$dest")"
      elif dest="$(_gwt_editor_dest)"; then
        :
      else
        echo "❌ Not inside a git worktree; pass DEST explicitly" >&2
        echo "   git-worktree-setup /path/to/new-worktree" >&2
        echo "   git-worktree-setup /path/to/main /path/to/new-worktree" >&2
        return 1
      fi

      if src="$(_gwt_primary_worktree "$dest")"; then
        :
      elif src="$(_gwt_editor_main)"; then
        :
      else
        echo "❌ Could not find primary worktree for $dest" >&2
        return 1
      fi
      ;;
    1)
      dest="$(_gwt_abspath "${args[0]}")"
      if [[ ! -d "$dest" ]]; then
        echo "❌ Destination not found: ${args[0]}" >&2
        return 1
      fi
      src="$(_gwt_primary_worktree "$dest")" || {
        echo "❌ Could not find primary worktree for $dest" >&2
        return 1
      }
      ;;
    *)
      src="$(_gwt_abspath "${args[0]}")"
      dest="$(_gwt_abspath "${args[1]}")"
      ;;
  esac

  if [[ -z "$src" || ! -d "$src" ]]; then
    echo "❌ Source worktree not found: ${src:-<empty>}" >&2
    return 1
  fi
  if [[ -z "$dest" || ! -d "$dest" ]]; then
    echo "❌ Destination worktree not found: ${dest:-<empty>}" >&2
    return 1
  fi
  if [[ "$src" == "$dest" ]]; then
    echo "❌ Source and destination are the same path: $src" >&2
    echo "   Run from the new worktree, or pass it as DEST:" >&2
    echo "   git-worktree-setup /path/to/new-worktree" >&2
    return 1
  fi
  if ! git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Source is not a git worktree: $src" >&2
    return 1
  fi
  if ! git -C "$dest" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Destination is not a git worktree: $dest" >&2
    return 1
  fi

  GWT_SRC="$src"
  GWT_DEST="$dest"
}

# Copy null-delimited relative paths from SRC to DEST via rsync (or cp fallback)
# Usage: _gwt_copy_paths SRC DEST DRY_RUN VERBOSE  (paths on stdin, NUL-separated)
_gwt_copy_paths() {
  local src="$1" dest="$2" dry_run="$3" verbose="$4"
  local -a paths=()

  mapfile -d '' -t paths

  if ((${#paths[@]} == 0)); then
    return 2  # signal: nothing to copy
  fi

  echo "📦 Copying ${#paths[@]} path(s): $src → $dest"

  if [[ "$dry_run" == true ]]; then
    printf '%s\n' "${paths[@]}"
    return 0
  fi

  local -a rsync_flags=(-a)
  if [[ "$verbose" == true ]]; then
    rsync_flags+=(--info=progress2 -v)
  fi

  if command -v rsync >/dev/null 2>&1; then
    printf '%s\0' "${paths[@]}" | rsync "${rsync_flags[@]}" --from0 --files-from=- "$src/" "$dest/"
  else
    local path
    for path in "${paths[@]}"; do
      mkdir -p "$dest/$(dirname "$path")"
      cp -a "$src/$path" "$dest/$path"
    done
  fi
}

import { getPreferenceValues } from "@raycast/api";
import { readdirSync, statSync } from "fs";
import { join } from "path";
import { homedir } from "os";

interface Preferences {
  baseDir: string;
  repoDir?: string;
  defaultWorktree: string;
  allegroDomain: string;
}

/**
 * Expand ~ to home directory
 */
function expandPath(path: string): string {
  if (path.startsWith("~")) {
    return join(homedir(), path.slice(1));
  }
  return path;
}

/**
 * Get the base directory for worktrees from preferences
 */
export function getBaseDir(): string {
  const { baseDir } = getPreferenceValues<Preferences>();
  return expandPath(baseDir);
}

export function getRepoDir(): string {
  const { repoDir } = getPreferenceValues<Preferences>();
  return expandPath(repoDir || "~/Developer/code/indirect");
}

/**
 * Get the default worktree from preferences
 */
export function getDefaultWorktree(): string {
  const { defaultWorktree } = getPreferenceValues<Preferences>();
  return defaultWorktree || "main";
}

/**
 * Get the Allegro domain from preferences
 */
export function getAllegroDomain(): string {
  const { allegroDomain } = getPreferenceValues<Preferences>();
  return allegroDomain || "indirect.test";
}

/**
 * List all available worktrees (directories in the base directory)
 */
export function listWorktrees(): string[] {
  const worktrees = new Set<string>();
  if (worktreeExists("main")) worktrees.add("main");
  try {
    for (const entry of readdirSync(getBaseDir(), { withFileTypes: true })) {
      if (
        entry.isDirectory() &&
        !entry.name.startsWith(".") &&
        entry.name !== "main"
      ) {
        worktrees.add(entry.name);
      }
    }
  } catch (error) {
    console.error("Failed to list worktrees:", error);
  }
  return [...worktrees].sort();
}

/**
 * Get the full path to a worktree
 */
export function getWorktreePath(worktree: string): string {
  return worktree === "main" ? getRepoDir() : join(getBaseDir(), worktree);
}

/**
 * Check if a worktree exists
 */
export function worktreeExists(worktree: string): boolean {
  try {
    const path = getWorktreePath(worktree);
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

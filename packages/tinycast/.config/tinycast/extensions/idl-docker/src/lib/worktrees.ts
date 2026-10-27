import { getPreferenceValues } from "@raycast/api";
import { readdirSync, statSync } from "fs";
import { join } from "path";
import { homedir } from "os";

interface Preferences {
  baseDir: string;
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
  const baseDir = getBaseDir();

  try {
    const entries = readdirSync(baseDir, { withFileTypes: true });
    return entries
      .filter((entry) => entry.isDirectory() && !entry.name.startsWith("."))
      .map((entry) => entry.name)
      .sort();
  } catch (error) {
    console.error("Failed to list worktrees:", error);
    return [];
  }
}

/**
 * Get the full path to a worktree
 */
export function getWorktreePath(worktree: string): string {
  return join(getBaseDir(), worktree);
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

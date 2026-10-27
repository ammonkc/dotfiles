import { homedir } from "os";
import { basename, join, relative, resolve } from "path";
import { readdir, realpath } from "fs/promises";

const SKIP_DIRS = new Set([
  ".git",
  ".cache",
  ".venv",
  "build",
  "dist",
  "node_modules",
  "target",
  "vendor",
]);

export function expandProjectsDir(projectsDir: string): string {
  if (projectsDir === "~") return homedir();
  if (projectsDir.startsWith("~/"))
    return resolve(homedir(), projectsDir.slice(2));
  return resolve(projectsDir);
}

export interface Project {
  path: string;
  title: string;
  subtitle: string;
}

export async function findRepositories(root: string): Promise<Project[]> {
  const rootReal = await realpath(root);
  const results: Project[] = [];

  async function visit(dir: string, depth: number): Promise<void> {
    if (depth > 6) return;
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }

    if (entries.some((entry) => entry.name === ".git")) {
      results.push({
        path: dir,
        title: basename(dir),
        subtitle: relative(rootReal, dir) || ".",
      });
      return;
    }

    for (const entry of entries) {
      if (
        !entry.isDirectory() ||
        entry.name.startsWith(".") ||
        SKIP_DIRS.has(entry.name)
      )
        continue;
      await visit(join(dir, entry.name), depth + 1);
    }
  }

  await visit(rootReal, 0);
  return results.sort((a, b) => a.subtitle.localeCompare(b.subtitle));
}

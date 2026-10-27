import { execFile } from "child_process";
import { promisify } from "util";
import { basename, join, relative, sep } from "path";
import { lstat, readdir, realpath, rm, stat } from "fs/promises";

const execFileAsync = promisify(execFile);
const SKIP_DIRS = new Set([".git", ".cache", ".venv", "target", "vendor"]);

export interface NodeModulesEntry {
  path: string;
  project: string;
  sizeBytes: number | null;
  packageModifiedAt: number | null;
  dev: number;
  ino: number;
}

export function formatBytes(bytes: number | null): string {
  if (bytes === null) return "Size unavailable";
  if (bytes < 1024 ** 2) return `${Math.round(bytes / 1024)} KB`;
  if (bytes < 1024 ** 3) return `${(bytes / 1024 ** 2).toFixed(1)} MB`;
  return `${(bytes / 1024 ** 3).toFixed(1)} GB`;
}

async function diskSize(path: string): Promise<number | null> {
  try {
    const { stdout } = await execFileAsync("du", ["-sk", path], {
      timeout: 30000,
    });
    const kib = Number.parseInt(stdout.split(/\s+/)[0], 10);
    return Number.isFinite(kib) ? kib * 1024 : null;
  } catch {
    return null;
  }
}

export async function findNodeModules(
  root: string,
): Promise<{ root: string; entries: NodeModulesEntry[] }> {
  const rootReal = await realpath(root);
  const found: NodeModulesEntry[] = [];

  async function visit(dir: string, depth: number): Promise<void> {
    if (depth > 8) return;
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const path = join(dir, entry.name);
      if (entry.name === "node_modules") {
        try {
          const directory = await lstat(path);
          const packageFile = await stat(join(dir, "package.json")).catch(
            () => null,
          );
          found.push({
            path,
            project: relative(rootReal, dir) || basename(dir),
            sizeBytes: null,
            packageModifiedAt: packageFile?.mtimeMs ?? null,
            dev: directory.dev,
            ino: directory.ino,
          });
        } catch {
          // Directory may have disappeared during the scan.
        }
      } else if (!entry.name.startsWith(".") && !SKIP_DIRS.has(entry.name)) {
        await visit(path, depth + 1);
      }
    }
  }

  await visit(rootReal, 0);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(4, found.length) }, async () => {
      while (next < found.length) {
        const entry = found[next++];
        entry.sizeBytes = await diskSize(entry.path);
      }
    }),
  );

  found.sort((a, b) => (b.sizeBytes ?? -1) - (a.sizeBytes ?? -1));
  return { root: rootReal, entries: found };
}

export async function deleteNodeModules(
  root: string,
  entry: NodeModulesEntry,
): Promise<void> {
  if (basename(entry.path) !== "node_modules")
    throw new Error("Invalid directory name");
  const rootReal = await realpath(root);
  const pathReal = await realpath(entry.path);
  if (!pathReal.startsWith(`${rootReal}${sep}`))
    throw new Error("Directory is outside the projects root");

  const current = await lstat(entry.path);
  if (
    !current.isDirectory() ||
    current.isSymbolicLink() ||
    current.dev !== entry.dev ||
    current.ino !== entry.ino
  ) {
    throw new Error(
      "Directory changed since the scan; refresh before deleting",
    );
  }

  await rm(entry.path, { recursive: true, force: false });
}

import { readFile, readdir, stat } from "fs/promises";
import { homedir } from "os";
import { isAbsolute, join } from "path";

export const PROMPTS_FOLDER = "Projects/Engineering/Prompts";

export interface Prompt {
  path: string;
  title: string;
  text: string;
  sourceFile: string;
  created: number;
}

function scalar(value: string): string {
  return value.trim().replace(/^(["'])(.*)\1$/, "$2");
}

function creationDate(value: string): number {
  const local = /^(\d{2})[/-](\d{2})[/-](\d{4})$/.exec(value);
  const iso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (local || iso) {
    const [year, month, day] = local
      ? [Number(local[3]), Number(local[1]), Number(local[2])]
      : [Number(iso![1]), Number(iso![2]), Number(iso![3])];
    const date = new Date(year, month - 1, day);
    return date.getFullYear() === year &&
      date.getMonth() === month - 1 &&
      date.getDate() === day
      ? date.getTime()
      : NaN;
  }
  return Date.parse(value);
}

export function parsePrompt(
  markdown: string,
  path: string,
  fallbackDate: number,
): Prompt | undefined {
  const normalized = markdown.replace(/^\uFEFF/, "").replace(/\r\n/g, "\n");
  const frontmatter = /^---\n([\s\S]*?)\n---(?:\n|$)/.exec(normalized);
  const body = frontmatter
    ? normalized.slice(frontmatter[0].length)
    : normalized;
  const fields: Record<string, string> = {};
  for (const line of (frontmatter?.[1] || "").split("\n")) {
    const field = /^([\w_]+):\s*(.*)$/.exec(line);
    if (field) fields[field[1]] = scalar(field[2]);
  }
  // Everything after this heading is editable prompt content, including nested headings.
  const section = /^## Prompt[ \t]*\n/m.exec(body);
  const text = section
    ? body.slice(section.index + section[0].length).trim()
    : "";
  if (!text) return undefined;
  const filename = path.split(/[\\/]/).pop() || path;
  const title =
    /^# (.+)$/m.exec(body)?.[1].replace(/^Implement Plan:\s*/i, "") ||
    filename.replace(/^implement-plan-/, "").replace(/\.md$/, "");
  const datedFilename =
    /^implement-plan-(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})-/.exec(
      filename,
    )?.[1];
  const metadataDate = creationDate(fields.created || "");
  const date = Number.isFinite(metadataDate)
    ? metadataDate
    : creationDate(datedFilename || "");
  return {
    path,
    title,
    text,
    sourceFile: fields.source_file || "",
    created: Number.isFinite(date) ? date : fallbackDate,
  };
}

export function sortPrompts(prompts: Prompt[]): Prompt[] {
  return [...prompts].sort(
    (a, b) => b.created - a.created || a.path.localeCompare(b.path),
  );
}

export function filterPrompts(prompts: Prompt[], query: string): Prompt[] {
  const terms = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
  return prompts.filter((prompt) => {
    const content =
      `${prompt.title}\n${prompt.path}\n${prompt.sourceFile}\n${prompt.text}`.toLowerCase();
    return terms.every((term) => content.includes(term));
  });
}

export async function resolveVault(
  configuredPath = "",
  home = homedir(),
): Promise<string> {
  const configured = configuredPath.trim();
  if (configured) {
    const expanded =
      configured === "~"
        ? home
        : configured.startsWith("~/")
          ? join(home, configured.slice(2))
          : configured;
    if (!isAbsolute(expanded))
      throw new Error("Set Obsidian Vault Path to an absolute path or ~/path.");
    return expanded;
  }
  const configPath = join(
    home,
    "Library/Application Support/obsidian/obsidian.json",
  );
  let config: { vaults?: Record<string, { path: string; open?: boolean }> };
  try {
    config = JSON.parse(await readFile(configPath, "utf8"));
  } catch {
    throw new Error(
      "Cannot read Obsidian's vault registry. Set Obsidian Vault Path in extension preferences.",
    );
  }
  const vaults = Object.values(config.vaults || {});
  const vault = vaults.find((entry) => entry.open) || vaults[0];
  if (!vault || !isAbsolute(vault.path))
    throw new Error(
      "No Obsidian vault found. Set Obsidian Vault Path in extension preferences.",
    );
  return vault.path;
}

export async function loadPrompts(vault: string): Promise<Prompt[]> {
  // Validate the vault separately so a missing prompts folder can simply be empty.
  if (!(await stat(vault)).isDirectory())
    throw new Error("Obsidian Vault Path must be a directory.");
  const folder = join(vault, PROMPTS_FOLDER);
  let entries;
  try {
    entries = await readdir(folder, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return [];
    throw error;
  }
  const prompts: Prompt[] = [];
  for (const entry of entries) {
    if (!entry.isFile() || !/^implement-plan-.+\.md$/i.test(entry.name))
      continue;
    const path = join(folder, entry.name);
    try {
      const [markdown, info] = await Promise.all([
        readFile(path, "utf8"),
        stat(path),
      ]);
      const prompt = parsePrompt(
        markdown,
        path,
        info.birthtimeMs || info.mtimeMs,
      );
      if (prompt) prompts.push(prompt);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
  }
  return sortPrompts(prompts);
}

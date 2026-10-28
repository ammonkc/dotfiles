const assert = require("node:assert/strict");
const { mkdtemp, mkdir, writeFile, rm } = require("node:fs/promises");
const { tmpdir } = require("node:os");
const { join } = require("node:path");
const {
  parsePrompt,
  sortPrompts,
  filterPrompts,
  resolveVault,
  loadPrompts,
  PROMPTS_FOLDER,
} = require("../dist/lib/prompts.js");

function note(created, title, text) {
  return `---\ncreated: ${created}\ntags:\n  - prompt\n  - implementation-prompt\n  - plan\nsource_file: /repo/.claude/plans/test.md\nplan_note: "[[Projects/Engineering/Plans/test]]"\n---\n\n# Implement Plan: ${title}\n\n## Plan\n[[Projects/Engineering/Plans/test|${title}]]\n\n## Prompt\n\n${text}\n`;
}

async function main() {
  const edited =
    'Implement the plan "Ship search".\n\nRead this exact path:\n/repo/.claude/plans/test.md\n\n## Custom instructions\nPreserve my edited instructions and **formatting**.';
  const older = parsePrompt(
    note("12/31/2025", "Ship search", edited),
    "/vault/implement-plan-12-31-2025-search.md",
    Date.now(),
  );
  const newer = parsePrompt(
    note("01/01/2026", "Deploy service", "Run focused checks."),
    "/vault/implement-plan-01-01-2026-deploy.md",
    0,
  );
  assert.equal(older.text, edited);
  assert.equal(older.title, "Ship search");
  assert.equal(older.sourceFile, "/repo/.claude/plans/test.md");
  assert.equal(
    parsePrompt(
      note("12/31/2025", "Ship search", edited).replace(/\n/g, "\r\n"),
      older.path,
      0,
    ).text,
    edited,
  );
  assert.equal(parsePrompt("# Empty\n## Prompt\n\n", "empty.md", 0), undefined);
  assert.equal(
    parsePrompt("# Other note\nNo prompt section.", "other.md", 0),
    undefined,
  );
  assert.equal(
    parsePrompt(
      note("invalid", "Fallback", "Go"),
      "/vault/implement-plan-2026-02-01-fallback.md",
      42,
    ).created,
    new Date(2026, 1, 1).getTime(),
  );
  assert.equal(
    parsePrompt(note("02/30/2026", "Bad date", "Go"), "bad.md", 42).created,
    42,
  );
  assert.equal(
    parsePrompt(note("2026-10-28", "ISO", "Go"), "iso.md", 0).created,
    new Date(2026, 9, 28).getTime(),
  );
  assert.deepEqual(sortPrompts([older, newer]), [newer, older]);
  assert.deepEqual(filterPrompts([newer, older], "  SHIP formatting "), [
    older,
  ]);
  assert.deepEqual(filterPrompts([newer, older], "focused"), [newer]);
  assert.deepEqual(filterPrompts([newer, older], "/repo/.claude"), [
    newer,
    older,
  ]);
  assert.deepEqual(filterPrompts([newer, older], "missing"), []);

  const home = await mkdtemp(join(tmpdir(), "obsidian-prompts-test-"));
  try {
    const vault = join(home, "My Vault");
    await mkdir(vault);
    assert.deepEqual(await loadPrompts(vault), []);
    await assert.rejects(loadPrompts(join(home, "missing")), /ENOENT/);
    await assert.rejects(resolveVault("", home), /vault registry/);
    const registry = join(home, "Library/Application Support/obsidian");
    await mkdir(registry, { recursive: true });
    await writeFile(
      join(registry, "obsidian.json"),
      JSON.stringify({
        vaults: { first: { path: home }, active: { path: vault, open: true } },
      }),
    );
    assert.equal(await resolveVault("", home), vault);
    assert.equal(await resolveVault("~/My Vault", home), vault);
    assert.equal(await resolveVault(home, home), home);
    await assert.rejects(resolveVault("relative/path", home), /absolute path/);
    await writeFile(
      join(registry, "obsidian.json"),
      JSON.stringify({
        vaults: { first: { path: home }, second: { path: vault } },
      }),
    );
    assert.equal(await resolveVault("", home), home);
    const folder = join(vault, PROMPTS_FOLDER);
    await mkdir(folder, { recursive: true });
    await writeFile(
      join(folder, "implement-plan-12-31-2025-search.md"),
      note("12/31/2025", "Ship search", edited),
    );
    await writeFile(
      join(folder, "implement-plan-01-01-2026-deploy.md"),
      note("01/01/2026", "Deploy service", "Run focused checks."),
    );
    await writeFile(
      join(folder, "unrelated.md"),
      note("01/02/2026", "Unrelated", "Ignore me"),
    );
    await writeFile(
      join(folder, "implement-plan-empty.md"),
      "# Empty\n## Prompt\n",
    );
    const loaded = await loadPrompts(vault);
    assert.deepEqual(
      loaded.map((prompt) => prompt.title),
      ["Deploy service", "Ship search"],
    );
    assert.equal(loaded[1].text, edited);
  } finally {
    await rm(home, { recursive: true, force: true });
  }
  console.log(
    "Prompt extraction, chronological sorting, search, and vault discovery passed.",
  );
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

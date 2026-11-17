import assert from "node:assert/strict";
import { test } from "node:test";
import { writeFile, unlink } from "node:fs/promises";
import { pathToFileURL } from "node:url";

test("OpenCode registers a strategy and creates, lists, and safely removes a real worktree", async () => {
  const { default: plugin, strategy } = await import(pathToFileURL(process.env.AGENT_PLUGIN_PATH));
  let registered;
  await plugin.setup({ worktree: { transform: async (fn) => fn({ add: (value) => { registered = value; } }) } });
  assert.equal(registered, strategy);
  const signal = new AbortController().signal;
  const repo = process.env.AGENT_TEST_REPO;
  const result = await strategy.create({ sourceDirectory: repo, directory: "/suggested/ui-task", branch: "main" }, { signal });
  assert.match(result.directory, /\/indirect-lending-application\/opencode-ui-task$/);
  const list = await strategy.list(repo, { signal });
  assert.ok(list.some((entry) => entry.directory === result.directory));
  await writeFile(`${result.directory}/work-in-progress`, "keep this");
  await assert.rejects(strategy.remove({ directory: result.directory, force: false }, { signal }), (error) => error.forceRequired === true);
  await unlink(`${result.directory}/work-in-progress`);
  await strategy.remove({ directory: result.directory, force: false }, { signal });
});

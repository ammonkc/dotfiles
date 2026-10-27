const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const {
  findNodeModules,
  deleteNodeModules,
} = require("../dist/lib/node-modules.js");
const { findRepositories } = require("../dist/lib/projects.js");
const execFileAsync = promisify(execFile);

(async () => {
  const scratch = await fs.mkdtemp(path.join(os.tmpdir(), "tinycast-cleanup-"));
  try {
    const root = path.join(scratch, "projects");
    const project = path.join(root, "team", "app");
    const modules = path.join(project, "node_modules");
    const outside = path.join(scratch, "outside", "node_modules");
    await fs.mkdir(modules, { recursive: true });
    await fs.mkdir(outside, { recursive: true });
    await fs.writeFile(path.join(modules, "dependency"), "test");
    await fs.writeFile(path.join(outside, "keep"), "outside");
    await fs.writeFile(path.join(project, "package.json"), "{}");
    await execFileAsync("git", ["init", "-q", project]);
    await execFileAsync("git", [
      "-C",
      project,
      "config",
      "user.name",
      "Test User",
    ]);
    await execFileAsync("git", [
      "-C",
      project,
      "config",
      "user.email",
      "test@example.invalid",
    ]);
    await execFileAsync("git", [
      "-C",
      project,
      "config",
      "commit.gpgsign",
      "false",
    ]);
    await execFileAsync("git", [
      "-C",
      project,
      "config",
      "core.hooksPath",
      "/dev/null",
    ]);
    await execFileAsync("git", ["-C", project, "add", "package.json"]);
    await execFileAsync("git", [
      "-C",
      project,
      "commit",
      "-qm",
      "test standup commit",
    ]);
    await fs.symlink(
      path.join(scratch, "outside"),
      path.join(root, "linked-project"),
    );

    const repositories = await findRepositories(root);
    assert.equal(repositories.length, 1);
    assert.equal(repositories[0].path, await fs.realpath(project));
    const standup = path.resolve(
      __dirname,
      "../../../../../../../packages/bin/.local/bin/git-standup",
    );
    const { stdout: standupOutput } = await execFileAsync(standup, [], {
      cwd: project,
    });
    assert.match(standupOutput, /test standup commit/);

    const result = await findNodeModules(root);
    assert.equal(result.entries.length, 1);
    assert.equal(result.entries[0].project, path.join("team", "app"));
    assert.ok(result.entries[0].sizeBytes !== null);
    await assert.rejects(() =>
      deleteNodeModules(root, { ...result.entries[0], path: outside }),
    );
    await fs.rename(modules, `${modules}-original`);
    await fs.mkdir(modules);
    await assert.rejects(() => deleteNodeModules(root, result.entries[0]));
    await fs.rmdir(modules);
    await fs.rename(`${modules}-original`, modules);
    await deleteNodeModules(root, result.entries[0]);
    await assert.rejects(() => fs.access(modules));
    await fs.access(path.join(outside, "keep"));
    await fs.access(path.join(project, "package.json"));
  } finally {
    await fs.rm(scratch, { recursive: true, force: true });
  }
  console.log("Node modules cleanup checks passed.");
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

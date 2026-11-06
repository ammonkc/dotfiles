// Shared behavioral suite for both launcher extensions; no launcher or Docker needed.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const vm = require("node:vm");
const { test } = require("node:test");

test("IDL helpers, preferences, streaming and failure paths", async () => {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "idl-extension-"));
  const home = path.join(scratch, "home with spaces");
  const base = path.join(home, "worktrees");
  const bin = path.join(home, ".local", "bin");
  fs.mkdirSync(bin, { recursive: true });
  fs.mkdirSync(path.join(base, "feature branch"), { recursive: true });
  fs.mkdirSync(path.join(base, ".hidden"));
  fs.writeFileSync(path.join(base, "not-a-directory"), "file");
  const preferences = { baseDir: "~/worktrees" };
  const modules = new Map();
  function load(name) {
    if (modules.has(name)) return modules.get(name);
    const exports = {};
    modules.set(name, exports);
    const source = fs.readFileSync(path.join(process.cwd(), "dist/lib", `${name}.js`), "utf8");
    vm.runInNewContext(source, {
      exports, process, Buffer, console,
      require(id) {
        if (id === "os") return { ...os, homedir: () => home };
        if (id === "@raycast/api") return { getPreferenceValues: () => preferences };
        if (id.startsWith("./")) return load(id.slice(2));
        return require(id);
      },
    }, { filename: `${name}.js` });
    return exports;
  }
  function helper(name, exitCode) {
    fs.writeFileSync(path.join(bin, name), `#!${process.execPath}
console.log(JSON.stringify({args:process.argv.slice(2),base:process.env.IDL_WORKTREES_DIR,cwd:process.cwd(),path:process.env.PATH}));
process.stdout.write('first');
process.stderr.write('warning');
const unicode = Buffer.from('λ');
process.stdout.write(' line\\n');
process.stdout.write(unicode.subarray(0, 1));
setTimeout(() => {
  process.stdout.write(unicode.subarray(1));
  process.stdout.write('\\nlast');
  process.stderr.write(' line\\n');
  process.exitCode = ${exitCode};
}, 30);
`, { mode: 0o755 });
  }
  async function run(fn, options) {
    const lines = [];
    const completions = [];
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("Helper timed out")), 5000);
      fn(options, {
        onOutput: (line) => lines.push(line),
        onComplete: (success, message) => {
          completions.push({ success, message });
          clearTimeout(timer);
          // Missing executables emit both error and close: completion must happen once.
          setTimeout(resolve, 50);
        },
      });
    });
    assert.equal(completions.length, 1);
    return { lines, ...completions[0] };
  }
  try {
    const worktrees = load("worktrees");
    assert.equal(worktrees.getBaseDir(), base);
    assert.deepEqual(Array.from(worktrees.listWorktrees()), ["feature branch"]);
    assert.equal(worktrees.worktreeExists("feature branch"), true);
    assert.equal(worktrees.worktreeExists("not-a-directory"), false);
    assert.equal(worktrees.worktreeExists("missing"), false);
    assert.equal(worktrees.getDefaultWorktree(), "main");
    assert.equal(worktrees.getAllegroDomain(), "indirect.test");
    const docker = load("docker");
    const options = { worktree: "feature branch", domain: "example.test; echo injected", profiles: ["queue"] };
    for (const [name, fn] of [["idl-up", docker.startContainersStream], ["idl-down", docker.stopContainersStream]]) {
      helper(name, 0);
      const success = await run(fn, options);
      assert.equal(success.success, true);
      const metadata = JSON.parse(success.lines.find((line) => line.startsWith("{")));
      assert.deepEqual(metadata.args, [options.worktree, options.domain, "--profile", "queue"]);
      assert.equal(metadata.base, base);
      assert.equal(metadata.cwd, process.cwd());
      assert.equal(metadata.path.split(":")[0], bin);
      for (const line of ["first line", "warning line", "λ", "last"]) assert.ok(success.lines.includes(line), line);
      helper(name, 7);
      const failure = await run(fn, { ...options, profiles: [] });
      assert.equal(failure.success, false);
      assert.match(failure.message, /exit code 7/);
      assert.deepEqual(JSON.parse(failure.lines.find((line) => line.startsWith("{"))).args, [options.worktree, options.domain]);
      fs.unlinkSync(path.join(bin, name));
      const missing = await run(fn, options);
      assert.equal(missing.success, false);
      assert.match(missing.message, /ENOENT/);
    }
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
});

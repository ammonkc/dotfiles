import { execFile } from "node:child_process";
import { basename, join } from "node:path";
import { homedir } from "node:os";
import { Plugin, Worktree } from "@opencode/plugin";

const helper = join(homedir(), ".local/bin/agent-worktree");

function invoke(args, signal) {
  return new Promise((resolve, reject) => {
    execFile(helper, args, { signal, maxBuffer: 1024 * 1024 }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr.trim() || error.message));
      else resolve(stdout);
    });
  });
}

export const strategy = {
  id: "dotfiles.worktrunk",
  async create(input, { signal }) {
    const args = [
      "create", "--tool", "opencode", "--repo", input.sourceDirectory,
      "--json", basename(input.directory),
    ];
    if (input.branch) args.push("--base", input.branch);
    const result = JSON.parse(await invoke(args, signal));
    return { directory: result.directory };
  },
  async remove(input, { signal }) {
    const args = ["remove", "--tool", "opencode", input.directory];
    if (input.force) args.push("--force");
    try {
      await invoke(args, signal);
    } catch (error) {
      if (!input.force && /uncommitted changes/.test(error.message)) {
        throw new Worktree.OperationError({ message: error.message, forceRequired: true });
      }
      throw error;
    }
  },
  async list(sourceDirectory, { signal }) {
    return JSON.parse(await invoke(["list", "--tool", "opencode", "--repo", sourceDirectory], signal));
  },
};

export default Plugin.define({
  id: "dotfiles.worktrunk",
  async setup(ctx) {
    await ctx.worktree.transform((editor) => editor.add(strategy));
  },
});

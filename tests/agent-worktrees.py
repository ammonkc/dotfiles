"""Behavioral checks for shared agent worktrees and private settings merges."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "packages/bin/.local/bin/agent-worktree"
CONFIGURE = ROOT / "scripts/agent-worktree-configure.py"


class SettingsTests(unittest.TestCase):
    def test_merge_preserves_private_settings_is_idempotent_and_refuses_conflicts(self):
        with tempfile.TemporaryDirectory() as scratch:
            home = Path(scratch)
            claude = home / ".claude"
            opencode = home / ".config/opencode"
            claude.mkdir(parents=True)
            opencode.mkdir(parents=True)
            for target, source in [
                (claude, ROOT / "packages/claude/.claude"),
                (opencode, ROOT / "packages/opencode/.config/opencode"),
            ]:
                shutil.copyfile(source / "worktree-settings.json", target / "worktree-settings.json")
            private = {"env": {"TEST_PRIVATE_VALUE": "fixture-only"}, "hooks": {"Stop": []}}
            (claude / "settings.json").write_text(json.dumps(private))
            (opencode / "opencode.json").write_text(json.dumps({"providers": {"fixture": {}}, "plugins": ["existing-plugin"]}))
            command = ["python3", str(CONFIGURE), "--home", str(home)]
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            actual = json.loads((claude / "settings.json").read_text())
            self.assertEqual(actual["env"], private["env"])
            self.assertIn("Stop", actual["hooks"])
            self.assertIn("WorktreeCreate", actual["hooks"])
            self.assertEqual(json.loads((opencode / "opencode.json").read_text())["plugins"][0], "existing-plugin")
            backups = list(home.rglob("*.backup.*"))
            self.assertEqual(len(backups), 2)
            for path in backups + [claude / "settings.json", opencode / "opencode.json"]:
                self.assertEqual(path.stat().st_mode & 0o077, 0)
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            self.assertEqual(list(home.rglob("*.backup.*")), backups)
            actual["hooks"]["WorktreeCreate"] = [{"hooks": [{"command": "another-creator"}]}]
            (claude / "settings.json").write_text(json.dumps(actual))
            before = (opencode / "opencode.json").read_bytes()
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((opencode / "opencode.json").read_bytes(), before)


@unittest.skipUnless(shutil.which("wt"), "Worktrunk not installed")
class CreationTests(unittest.TestCase):
    def test_agent_creation_setup_collision_inventory_and_safe_removal(self):
        with tempfile.TemporaryDirectory() as scratch:
            scratch = Path(scratch).resolve()
            home = scratch / "home with spaces"
            repo = home / "Developer/code/renamed-checkout"
            bin_dir = home / ".local/bin"
            repo.mkdir(parents=True)
            bin_dir.mkdir(parents=True)
            for name in ["git-worktree-setup", "idl-worktree-setup", "agent-worktree"]:
                (bin_dir / name).symlink_to(ROOT / "packages/bin/.local/bin" / name)
            env = {**os.environ, "HOME": str(home),
                   "WORKTRUNK_CONFIG_PATH": str(ROOT / "packages/worktrunk/.config/worktrunk/config.toml"),
                   "IDL_REPO_DIR": str(repo),
                   "IDL_WORKTREES_DIR": str(home / "Developer/worktrees/indirect-lending-application"),
                   "IDL_ZED_TASKS_TEMPLATE": str(ROOT / "packages/zed/.config/zed/templates/idl-tasks.json")}

            def git(*args):
                return subprocess.check_output(["git", "-C", str(repo), *args], env=env, text=True).strip()

            def call(*args, **kwargs):
                return subprocess.run([str(HELPER), *args], env=env, text=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, **kwargs)

            git("init", "-q", "-b", "main")
            git("remote", "add", "origin", "https://github.com/ncino/indirect-lending-application.git")
            git("config", "core.excludesfile", str(ROOT / "packages/git/.config/git/ignore"))
            (repo / ".gitignore").write_text("vendor/\nexcluded/\n")
            git("add", ".gitignore")
            git("-c", "user.name=Test", "-c", "user.email=test@example.test", "-c", "commit.gpgsign=false", "commit", "-qm", "initial")
            (repo / ".worktreeinclude").write_text("vendor/\n")
            (repo / "vendor").mkdir()
            (repo / "vendor/dependency").write_text("dependency fixture")
            (repo / "excluded").mkdir()
            (repo / "excluded/cache").write_text("not selected")
            event = json.dumps({"cwd": str(repo), "name": "task-name"})
            created = call("claude-create", input=event, check=True)
            claude_path = Path(created.stdout.strip())
            self.assertEqual(claude_path, home / "Developer/worktrees/indirect-lending-application/claude-task-name")
            self.assertEqual((claude_path / "vendor/dependency").read_text(), "dependency fixture")
            self.assertFalse((claude_path / "excluded/cache").exists())
            self.assertTrue((claude_path / ".zed/tasks.json").exists())
            collision = call("claude-create", input=event)
            self.assertNotEqual(collision.returncode, 0)
            self.assertEqual((claude_path / "vendor/dependency").read_text(), "dependency fixture")
            codex = call("create", "--tool", "codex", "--repo", str(repo), "task-name", check=True)
            self.assertEqual(Path(codex.stdout.strip()).name, "codex-task-name")
            opencode = call("create", "--tool", "opencode", "--repo", str(repo), "--base", "main", "task-name", "--json", check=True)
            oc_path = Path(json.loads(opencode.stdout)["directory"])
            inventory = json.loads(call("list", "--tool", "opencode", "--repo", str(repo), check=True).stdout)
            self.assertEqual(inventory, [{"directory": str(repo), "type": "root"}, {"directory": str(oc_path), "type": "worktree"}])
            unsafe = call("remove", "--tool", "claude", str(repo))
            self.assertNotEqual(unsafe.returncode, 0)
            (claude_path / "work-in-progress").write_text("keep this")
            dirty = call("claude-remove", input=json.dumps({"worktree_path": str(claude_path)}))
            self.assertNotEqual(dirty.returncode, 0)
            self.assertTrue(claude_path.exists())
            (claude_path / "work-in-progress").unlink()
            call("claude-remove", input=json.dumps({"worktree_path": str(claude_path)}), check=True)
            self.assertFalse(claude_path.exists())
            git("show-ref", "--verify", "refs/heads/claude/task-name")
            for name in ["../escape", "bad;name", "a b"]:
                invalid = call("create", "--tool", "codex", "--repo", str(repo), name)
                # Semicolons are legal branch characters; they must never execute as shell commands.
                if name != "bad;name":
                    self.assertNotEqual(invalid.returncode, 0)
                else:
                    self.assertEqual(invalid.returncode, 0)
                    self.assertEqual(Path(invalid.stdout.strip()).name, "codex-bad;name")
            if os.environ.get("AGENT_OPENCODE_TEST_PLUGIN"):
                subprocess.run(["node", "--test", str(ROOT / "tests/agent-worktrees-plugin.mjs")], check=True,
                               env={**env, "AGENT_PLUGIN_PATH": os.environ["AGENT_OPENCODE_TEST_PLUGIN"], "AGENT_TEST_REPO": str(repo)})


if __name__ == "__main__":
    unittest.main()

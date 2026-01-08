import { spawn } from "child_process";
import { homedir } from "os";
import { join } from "path";

// Path to the bash scripts
const SCRIPTS_DIR = join(homedir(), ".local", "bin");

// Ensure common paths are available (Homebrew, etc.)
function getEnvWithPath(): NodeJS.ProcessEnv {
  const additionalPaths = [
    join(homedir(), ".local", "bin"),
    "/opt/homebrew/bin",
    "/opt/homebrew/sbin",
    "/usr/local/bin",
    "/usr/local/sbin",
    "/usr/bin",
    "/bin",
  ];
  const currentPath = process.env.PATH || "";
  return {
    ...process.env,
    PATH: `${additionalPaths.join(":")}:${currentPath}`,
  };
}

export interface StreamCallbacks {
  onOutput: (line: string) => void;
  onComplete: (success: boolean, message: string) => void;
}

/**
 * Start Docker containers for a worktree using idl-up script (streaming)
 */
export function startContainersStream(worktree: string, callbacks: StreamCallbacks): void {
  const script = join(SCRIPTS_DIR, "idl-up");

  const proc = spawn(script, [worktree], {
    env: getEnvWithPath(),
    shell: true,
  });

  proc.stdout.on("data", (data: Buffer) => {
    const lines = data.toString().split("\n").filter(Boolean);
    lines.forEach((line) => callbacks.onOutput(line));
  });

  proc.stderr.on("data", (data: Buffer) => {
    const lines = data.toString().split("\n").filter(Boolean);
    lines.forEach((line) => callbacks.onOutput(line));
  });

  proc.on("close", (code) => {
    if (code === 0) {
      callbacks.onComplete(true, `Containers started for ${worktree}`);
    } else {
      callbacks.onComplete(false, `Failed with exit code ${code}`);
    }
  });

  proc.on("error", (error) => {
    callbacks.onComplete(false, error.message);
  });
}

/**
 * Stop Docker containers for a worktree using idl-down script (streaming)
 */
export function stopContainersStream(worktree: string, callbacks: StreamCallbacks): void {
  const script = join(SCRIPTS_DIR, "idl-down");

  const proc = spawn(script, [worktree], {
    env: getEnvWithPath(),
    shell: true,
  });

  proc.stdout.on("data", (data: Buffer) => {
    const lines = data.toString().split("\n").filter(Boolean);
    lines.forEach((line) => callbacks.onOutput(line));
  });

  proc.stderr.on("data", (data: Buffer) => {
    const lines = data.toString().split("\n").filter(Boolean);
    lines.forEach((line) => callbacks.onOutput(line));
  });

  proc.on("close", (code) => {
    if (code === 0) {
      callbacks.onComplete(true, `Containers stopped for ${worktree}`);
    } else {
      callbacks.onComplete(false, `Failed with exit code ${code}`);
    }
  });

  proc.on("error", (error) => {
    callbacks.onComplete(false, error.message);
  });
}

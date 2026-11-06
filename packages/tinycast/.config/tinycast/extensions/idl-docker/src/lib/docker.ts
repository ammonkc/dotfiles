import { spawn } from "child_process";
import { homedir } from "os";
import { join } from "path";
import { StringDecoder } from "string_decoder";
import { getBaseDir } from "./worktrees";

export interface StreamCallbacks {
  onOutput: (line: string) => void;
  onComplete: (success: boolean, message: string) => void;
}

export interface ContainerOptions {
  worktree: string;
  domain: string;
  profiles?: string[];
}

function runContainers(
  action: "start" | "stop",
  options: ContainerOptions,
  callbacks: StreamCallbacks,
): void {
  const { worktree, domain, profiles = [] } = options;
  const bin = join(homedir(), ".local", "bin");
  const paths = [
    bin,
    "/opt/homebrew/bin",
    "/opt/homebrew/sbin",
    "/usr/local/bin",
    "/usr/local/sbin",
    "/usr/bin",
    "/bin",
  ];
  const proc = spawn(
    join(bin, action === "start" ? "idl-up" : "idl-down"),
    [
      worktree,
      domain,
      ...profiles.flatMap((profile) => ["--profile", profile]),
    ],
    {
      env: {
        ...process.env,
        PATH: `${paths.join(":")}:${process.env.PATH || ""}`,
        IDL_WORKTREES_DIR: getBaseDir(),
      },
    },
  );

  // Pipe chunks can split lines and UTF-8 characters at arbitrary positions.
  for (const stream of [proc.stdout, proc.stderr]) {
    const decoder = new StringDecoder("utf8");
    let pending = "";
    stream.on("data", (data: Buffer) => {
      pending += decoder.write(data);
      const lines = pending.split("\n");
      pending = lines.pop() || "";
      lines.filter(Boolean).forEach((line) => callbacks.onOutput(line));
    });
    stream.on("end", () => {
      pending += decoder.end();
      if (pending) callbacks.onOutput(pending);
    });
  }

  let completed = false;
  function complete(success: boolean, message: string): void {
    if (completed) return;
    completed = true;
    callbacks.onComplete(success, message);
  }
  proc.on("error", (error) => complete(false, error.message));
  proc.on("close", (code) => {
    complete(
      code === 0,
      code === 0
        ? `Containers ${action === "start" ? "started" : "stopped"} for ${worktree} @ ${domain}`
        : `Failed with exit code ${code}`,
    );
  });
}

export function startContainersStream(
  options: ContainerOptions,
  callbacks: StreamCallbacks,
): void {
  runContainers("start", options, callbacks);
}

export function stopContainersStream(
  options: ContainerOptions,
  callbacks: StreamCallbacks,
): void {
  runContainers("stop", options, callbacks);
}

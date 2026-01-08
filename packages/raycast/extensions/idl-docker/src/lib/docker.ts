import { exec, ExecException } from "child_process";
import { promisify } from "util";
import { getWorktreePath } from "./worktrees";

const execAsync = promisify(exec);

export interface DockerResult {
  success: boolean;
  message: string;
  output?: string;
}

// Ensure common paths are available (Homebrew, etc.)
function getEnvWithPath(): NodeJS.ProcessEnv {
  const additionalPaths = [
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

// Extract meaningful error message from exec error
function getErrorDetails(error: unknown): string {
  if (error && typeof error === "object") {
    const execError = error as ExecException & { stderr?: string; stdout?: string };
    // Prefer stderr, fall back to stdout, then message
    if (execError.stderr?.trim()) {
      return execError.stderr.trim();
    }
    if (execError.stdout?.trim()) {
      return execError.stdout.trim();
    }
    if (execError.message) {
      return execError.message;
    }
  }
  return String(error);
}

/**
 * Start Docker containers for a worktree
 */
export async function startContainers(worktree: string): Promise<DockerResult> {
  const projectDir = getWorktreePath(worktree);

  const command = `cd "${projectDir}" && ALLEGRO_DOMAIN=indirect.test docker compose -f docker-compose.yaml --profile sftp up --force-recreate --build --detach --remove-orphans`;

  try {
    const { stdout, stderr } = await execAsync(command, {
      timeout: 300000, // 5 minute timeout for build
      env: getEnvWithPath(),
    });

    return {
      success: true,
      message: `Containers started for ${worktree}`,
      output: stdout || stderr,
    };
  } catch (error) {
    return {
      success: false,
      message: getErrorDetails(error),
    };
  }
}

/**
 * Stop Docker containers for a worktree
 */
export async function stopContainers(worktree: string): Promise<DockerResult> {
  const projectDir = getWorktreePath(worktree);

  const command = `cd "${projectDir}" && ALLEGRO_DOMAIN=indirect.test docker compose -f docker-compose.yaml --profile sftp --profile php8-work down`;

  try {
    const { stdout, stderr } = await execAsync(command, {
      timeout: 60000, // 1 minute timeout
      env: getEnvWithPath(),
    });

    return {
      success: true,
      message: `Containers stopped for ${worktree}`,
      output: stdout || stderr,
    };
  } catch (error) {
    return {
      success: false,
      message: getErrorDetails(error),
    };
  }
}

/**
 * Get container status for a worktree
 */
export async function getContainerStatus(worktree: string): Promise<DockerResult> {
  const projectDir = getWorktreePath(worktree);

  const command = `cd "${projectDir}" && docker compose -f docker-compose.yaml ps --format json 2>/dev/null || echo "[]"`;

  try {
    const { stdout } = await execAsync(command, {
      timeout: 10000,
      env: getEnvWithPath(),
    });

    return {
      success: true,
      message: "Status retrieved",
      output: stdout,
    };
  } catch (error) {
    return {
      success: false,
      message: getErrorDetails(error),
    };
  }
}

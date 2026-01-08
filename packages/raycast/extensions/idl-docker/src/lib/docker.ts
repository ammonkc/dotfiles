import { exec } from "child_process";
import { promisify } from "util";
import { getWorktreePath } from "./worktrees";

const execAsync = promisify(exec);

export interface DockerResult {
  success: boolean;
  message: string;
  output?: string;
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
      env: { ...process.env },
    });

    return {
      success: true,
      message: `Containers started for ${worktree}`,
      output: stdout || stderr,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      message: `Failed to start containers: ${errorMessage}`,
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
      env: { ...process.env },
    });

    return {
      success: true,
      message: `Containers stopped for ${worktree}`,
      output: stdout || stderr,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      message: `Failed to stop containers: ${errorMessage}`,
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
      env: { ...process.env },
    });

    return {
      success: true,
      message: "Status retrieved",
      output: stdout,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      success: false,
      message: `Failed to get status: ${errorMessage}`,
    };
  }
}

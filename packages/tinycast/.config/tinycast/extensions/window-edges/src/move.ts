import { environment, getFrontmostApplication, showHUD } from "@raycast/api";
import { execFile } from "child_process";
import { join } from "path";
import { promisify } from "util";

const run = promisify(execFile);

export async function moveToEdge(edge: "left" | "right" | "top" | "bottom") {
  try {
    const app = await getFrontmostApplication();
    if (!app.bundleId)
      throw new Error("The focused application has no bundle ID.");
    await run(
      join(environment.assetsPath, "window-edges"),
      [edge, app.bundleId],
      {
        timeout: 5000,
      },
    );
  } catch (error) {
    const failure = error as Error & { stderr?: string };
    await showHUD(
      failure.stderr?.trim() || failure.message || "Could not move window.",
    );
  }
}

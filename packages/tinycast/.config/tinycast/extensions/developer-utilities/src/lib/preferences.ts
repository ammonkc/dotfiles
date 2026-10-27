import { getPreferenceValues } from "@raycast/api";
import { expandProjectsDir } from "./projects";

export function getProjectsDir(): string {
  const { projectsDir } = getPreferenceValues<{ projectsDir: string }>();
  return expandProjectsDir(projectsDir);
}

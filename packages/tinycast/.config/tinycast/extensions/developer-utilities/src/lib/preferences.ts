import { getPreferenceValues } from "@raycast/api";
import { expandProjectsDir } from "./projects";

export function getProjectsDir(): string {
  const { projectsDir } = getPreferenceValues<{ projectsDir: string }>();
  return expandProjectsDir(projectsDir);
}

export function getEditorApp(): string {
  const { editorApp } = getPreferenceValues<{ editorApp?: string }>();
  return editorApp?.trim() || "Zed";
}

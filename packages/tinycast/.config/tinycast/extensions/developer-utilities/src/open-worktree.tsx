import {
  Action,
  ActionPanel,
  Icon,
  List,
  showToast,
  Toast,
} from "@raycast/api";
import { execFile } from "child_process";
import { promisify } from "util";
import { useEffect, useState } from "react";
import { getEditorApp, getProjectsDir } from "./lib/preferences";
import { findRepositories, Project } from "./lib/projects";

const execFileAsync = promisify(execFile);

export default function OpenWorktree() {
  const projectsDir = getProjectsDir();
  const editorApp = getEditorApp();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    findRepositories(projectsDir)
      .then((found) => {
        if (active) setProjects(found);
      })
      .catch((cause) => {
        if (active)
          setError(cause instanceof Error ? cause.message : String(cause));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [projectsDir]);

  async function openWorktree(project: Project) {
    try {
      await execFileAsync("/usr/bin/open", ["-a", editorApp, project.path]);
      await showToast({
        style: Toast.Style.Success,
        title: `Opened in ${editorApp}`,
        message: project.path,
      });
    } catch (cause) {
      await showToast({
        style: Toast.Style.Failure,
        title: `Could not open ${editorApp}`,
        message: cause instanceof Error ? cause.message : String(cause),
      });
    }
  }

  return (
    <List isLoading={loading} searchBarPlaceholder="Choose a worktree to open">
      {projects.length === 0 && (
        <List.EmptyView
          icon={Icon.Folder}
          title={error ? "Cannot scan projects" : "No Git worktrees found"}
          description={error || projectsDir}
        />
      )}
      {projects.map((project) => (
        <List.Item
          key={project.path}
          icon={Icon.Code}
          title={project.title}
          subtitle={project.subtitle}
          actions={
            <ActionPanel>
              <Action
                title={`Open in ${editorApp}`}
                icon={Icon.Code}
                onAction={() => void openWorktree(project)}
              />
              <Action.CopyToClipboard
                title="Copy Worktree Path"
                content={project.path}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

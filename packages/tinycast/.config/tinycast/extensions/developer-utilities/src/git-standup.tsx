import { Action, ActionPanel, Detail, Icon, List } from "@raycast/api";
import { execFile } from "child_process";
import { promisify } from "util";
import { useEffect, useState } from "react";
import { homedir } from "os";
import { join } from "path";
import { getProjectsDir } from "./lib/preferences";
import { findRepositories, Project } from "./lib/projects";

const execFileAsync = promisify(execFile);
const ANSI_COLOR = new RegExp(`${String.fromCharCode(27)}\\[[0-9;]*m`, "g");

function StandupDetail({
  project,
  days,
  allAuthors,
}: {
  project: Project;
  days: number;
  allAuthors: boolean;
}) {
  const [output, setOutput] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    async function load() {
      try {
        const args = ["-d", String(days), ...(allAuthors ? ["-a"] : [])];
        const { stdout } = await execFileAsync(
          join(homedir(), ".local/bin/git-standup"),
          args,
          {
            cwd: project.path,
            timeout: 15000,
          },
        );
        if (active) setOutput(stdout.replace(ANSI_COLOR, ""));
      } catch (cause) {
        if (active)
          setOutput(cause instanceof Error ? cause.message : String(cause));
      } finally {
        if (active) setLoading(false);
      }
    }
    void load();
    return () => {
      active = false;
    };
  }, [project.path, days, allAuthors]);

  return (
    <Detail
      isLoading={loading}
      navigationTitle={`${project.title} · ${days} ${days === 1 ? "day" : "days"}`}
      markdown={`## ${project.title}\n\n\`\`\`text\n${output.trim() || "No commits found."}\n\`\`\``}
      actions={
        <ActionPanel>
          <Action.CopyToClipboard title="Copy Standup" content={output} />
        </ActionPanel>
      }
    />
  );
}

export default function GitStandup() {
  const projectsDir = getProjectsDir();
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

  return (
    <List
      isLoading={loading}
      searchBarPlaceholder="Choose a repository for standup"
    >
      {projects.length === 0 && (
        <List.EmptyView
          icon={Icon.Folder}
          title={error ? "Cannot scan projects" : "No Git repositories found"}
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
              <Action.Push
                title="My Commits · Last Day"
                target={
                  <StandupDetail
                    project={project}
                    days={1}
                    allAuthors={false}
                  />
                }
              />
              <Action.Push
                title="My Commits · Last 3 Days"
                target={
                  <StandupDetail
                    project={project}
                    days={3}
                    allAuthors={false}
                  />
                }
              />
              <Action.Push
                title="All Authors · Last Day"
                target={<StandupDetail project={project} days={1} allAuthors />}
              />
              <Action.CopyToClipboard
                title="Copy Repository Path"
                content={project.path}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

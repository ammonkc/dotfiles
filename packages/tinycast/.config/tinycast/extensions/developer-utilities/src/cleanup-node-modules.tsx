import {
  Action,
  ActionPanel,
  Detail,
  Icon,
  List,
  showToast,
  Toast,
  useNavigation,
} from "@raycast/api";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  deleteNodeModules,
  findNodeModules,
  formatBytes,
  NodeModulesEntry,
} from "./lib/node-modules";
import { getProjectsDir } from "./lib/preferences";

function DeleteConfirmation({
  targets,
  onConfirm,
}: {
  targets: NodeModulesEntry[];
  onConfirm: () => Promise<void>;
}) {
  const { pop } = useNavigation();
  const [working, setWorking] = useState(false);
  const started = useRef(false);
  const total = targets.reduce((sum, entry) => sum + (entry.sizeBytes ?? 0), 0);
  return (
    <Detail
      isLoading={working}
      navigationTitle="Confirm node_modules cleanup"
      markdown={`## Delete ${targets.length} ${targets.length === 1 ? "directory" : "directories"}?\n\nApproximately **${formatBytes(total)}** will be removed. These dependencies can be restored by their package managers.\n\n${targets.map((entry) => `- ${entry.project} (${formatBytes(entry.sizeBytes)})`).join("\n")}`}
      actions={
        <ActionPanel>
          <Action
            title="Delete Selected Directories"
            icon={Icon.Trash}
            style={Action.Style.Destructive}
            onAction={async () => {
              if (started.current) return;
              started.current = true;
              setWorking(true);
              try {
                await onConfirm();
                pop();
              } catch (cause) {
                started.current = false;
                setWorking(false);
                await showToast({
                  style: Toast.Style.Failure,
                  title: "Cleanup failed",
                  message: String(cause),
                });
              }
            }}
          />
          {!working && <Action title="Cancel" onAction={pop} />}
        </ActionPanel>
      }
    />
  );
}

export default function CleanupNodeModules() {
  const projectsDir = getProjectsDir();
  const { push } = useNavigation();
  const [root, setRoot] = useState("");
  const [entries, setEntries] = useState<NodeModulesEntry[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const refresh = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const result = await findNodeModules(projectsDir);
      setRoot(result.root);
      setEntries(result.entries);
      setSelected(new Set());
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : String(cause));
    } finally {
      setLoading(false);
    }
  }, [projectsDir]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  function toggle(path: string) {
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(path)) next.delete(path);
      else next.add(path);
      return next;
    });
  }

  async function removeTargets(targets: NodeModulesEntry[]) {
    const total = targets.reduce(
      (sum, entry) => sum + (entry.sizeBytes ?? 0),
      0,
    );
    setLoading(true);
    const failures: string[] = [];
    for (const entry of targets) {
      try {
        await deleteNodeModules(root, entry);
      } catch (cause) {
        failures.push(
          `${entry.project}: ${cause instanceof Error ? cause.message : String(cause)}`,
        );
      }
    }
    await refresh();
    await showToast({
      style: failures.length ? Toast.Style.Failure : Toast.Style.Success,
      title: failures.length
        ? `${failures.length} deletion(s) failed`
        : `${targets.length} directory(s) deleted`,
      message: failures[0] ?? `${formatBytes(total)} selected`,
    });
  }

  function askToDelete(paths: string[]) {
    const targets = entries.filter((entry) => paths.includes(entry.path));
    if (targets.length === 0) return;
    push(
      <DeleteConfirmation
        targets={targets}
        onConfirm={() => removeTargets(targets)}
      />,
    );
  }

  return (
    <List
      isLoading={loading}
      searchBarPlaceholder="Search node_modules by project or path"
    >
      {entries.length === 0 && (
        <List.EmptyView
          icon={error ? Icon.Warning : Icon.Check}
          title={error ? "Cannot scan projects" : "No node_modules found"}
          description={error || projectsDir}
          actions={
            <ActionPanel>
              <Action title="Scan Again" onAction={refresh} />
            </ActionPanel>
          }
        />
      )}
      {entries.map((entry) => (
        <List.Item
          key={entry.path}
          icon={selected.has(entry.path) ? Icon.CheckCircle : Icon.Folder}
          title={entry.project}
          subtitle={entry.path}
          accessories={[
            { text: formatBytes(entry.sizeBytes) },
            ...(entry.packageModifiedAt
              ? [
                  {
                    text: new Date(
                      entry.packageModifiedAt,
                    ).toLocaleDateString(),
                    tooltip: "package.json modified",
                  },
                ]
              : []),
          ]}
          actions={
            <ActionPanel>
              <Action
                title={selected.has(entry.path) ? "Deselect" : "Select"}
                icon={selected.has(entry.path) ? Icon.XMarkCircle : Icon.Check}
                onAction={() => toggle(entry.path)}
              />
              {selected.size > 0 && (
                <Action
                  title={`Delete ${selected.size} Selected`}
                  icon={Icon.Trash}
                  onAction={() => askToDelete([...selected])}
                />
              )}
              <Action
                title="Delete This Directory"
                icon={Icon.Trash}
                onAction={() => askToDelete([entry.path])}
              />
              <Action
                title="Scan Again"
                icon={Icon.ArrowClockwise}
                onAction={refresh}
              />
              <Action.CopyToClipboard title="Copy Path" content={entry.path} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

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
import { useState, useEffect, useCallback, useRef } from "react";
import { stopContainersStream } from "./lib/docker";
import { listWorktrees, getDefaultWorktree, worktreeExists, getAllegroDomain } from "./lib/worktrees";

function OutputView({ worktree }: { worktree: string }) {
  const [output, setOutput] = useState<string[]>([]);
  const [isRunning, setIsRunning] = useState(true);
  const [success, setSuccess] = useState<boolean | null>(null);
  const { pop } = useNavigation();
  const hasStarted = useRef(false);
  const domain = getAllegroDomain();

  useEffect(() => {
    // Prevent double execution (React strict mode)
    if (hasStarted.current) return;
    hasStarted.current = true;

    setOutput([`🛑 Stopping containers for ${worktree} @ ${domain}...`, ""]);

    stopContainersStream({ worktree, domain }, {
      onOutput: (line) => {
        setOutput((prev) => [...prev, line]);
      },
      onComplete: async (succeeded, message) => {
        setIsRunning(false);
        setSuccess(succeeded);
        setOutput((prev) => [...prev, "", succeeded ? `✅ ${message}` : `❌ ${message}`]);

        await showToast({
          style: succeeded ? Toast.Style.Success : Toast.Style.Failure,
          title: succeeded ? "Containers stopped" : "Failed to stop",
          message: worktree,
        });
      },
    });
  }, [worktree]);

  const statusIcon = isRunning ? "⏳" : success ? "✅" : "❌";
  const statusText = isRunning ? "Stopping..." : success ? "Stopped" : "Failed";

  const markdown = `
\`\`\`
${output.join("\n")}
\`\`\`
`;

  return (
    <Detail
      navigationTitle={`${statusIcon} ${statusText} - ${worktree}`}
      markdown={markdown}
      isLoading={isRunning}
      metadata={
        <Detail.Metadata>
          <Detail.Metadata.Label title="Worktree" text={worktree} />
          <Detail.Metadata.Label title="Domain" text={domain} />
          <Detail.Metadata.Separator />
          <Detail.Metadata.Label
            title="Status"
            text={statusText}
            icon={isRunning ? Icon.Clock : success ? Icon.Check : Icon.XMarkCircle}
          />
          <Detail.Metadata.Label title="Lines" text={String(output.length)} />
        </Detail.Metadata>
      }
      actions={
        <ActionPanel>
          {!isRunning && (
            <Action title="Done" icon={Icon.Check} onAction={pop} />
          )}
          <Action.CopyToClipboard
            title="Copy Output"
            content={output.join("\n")}
            shortcut={{ modifiers: ["cmd"], key: "c" }}
          />
        </ActionPanel>
      }
    />
  );
}

export default function StopCommand() {
  const worktrees = listWorktrees();
  const defaultWorktree = getDefaultWorktree();
  const { push } = useNavigation();

  // Sort worktrees with default first
  const sortedWorktrees = [...worktrees].sort((a, b) => {
    if (a === defaultWorktree) return -1;
    if (b === defaultWorktree) return 1;
    return a.localeCompare(b);
  });

  const handleStop = useCallback(
    async (worktree: string) => {
      if (!worktreeExists(worktree)) {
        await showToast({
          style: Toast.Style.Failure,
          title: "Worktree not found",
          message: `Directory for "${worktree}" does not exist`,
        });
        return;
      }

      push(<OutputView worktree={worktree} />);
    },
    [push]
  );

  if (worktrees.length === 0) {
    return (
      <List>
        <List.EmptyView
          icon={Icon.Warning}
          title="No worktrees found"
          description="Check your Worktrees Directory preference"
        />
      </List>
    );
  }

  return (
    <List searchBarPlaceholder="Search worktrees...">
      {sortedWorktrees.map((worktree) => (
        <List.Item
          key={worktree}
          icon={Icon.Stop}
          title={worktree}
          subtitle={worktree === defaultWorktree ? "default" : undefined}
          accessories={[
            worktree === defaultWorktree ? { icon: Icon.Star, tooltip: "Default" } : {},
          ]}
          actions={
            <ActionPanel>
              <Action
                title="Stop Containers"
                icon={Icon.Stop}
                onAction={() => handleStop(worktree)}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

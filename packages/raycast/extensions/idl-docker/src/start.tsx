import { Action, ActionPanel, Icon, List, showToast, Toast } from "@raycast/api";
import { useState } from "react";
import { startContainers } from "./lib/docker";
import { listWorktrees, getDefaultWorktree, worktreeExists } from "./lib/worktrees";

export default function StartCommand() {
  const [isLoading, setIsLoading] = useState(false);
  const worktrees = listWorktrees();
  const defaultWorktree = getDefaultWorktree();

  // Sort worktrees with default first
  const sortedWorktrees = [...worktrees].sort((a, b) => {
    if (a === defaultWorktree) return -1;
    if (b === defaultWorktree) return 1;
    return a.localeCompare(b);
  });

  async function handleStart(worktree: string) {
    if (!worktreeExists(worktree)) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Worktree not found",
        message: `Directory for "${worktree}" does not exist`,
      });
      return;
    }

    setIsLoading(true);

    const toast = await showToast({
      style: Toast.Style.Animated,
      title: "Starting containers...",
      message: worktree,
    });

    const result = await startContainers(worktree);

    if (result.success) {
      toast.style = Toast.Style.Success;
      toast.title = "Containers started";
      toast.message = worktree;
    } else {
      toast.style = Toast.Style.Failure;
      toast.title = "Failed to start";
      toast.message = result.message;
    }

    setIsLoading(false);
  }

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
    <List isLoading={isLoading} searchBarPlaceholder="Search worktrees...">
      {sortedWorktrees.map((worktree) => (
        <List.Item
          key={worktree}
          icon={Icon.Play}
          title={worktree}
          subtitle={worktree === defaultWorktree ? "default" : undefined}
          accessories={[
            worktree === defaultWorktree ? { icon: Icon.Star, tooltip: "Default" } : {},
          ]}
          actions={
            <ActionPanel>
              <Action
                title="Start Containers"
                icon={Icon.Play}
                onAction={() => handleStart(worktree)}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

import {
  Action,
  ActionPanel,
  Detail,
  getPreferenceValues,
  Icon,
  List,
} from "@raycast/api";
import { useEffect, useState } from "react";
import {
  filterPrompts,
  loadPrompts,
  Prompt,
  resolveVault,
} from "./lib/prompts";

function PromptActions({ prompt }: { prompt: Prompt }) {
  return (
    <ActionPanel>
      <Action.CopyToClipboard
        title="Copy Implementation Prompt"
        content={prompt.text}
      />
      <Action.Push
        title="Preview Prompt"
        target={
          <Detail
            markdown={prompt.text}
            actions={
              <ActionPanel>
                <Action.CopyToClipboard
                  title="Copy Implementation Prompt"
                  content={prompt.text}
                />
              </ActionPanel>
            }
          />
        }
      />
      <Action.OpenInBrowser
        title="Open Note in Obsidian"
        url={`obsidian://open?path=${encodeURIComponent(prompt.path)}`}
      />
    </ActionPanel>
  );
}

export default function SearchPrompts() {
  const { vaultPath = "" } = getPreferenceValues<{ vaultPath?: string }>();
  const [prompts, setPrompts] = useState<Prompt[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  useEffect(() => {
    let active = true;
    resolveVault(vaultPath)
      .then(loadPrompts)
      .then((found) => {
        if (active) setPrompts(found);
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
  }, [vaultPath]);
  const visible = filterPrompts(prompts, query);
  return (
    <List
      isLoading={loading}
      filtering={false}
      onSearchTextChange={setQuery}
      searchBarPlaceholder="Search plan titles, source paths, or prompt text…"
    >
      {visible.length === 0 && (
        <List.EmptyView
          icon={Icon.Document}
          title={
            error
              ? "Cannot load implementation prompts"
              : query
                ? "No matching prompts"
                : "No implementation prompts yet"
          }
          description={
            error ||
            "Notes are read from Projects/Engineering/Prompts in your Obsidian vault."
          }
        />
      )}
      {visible.map((prompt) => (
        <List.Item
          key={prompt.path}
          icon={Icon.Document}
          title={prompt.title}
          subtitle={prompt.sourceFile}
          accessories={[
            { text: new Date(prompt.created).toLocaleDateString() },
          ]}
          actions={<PromptActions prompt={prompt} />}
        />
      ))}
    </List>
  );
}

import { Action, ActionPanel, Form } from "@raycast/api";

interface ProfileFormProps {
  actionTitle: string;
  onSubmit: (profiles: string[]) => void | Promise<void>;
}

export function ProfileForm({ actionTitle, onSubmit }: ProfileFormProps) {
  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm
            title={actionTitle}
            onSubmit={({ profiles }: { profiles: string }) =>
              onSubmit(
                profiles
                  .split(",")
                  .map((profile) => profile.trim())
                  .filter(Boolean),
              )
            }
          />
        </ActionPanel>
      }
    >
      <Form.TextField
        id="profiles"
        title="Additional Profiles"
        placeholder="queue"
        info="Enable the queue services. sftp is always enabled."
      />
    </Form>
  );
}

import {
  Action,
  ActionPanel,
  Detail,
  getPreferenceValues,
  Icon,
} from "@raycast/api";
import { execFile } from "child_process";
import { existsSync } from "fs";
import { promisify } from "util";
import { useCallback, useEffect, useRef, useState } from "react";
import { cliError, needsSsoLogin } from "./lib/aws-sso";

const execFileAsync = promisify(execFile);
const aws = existsSync("/opt/homebrew/bin/aws")
  ? "/opt/homebrew/bin/aws"
  : "aws";

type LoginState = {
  phase: "checking" | "opening-browser" | "signed-in" | "error";
  message: string;
};

async function runAws(args: string[], timeout: number): Promise<void> {
  await execFileAsync(aws, args, {
    timeout,
    maxBuffer: 1024 * 1024,
    env: { ...process.env, AWS_PAGER: "" },
  });
}

export default function GenaiAwsSso() {
  const { awsSsoProfile } = getPreferenceValues<{ awsSsoProfile: string }>();
  const profile = awsSsoProfile?.trim() || "genai";
  const [state, setState] = useState<LoginState>({
    phase: "checking",
    message: "Checking AWS credentials…",
  });
  const started = useRef(false);
  const busy = useRef(false);

  const check = useCallback(async () => {
    await runAws(
      ["sts", "get-caller-identity", "--profile", profile, "--no-cli-pager"],
      30000,
    );
  }, [profile]);

  const login = useCallback(async () => {
    if (busy.current) return;
    busy.current = true;
    setState({
      phase: "opening-browser",
      message:
        "AWS is opening your default browser. Complete the sign-in there; this command will update when it finishes.",
    });
    try {
      // AWS CLI's default PKCE flow opens the browser. Do not use --no-browser.
      await runAws(
        ["sso", "login", "--profile", profile, "--no-cli-pager"],
        600000,
      );
      await check();
      setState({
        phase: "signed-in",
        message: `AWS credentials for ${profile} are ready.`,
      });
    } catch (cause) {
      setState({ phase: "error", message: cliError(cause) });
    } finally {
      busy.current = false;
    }
  }, [check, profile]);

  const checkThenLogin = useCallback(async () => {
    if (busy.current) return;
    busy.current = true;
    setState({ phase: "checking", message: "Checking AWS credentials…" });
    try {
      await check();
      setState({
        phase: "signed-in",
        message: `AWS credentials for ${profile} are ready. No browser sign-in was needed.`,
      });
    } catch (cause) {
      const error = cliError(cause);
      if (needsSsoLogin(error)) {
        busy.current = false;
        await login();
        return;
      }
      setState({ phase: "error", message: error });
    } finally {
      busy.current = false;
    }
  }, [check, login, profile]);

  useEffect(() => {
    if (started.current) return;
    started.current = true;
    void checkThenLogin();
  }, [checkThenLogin]);

  const title =
    state.phase === "signed-in"
      ? "Signed in to AWS"
      : state.phase === "error"
        ? "AWS sign-in needs attention"
        : state.phase === "opening-browser"
          ? "Complete AWS sign-in in your browser"
          : "Checking AWS sign-in";

  return (
    <Detail
      isLoading={
        state.phase === "checking" || state.phase === "opening-browser"
      }
      markdown={`# ${title}\n\n**Profile:** ${profile}\n\n${state.message}`}
      actions={
        <ActionPanel>
          <Action
            title="Check Credentials"
            icon={Icon.ArrowClockwise}
            onAction={() => void checkThenLogin()}
          />
          <Action
            title="Sign in Again"
            icon={Icon.Globe}
            onAction={() => void login()}
          />
        </ActionPanel>
      }
    />
  );
}

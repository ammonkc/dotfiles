export function needsSsoLogin(error: string): boolean {
  return [
    /error loading sso token/i,
    /sso session[^\n]*(expired|invalid)/i,
    /sso token[^\n]*(expired|invalid|does not exist)/i,
    /token for session[^\n]*does not exist/i,
    /token has expired and refresh failed/i,
    /unauthorizedssotokenerror/i,
  ].some((pattern) => pattern.test(error));
}

export function cliError(cause: unknown): string {
  if (cause instanceof Error) {
    const stderr = (cause as Error & { stderr?: string }).stderr;
    return (stderr?.trim() || cause.message).trim();
  }
  return String(cause);
}

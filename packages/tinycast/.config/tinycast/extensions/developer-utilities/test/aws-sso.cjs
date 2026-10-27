const assert = require("node:assert/strict");
const { needsSsoLogin } = require("../dist/lib/aws-sso.js");

for (const error of [
  "Error loading SSO Token: Token for session session1 does not exist",
  "The SSO session associated with this profile has expired or is otherwise invalid.",
  "Token has expired and refresh failed",
]) {
  assert.equal(needsSsoLogin(error), true, error);
}

for (const error of [
  "Could not connect to the endpoint URL",
  "The config profile (genai) could not be found",
  "AccessDenied when calling GetCallerIdentity",
]) {
  assert.equal(needsSsoLogin(error), false, error);
}

console.log("AWS SSO error classification passed.");

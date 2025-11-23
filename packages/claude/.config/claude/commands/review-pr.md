---
description: Perform comprehensive code review of changes in current git branch
allowed-tools: mcp__git__git_branch, mcp__git__git_log, mcp__git__git_diff, mcp__git__git_show, mcp__git__git_status, mcp__acp__Read, mcp__acp__Bash, Grep, Glob, TodoWrite
argument-hint: [optional branch name]
---

**Usage:**

```
/review:pr
```

## Context

-   Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"`
-   Your commits only: !`git log --author="$(git config user.name)" --no-merges --oneline | wc -l | tr -d ' '` commits by you
-   Git status: !`git status --porcelain | wc -l | tr -d ' '` files changed
-   Latest commit: !`git log -1 --oneline || echo "no commits"`
-   Your latest commit: !`git log --author="$(git config user.name)" --no-merges -1 --oneline 2>/dev/null || echo "no commits by you"`
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`

## Task

Perform a comprehensive code review of changes in the current git branch ($ARGUMENTS if specified, otherwise current branch).

### Steps:

1. **Identify Current Context**

    - Get the current branch name and recent commits
    - Focus ONLY on commits authored by you, ignore merge commits from upstream branches
    - Use `git log --author="$(git config user.name)" --no-merges` to identify your commits
    - Examine git diff against main/base branch to understand scope of YOUR changes only
    - Determine what files were modified by your commits specifically

2. **Analyze Code Changes**

    - Use git diff against main branch to examine all modified files by your commits
    - **Exclude upstream/merge commits**: Only review code changes you authored
    - Focus on the actual changes you made, not the entire codebase or merged changes
    - Read modified files to understand context of your specific contributions

3. **Comprehensive Review Criteria**
   Review the code changes for:

    - **Bug Prevention**: Error handling, edge cases, null checks
    - **Performance**: Prefer `isset()` over `in_array()`, efficient queries, caching
    - **Security**: Input validation, SQL injection prevention, XSS protection, authentication/authorization
    - **Laravel/PHP Best Practices**: Follow guidelines from @laravel-php-guidelines.md
    - **Code Quality**: Readability, maintainability, SOLID principles
    - **Test Coverage**: Identify areas needing tests, suggest test scenarios
    - **Project Conventions**: Adherence to standards in @CLAUDE.md
    - **Database**: Proper migrations, relationships, indexing considerations
    - **API Design**: RESTful principles, proper status codes, validation

4. **Provide Structured Output**
   Format your review as follows:

```markdown
# Code Review: [Branch Name] - [Brief Description]

## ✅ Strengths

-   [List positive aspects of the changes]
-   [Performance improvements identified]
-   [Good practices followed]

## 🟡 Observations & Potential Improvements

1. **[Category/File]: [Issue Title]**
    - **Description**: [What was observed]
    - **Recommendation**: [Specific suggestion with code example if applicable]
    - **Priority**: Low/Medium/High

## 🔴 Issues Requiring Attention

1. **[Category/File]: [Critical Issue]**
    - **Description**: [What's wrong and why it's critical]
    - **Impact**: [Potential consequences]
    - **Solution**: [Specific fix with code example]
    - **Priority**: High/Critical

## 📊 Code Quality Metrics

| Metric          | Score      | Notes      |
| --------------- | ---------- | ---------- |
| Bug Prevention  | ⭐⭐⭐⭐⭐ | [Comments] |
| Performance     | ⭐⭐⭐⭐⭐ | [Comments] |
| Security        | ⭐⭐⭐⭐⭐ | [Comments] |
| Maintainability | ⭐⭐⭐⭐⭐ | [Comments] |
| Test Coverage   | ⭐⭐⭐⭐⭐ | [Comments] |

## 🎯 Prioritized Action Items

1. [Most critical issues first]
2. [Medium priority items]
3. [Nice-to-have improvements]

## 🔍 Security Analysis

-   [Authentication/Authorization considerations]
-   [Input validation review]
-   [Data protection compliance]

## 📝 Final Verdict

⭐⭐⭐⭐⭐ **[APPROVE/REQUEST CHANGES/COMMENT]**

**Overall Assessment**: [1-2 sentence summary]

**Recommendation**: [Specific next steps]
```

## Success Criteria

-   **Comprehensive Analysis**: All modified files examined and changes understood
-   **Structured Output**: Review follows the specified markdown format
-   **Actionable Feedback**: Specific recommendations with code examples where applicable
-   **Risk Assessment**: Security, performance, and maintainability issues identified
-   **Laravel Standards**: Compliance with project coding standards verified

## Commit Filtering Strategy

**Review ONLY the author's commits, ignore upstream merges:**

- Use `git log --author="$(git config user.name)" --no-merges` to identify commits to review
- Use `git diff main...HEAD` to see all changes, but focus analysis on files modified by author commits
- Exclude any merge commits or commits from other authors from the review scope
- If you encounter merge conflicts or upstream changes, mention them but don't review their content

## Important Notes

-   **Focus exclusively on the author's commits** - ignore merge commits from upstream branches
-   Review only changes in this PR/branch authored by the current user, not the entire codebase
-   Provide actionable feedback with specific examples for the author's code only
-   Consider the Laravel 9 context and project-specific patterns
-   Be thorough but constructive in your feedback
-   Always suggest concrete improvements rather than just pointing out problems
-   If unsure whether a change was authored by the user, use git blame or git log to verify

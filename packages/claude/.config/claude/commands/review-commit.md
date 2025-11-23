---
description: Perform code review of a specific git commit
allowed-tools: mcp__git__git_show, mcp__git__git_log, mcp__git__git_diff, mcp__acp__Read, Grep, Glob, TodoWrite
argument-hint: <commit SHA>
---

**Usage:**

```
/review:commit abc123def
```

## Context

-   Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"`
-   Recent commits: !`git log --oneline -3 2>/dev/null || echo "no commits"`
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`

## Task

Perform comprehensive code review of a specific git commit ($ARGUMENTS).

### Steps:

1. **Validate Input**

    - Ensure a commit SHA is provided
    - If no SHA provided, ask the user to specify one

2. **Analyze Specific Commit**

    - Use `git show [SHA]` to get commit details and changes
    - Identify all files modified in that commit
    - Read the commit message for context
    - Analyze the diff to understand what changed

3. **Focused Review Criteria**
   Review the commit changes for:

    - **Breaking Changes**: API changes, database schema changes, config changes
    - **Consistency**: Follows existing codebase patterns and conventions
    - **Completeness**: All related changes included (tests, docs, migrations)
    - **Code Quality**: Follows Laravel/PHP best practices from @laravel-php-guidelines.md
    - **Security**: Any security implications of the changes
    - **Performance**: Impact on system performance
    - **Dependencies**: New dependencies or version changes

4. **Provide Structured Output**
   Format your review as follows:

```markdown
# Commit Review: [SHA] - [Commit Message]

## 📋 Commit Summary

-   **Author**: [Author name]
-   **Date**: [Commit date]
-   **Files Changed**: [Number] files
-   **Lines**: +[added] -[removed]

## 📝 Changes Overview

-   [Brief summary of what the commit does]
-   [Key files/components affected]

## ✅ Positive Aspects

-   [Good practices followed]
-   [Well-implemented features]
-   [Proper testing/documentation]

## ⚠️ Concerns & Issues

1. **[Category]: [Issue Title]**
    - **Description**: [What's concerning]
    - **Impact**: [Potential consequences]
    - **Recommendation**: [Suggested fix]

## 🔍 Breaking Changes Analysis

-   [List any breaking changes found]
-   [Impact assessment]
-   [Migration/upgrade path needed]

## 📊 Completeness Check

| Aspect                | Status | Notes      |
| --------------------- | ------ | ---------- |
| Code Changes          | ✅/❌  | [Comments] |
| Tests Added/Updated   | ✅/❌  | [Comments] |
| Documentation         | ✅/❌  | [Comments] |
| Database Migrations   | ✅/❌  | [Comments] |
| Configuration Updates | ✅/❌  | [Comments] |

## 🎯 Action Items

1. [Most critical issues to address]
2. [Documentation needs]
3. [Testing gaps to fill]

## 📝 Overall Assessment

**Commit Quality**: ⭐⭐⭐⭐⭐ (1-5 stars)

**Recommendation**: [APPROVE/REQUEST CHANGES/NEEDS ATTENTION]

**Summary**: [1-2 sentence overall assessment]
```

## Success Criteria

-   **Complete Commit Analysis**: All changes in the commit thoroughly reviewed
-   **Breaking Changes Identified**: Any API or schema changes flagged and assessed
-   **Quality Assessment**: Code quality, completeness, and consistency evaluated
-   **Actionable Feedback**: Specific recommendations provided for improvements
-   **Risk Assessment**: Security, performance, and compatibility issues identified

## Important Notes

-   Focus specifically on the changes in this commit, not the entire codebase
-   Pay special attention to breaking changes that might affect other parts of the system
-   Consider the commit message quality and whether it accurately describes the changes
-   Look for missing pieces (tests, docs, related changes)
-   Evaluate whether the commit is atomic and focused on a single logical change

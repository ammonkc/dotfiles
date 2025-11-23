---
description: Perform focused code review on a specific file
allowed-tools: mcp__acp__Read, Grep, Glob, TodoWrite, mcp__git__git_log
argument-hint: [optional file path]
---

**Usage:**

```
/review:file
```

## Context

-   Working directory: !`pwd`
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`
-   PHP version: !`php -v | head -1 || echo "php not found"`

## Task

Perform comprehensive code review of a specific file ($ARGUMENTS if provided, otherwise ask user).

### Steps:

1. **Identify Target File**

    - If a file path is provided, use that file
    - If no file specified, ask the user which file they want reviewed
    - Read the entire file to understand its complete context

2. **Comprehensive File Analysis**
   Review the file for:

    - **Code Style**: Adherence to Laravel/PHP guidelines from @laravel-php-guidelines.md
    - **Architecture**: Proper class structure, separation of concerns
    - **Security**: Input validation, authentication, authorization, encryption
    - **Performance**: Efficient algorithms, database queries, memory usage
    - **Maintainability**: Code readability, documentation, naming conventions
    - **Testing**: Test coverage opportunities, testable design
    - **Laravel Best Practices**: Proper use of Eloquent, middleware, services

3. **Provide Structured Output**
   Format your review as follows:

```markdown
# File Review: [filename]

## 📁 File Overview

-   **Type**: [Controller/Model/Service/etc.]
-   **Purpose**: [Brief description of file's responsibility]
-   **Lines of Code**: [Approximate count]
-   **Complexity**: [Low/Medium/High]

## ✅ Strengths

-   [Good practices implemented]
-   [Well-structured code sections]
-   [Proper design patterns used]

## 🔍 Code Quality Analysis

### Structure & Organization

-   [Class organization assessment]
-   [Method ordering and grouping]
-   [Namespace and import usage]

### Security Review

-   [Input validation coverage]
-   [Authentication/authorization checks]
-   [Data sanitization and encryption]

### Performance Considerations

-   [Database query efficiency]
-   [Algorithm complexity]
-   [Memory usage patterns]

## ⚠️ Issues & Improvements

### 🔴 Critical Issues

1. **[Issue Category]: [Problem Title]**
    - **Line(s)**: [Specific line numbers]
    - **Description**: [What's wrong]
    - **Risk**: [Security/Performance/Maintenance risk]
    - **Fix**: [Specific solution with code example]

### 🟡 Potential Improvements

1. **[Category]: [Improvement Title]**
    - **Line(s)**: [Specific line numbers]
    - **Current**: [How it's currently done]
    - **Suggestion**: [Proposed improvement]
    - **Benefit**: [Why this improves the code]

## 📊 Code Metrics

| Aspect          | Rating     | Comments     |
| --------------- | ---------- | ------------ |
| Readability     | ⭐⭐⭐⭐⭐ | [Assessment] |
| Maintainability | ⭐⭐⭐⭐⭐ | [Assessment] |
| Security        | ⭐⭐⭐⭐⭐ | [Assessment] |
| Performance     | ⭐⭐⭐⭐⭐ | [Assessment] |
| Testing         | ⭐⭐⭐⭐⭐ | [Assessment] |

## 🎯 Recommended Actions

### High Priority

1. [Most critical fixes needed]
2. [Security improvements required]
3. [Performance optimizations]

### Medium Priority

1. [Code quality improvements]
2. [Refactoring opportunities]
3. [Documentation additions]

### Low Priority

1. [Style improvements]
2. [Nice-to-have optimizations]

## 🧪 Testing Recommendations

-   [Missing test scenarios]
-   [Test improvement suggestions]
-   [Mock/stub opportunities]

## 📝 Overall Assessment

**File Quality Score**: ⭐⭐⭐⭐⭐ (1-5 stars)

**Primary Concerns**: [Top 1-2 issues to address]

**Recommendation**: [Overall verdict and next steps]
```

## Success Criteria

-   **Comprehensive File Analysis**: Complete review of code structure, security, and performance
-   **Line-Specific Feedback**: Detailed recommendations with exact line references
-   **Quality Metrics**: Quantified assessment of code quality aspects
-   **Actionable Improvements**: Prioritized list of concrete enhancements
-   **Testing Strategy**: Specific testing recommendations for the file

## Important Notes

-   Provide line-specific feedback when possible
-   Focus on actionable improvements with concrete examples
-   Consider the file's role in the larger application context
-   Balance thoroughness with practicality
-   Reference Laravel and project-specific conventions
-   Suggest specific refactoring opportunities where beneficial

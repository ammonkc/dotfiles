---
description: Perform performance analysis of code changes or specified files
allowed-tools: mcp__git__git_branch, mcp__git__git_diff, mcp__git__git_status, mcp__acp__Read, mcp__acp__Bash, Grep, Glob, TodoWrite
argument-hint: [optional file paths or 'current' for git changes]
---

## Context

-   Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"`
-   Modified files: !`git status --porcelain | wc -l | tr -d ' '` changes
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`
-   PHP version: !`php -v | head -1 || echo "php not found"`

## Task

Perform comprehensive performance analysis of code changes or specified files ($ARGUMENTS).

### Steps:

1. **Identify Target Code**
   - If analyzing current changes, use git commands to identify modified files
   - If analyzing specific files, focus on the requested files
   - Read the relevant code files to understand the implementation

2. **Performance Analysis Areas**
   Analyze the code for:
   - **Database Performance**:
     - N+1 query problems
     - Missing database indexes
     - Inefficient joins or subqueries
     - Lack of proper eager loading
     - Missing query optimization

   - **Code Efficiency**:
     - Inefficient loops or array operations
     - Unnecessary computations in loops
     - Memory-intensive operations
     - Repeated function calls that could be cached
     - Inefficient string operations

   - **Laravel-Specific Optimizations**:
     - Missing query scopes
     - Inefficient Eloquent usage
     - Missing caching opportunities
     - Improper use of collections vs arrays
     - Missing pagination for large datasets

3. **Provide Structured Output**
   Format your analysis as follows:

```markdown
# Performance Analysis Report

## 📊 Performance Issues Found

### 🔴 Critical Performance Issues
1. **[File/Function]: [Issue Title]**
   - **Problem**: [Description of the performance issue]
   - **Impact**: [Expected performance impact]
   - **Solution**: [Specific optimization with code example]
   - **Estimated Improvement**: [Performance gain estimate]

### 🟡 Optimization Opportunities
1. **[File/Function]: [Optimization Title]**
   - **Current Implementation**: [Brief description]
   - **Suggested Optimization**: [Improvement with code example]
   - **Benefits**: [Expected performance benefits]

## 🚀 Recommendations

### Database Optimizations
- [List database-specific improvements]
- [Index recommendations]
- [Query optimization suggestions]

### Code Optimizations
- [Algorithm improvements]
- [Memory usage optimizations]
- [Caching strategies]

### Laravel Best Practices
- [Eloquent optimizations]
- [Collection usage improvements]
- [Service optimization suggestions]

## 📈 Implementation Priority
1. **High Impact, Low Effort**: [Quick wins]
2. **High Impact, High Effort**: [Major improvements]
3. **Low Impact, Low Effort**: [Nice-to-have optimizations]

## 🔍 Benchmarking Suggestions
- [Specific areas to measure before/after]
- [Performance testing recommendations]
- [Monitoring recommendations]

## 📝 Summary
**Overall Performance Assessment**: [1-2 sentence summary]
**Top Priority Action**: [Most critical improvement needed]
```

## Success Criteria

- **Comprehensive Analysis**: All target files analyzed for performance bottlenecks
- **Actionable Recommendations**: Specific optimizations with code examples
- **Impact Assessment**: Performance gains estimated for each recommendation
- **Prioritized Implementation**: Clear roadmap for performance improvements
- **Benchmarking Strategy**: Measurable testing approach provided

## Important Notes
- Focus on measurable performance improvements
- Provide specific code examples for optimizations
- Consider Laravel 9 and PHP 8.1+ specific optimizations
- Reference database query optimization patterns where applicable
- Suggest realistic benchmarking approaches
- Balance performance gains with code maintainability

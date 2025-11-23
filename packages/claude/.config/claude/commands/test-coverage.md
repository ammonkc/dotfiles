---
description: Analyze test coverage for files, classes, or current changes
allowed-tools: mcp__git__git_diff, mcp__git__git_status, mcp__acp__Read, mcp__acp__Bash, Grep, Glob, TodoWrite
argument-hint: [optional file/class path or 'current' for git changes]
---

## Context

-   Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"`
-   Modified files: !`git status --porcelain | wc -l | tr -d ' '` changes
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`
-   PHPUnit: !`[ -f vendor/bin/phpunit ] && echo "phpunit: yes" || echo "phpunit: no"`
-   Pest: !`[ -f vendor/bin/pest ] && echo "pest: yes" || echo "pest: no"`

## Task

Analyze test coverage for specified target ($ARGUMENTS) or current changes if no target provided.

### Steps:

1. **Identify Target Code**
   - If analyzing current changes, use git commands to identify modified files
   - If a specific file/class is mentioned, focus on that
   - If no target specified, ask the user what they want to analyze

2. **Analyze Existing Tests**
   - Search for existing test files in the `tests/` directory
   - Look for Unit tests (`tests/Unit/`)
   - Look for Feature tests (`tests/Feature/`)
   - Look for Integration tests (`tests/Integration/`)
   - Identify any related test files

3. **Coverage Analysis**
   Evaluate test coverage for:
   - **Method Coverage**: Which methods are tested
   - **Path Coverage**: Different code paths through methods
   - **Edge Cases**: Boundary conditions and error scenarios
   - **Integration Points**: API endpoints, database interactions
   - **Business Logic**: Core functionality validation
   - **Error Handling**: Exception scenarios and error conditions

4. **Provide Structured Output**
   Format your analysis as follows:

```markdown
# Test Coverage Analysis

## 📊 Coverage Overview
**Target**: [File/Class/Feature analyzed]
**Existing Tests Found**: [Number] test files
**Estimated Coverage**: [Percentage estimate based on analysis]

## 🧪 Existing Test Files
- `[test-file-path]` - [Brief description of what it tests]
- `[test-file-path]` - [Brief description of what it tests]

## ✅ Well-Covered Areas
- [Methods/features with good test coverage]
- [Scenarios that are properly tested]
- [Integration points with adequate tests]

## 🔍 Coverage Gaps Identified

### 🔴 Critical Missing Tests
1. **[Method/Feature]: [Test Gap Title]**
   - **Untested Code**: [Specific methods/paths]
   - **Risk**: [What could break without these tests]
   - **Priority**: Critical

### 🟡 Important Test Scenarios Missing
1. **[Category]: [Test Scenario]**
   - **Current Gap**: [What's not being tested]
   - **Recommended Test**: [Specific test case needed]
   - **Priority**: High/Medium

### 🟢 Nice-to-Have Test Improvements
1. **[Category]: [Enhancement]**
   - **Current State**: [Existing test limitations]
   - **Improvement**: [How to enhance coverage]
   - **Priority**: Low

## 📝 Recommended Test Cases

### Unit Tests Needed
```php
// Example test structure for missing unit tests
class [ClassName]Test extends TestCase
{
    /** @test */
    public function [descriptive_test_name]()
    {
        // Arrange
        // Act
        // Assert
    }
}
```

### Feature Tests Needed
```php
// Example feature test for missing integration coverage
class [FeatureName]Test extends TestCase
{
    /** @test */
    public function [test_scenario_description]()
    {
        // Setup
        // Execute
        // Verify
    }
}
```

### Edge Cases to Test
1. **[Scenario]**: [Test case description]
2. **[Error Condition]**: [Error handling test]
3. **[Boundary Case]**: [Boundary testing scenario]

## 🎯 Test Implementation Priority

### Phase 1: Critical Coverage (Immediate)
- [ ] [Most important missing tests]
- [ ] [Core functionality validation]
- [ ] [Security-critical paths]

### Phase 2: Enhanced Coverage (Short-term)
- [ ] [Edge cases and error handling]
- [ ] [Integration test improvements]
- [ ] [Performance test scenarios]

### Phase 3: Comprehensive Coverage (Long-term)
- [ ] [Complete path coverage]
- [ ] [Stress testing scenarios]
- [ ] [UI/E2E test coverage]

## 🔧 Testing Recommendations

### Test Structure Improvements
- [Suggestions for test organization]
- [Mock/stub usage recommendations]
- [Test data factory improvements]

### Testing Tools & Techniques
- [PHPUnit feature usage suggestions]
- [Laravel testing helper recommendations]
- [Database testing improvements]

### Continuous Integration
- [Coverage reporting setup]
- [Automated test execution]
- [Coverage threshold recommendations]

## 📈 Coverage Metrics Goals

| Test Type | Current Est. | Target | Priority |
|-----------|-------------|--------|----------|
| Unit Tests | [%] | 90%+ | High |
| Feature Tests | [%] | 80%+ | High |
| Integration Tests | [%] | 70%+ | Medium |
| E2E Tests | [%] | 60%+ | Low |

## 📝 Next Steps
1. **Immediate Actions**: [Top 3 tests to implement first]
2. **Test File Creation**: [New test files needed]
3. **Coverage Validation**: [How to verify improved coverage]

## 🚀 Implementation Examples
[Provide specific, copy-paste ready test examples for the most critical gaps]
```

## Success Criteria

- **Coverage Assessment**: Current test coverage accurately analyzed and quantified
- **Gap Identification**: Missing test scenarios identified with priority levels
- **Implementation Roadmap**: Clear, phased approach to improving coverage
- **Quality Tests**: Focus on meaningful tests that catch real bugs
- **Maintainable Strategy**: Realistic and sustainable testing approach

## Important Notes
- Focus on meaningful tests that catch real bugs, not just coverage percentages
- Prioritize testing business logic and user-facing functionality
- Consider both positive and negative test scenarios
- Include integration testing for API endpoints and database interactions
- Suggest realistic and maintainable test approaches
- Reference existing test patterns in the codebase for consistency

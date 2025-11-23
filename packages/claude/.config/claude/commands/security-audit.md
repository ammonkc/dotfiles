---
description: Perform security-focused audit of code changes or specified files
allowed-tools: mcp__git__git_diff, mcp__git__git_status, mcp__git__git_show, mcp__acp__Read, Grep, Glob, TodoWrite
argument-hint: [optional file paths or 'current' for git changes]
---

## Context

-   Current branch: !`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"`
-   Modified files: !`git status --porcelain | wc -l | tr -d ' '` changes
-   Laravel: !`php artisan --version 2>/dev/null || echo "artisan not found"`
-   Environment: !`php artisan env 2>/dev/null || echo "unknown"`

## Task

Perform comprehensive security audit of code changes or specified files ($ARGUMENTS).

### Steps:

1. **Identify Target Code**
   - If analyzing current changes, use git commands to identify modified files
   - If analyzing specific files, focus on the requested files
   - Read the relevant code files to understand security implications

2. **Security Analysis Areas**
   Analyze the code for security vulnerabilities:

   - **Input Validation & Sanitization**:
     - SQL injection vulnerabilities
     - XSS (Cross-Site Scripting) risks
     - Command injection possibilities
     - Path traversal vulnerabilities
     - Input validation bypass opportunities

   - **Authentication & Authorization**:
     - Authentication bypass vulnerabilities
     - Authorization logic flaws
     - Session management issues
     - Privilege escalation risks
     - Missing access controls

   - **Data Protection**:
     - PII data encryption (should use EncryptedCast)
     - Sensitive data exposure
     - Data leakage through logs/errors
     - Insecure data transmission
     - Missing encryption for sensitive fields

   - **Laravel-Specific Security**:
     - CSRF protection implementation
     - Mass assignment vulnerabilities
     - Route protection gaps
     - Middleware security checks
     - OAuth2 scope validation
     - API security measures

3. **Provide Structured Output**
   Format your security audit as follows:

```markdown
# Security Audit Report

## 🔐 Executive Summary
**Security Risk Level**: [Low/Medium/High/Critical]
**Files Analyzed**: [Number] files
**Vulnerabilities Found**: [Number] issues

## 🚨 Critical Security Issues
1. **[Vulnerability Type]: [Issue Title]**
   - **Location**: [File:line]
   - **Risk Level**: Critical
   - **Description**: [Detailed explanation of the vulnerability]
   - **Attack Scenario**: [How this could be exploited]
   - **Impact**: [Potential damage/data exposure]
   - **Remediation**: [Specific fix with secure code example]

## ⚠️ High Priority Security Concerns
1. **[Vulnerability Type]: [Issue Title]**
   - **Location**: [File:line]
   - **Risk Level**: High
   - **Description**: [Security concern details]
   - **Potential Impact**: [What could happen]
   - **Fix**: [Security improvement needed]

## 🟡 Medium Priority Security Issues
1. **[Issue Type]: [Issue Title]**
   - **Location**: [File:line]
   - **Risk Level**: Medium
   - **Description**: [Security issue details]
   - **Recommendation**: [Security enhancement]

## 🔍 Security Checklist

### Input Validation & Sanitization
- [ ] SQL injection protection (parameterized queries)
- [ ] XSS prevention (proper output encoding)
- [ ] Input validation rules implemented
- [ ] File upload security measures
- [ ] Command injection prevention

### Authentication & Authorization
- [ ] Authentication mechanisms secure
- [ ] Authorization checks in place
- [ ] Session security configured
- [ ] API authentication (OAuth2/Passport)
- [ ] Multi-factor authentication support

### Data Protection
- [ ] PII data encrypted using EncryptedCast
- [ ] Sensitive data not logged
- [ ] Secure data transmission (HTTPS)
- [ ] Database credentials protected
- [ ] API keys/secrets secured

### Laravel Security Features
- [ ] CSRF protection enabled
- [ ] Mass assignment protection
- [ ] Route middleware security
- [ ] Blade template XSS protection
- [ ] File permission security

## 🛡️ Security Recommendations

### Immediate Actions Required
1. [Most critical vulnerabilities to fix]
2. [High-risk exposures to address]
3. [Authentication gaps to close]

### Security Enhancements
1. [Additional protective measures]
2. [Security monitoring improvements]
3. [Code security patterns to implement]

### Best Practices Implementation
1. [Laravel security features to enable]
2. [Security middleware to add]
3. [Encryption improvements needed]

## 📋 Compliance Considerations
- [Data protection regulation compliance (GDPR, etc.)]
- [Industry-specific security requirements]
- [Security logging and monitoring needs]

## 🔧 Remediation Code Examples
```php
// Example secure code implementations
// [Provide specific secure coding examples]
```

## 📝 Security Assessment Summary
**Overall Security Posture**: [Assessment]
**Critical Actions**: [Top 3 most important fixes]
**Timeline**: [Recommended fix prioritization]

## 🚀 Next Steps
1. **Immediate** (0-24 hours): [Critical fixes]
2. **Short-term** (1-7 days): [High priority issues]
3. **Medium-term** (1-4 weeks): [Security enhancements]
```

## Success Criteria

- **Complete Security Assessment**: All target code analyzed for vulnerabilities
- **Risk Prioritization**: Issues categorized by severity and exploitability
- **Actionable Remediation**: Specific fixes provided with secure code examples
- **Compliance Review**: Data protection and regulatory compliance assessed
- **Security Checklist**: Comprehensive security controls verification

## Important Notes
- Focus on exploitable vulnerabilities, not theoretical issues
- Provide specific, actionable remediation steps with code examples
- Consider the Laravel 9 security features and best practices
- Reference the project's EncryptedCast usage for PII data
- Include both input and output security considerations
- Evaluate API security if applicable
- Consider the complete attack surface, not just individual functions

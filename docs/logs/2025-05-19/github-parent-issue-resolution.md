# GitHub Parent Issue Resolution

Date: 2025-05-19

## 🔍 Problem Overview

We encountered an issue where parent-child relationships were properly set at the GitHub Issues level using the `addSubIssue` GraphQL mutation, but these relationships weren't appearing in the "Parent issue" field in GitHub Projects view.

The issue was identified when viewing the GitHub Project board, where several user stories had empty values in the "Parent issue" column despite having parent-child relationships set at the GitHub Issues level.

## 🧪 Investigation

We initially tried setting the parent-child relationships using our existing scripts:
- `batch-set-parent-relationships.sh`
- `assign-missing-parents.sh`

These scripts successfully created the relationships at the GitHub Issues level but did not update the "Parent issue" field in the Project view.

The documentation in `parent-issue-guide.md` suggested a limitation in the GitHub API preventing programmatic setting of the Parent issue field, stating it must be done manually.

## 💡 Solution Discovery

Upon deeper investigation of the GitHub GraphQL API documentation, we discovered that the `addSubIssue` mutation requires a special header `GraphQL-Features: sub_issues` that was missing from our implementation.

We created improved script versions:
- `set-direct-parent-improved.sh`
- `batch-set-parent-improved.sh`
- `set-missing-parents.sh`

These scripts include the required header and successfully establish parent-child relationships that appear in both GitHub Issues and GitHub Projects views.

## 🛠️ Implementation

The key addition to make parent-child relationships work was including the header in the GraphQL request:

```bash
gh api graphql \
  -H "GraphQL-Features: sub_issues" \
  -f query='
  mutation($parentId:ID!, $childId:ID!) {
    addSubIssue(input: {
      issueId: $parentId,
      subIssueId: $childId,
      replaceParent: true
    }) {
      issue { number, title }
      subIssue { number, title }
    }
  }' -f parentId="$PARENT_ID" -f childId="$CHILD_ID"
```

We successfully established parent-child relationships for all user stories that were missing parent issues in the GitHub Project view.

## 📝 Insights and Improvements

1. The GitHub GraphQL API documentation for sub-issues functionality is somewhat hidden. The requirement for the `GraphQL-Features: sub_issues` header is crucial but not prominently documented.

2. We created a formal rule in `.claude/rules/github-parent-child-relationships.md` to document this solution for future reference.

3. We established a rules repository structure in `.claude/rules/` to capture reusable solutions for similar problems.

4. We updated `CLAUDE.md` to reference the rules repository as part of our standard project documentation.

## 🔄 Related Documents

- [GitHub Parent-Child Relationships Rule](/.claude/rules/github-parent-child-relationships.md)
- [Rule Creation Policy](/.claude/rules/rule-creation-policy.md)
- [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)
- [GitHub Project Migration](/docs/logs/2025-05-17/github-project-migration.md)

---

🧭 **Navigation**: [Home](/README.md) | [Up](../README.md) | [Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)
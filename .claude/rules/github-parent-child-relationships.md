# GitHub Parent-Child Issue Relationship Rule

## Problem
When trying to set parent-child relationships between GitHub issues using the GraphQL API, you may encounter failures or inconsistencies between what's set at the GitHub Issues level versus what appears in GitHub Projects.

## Solution
The key to successfully setting parent-child relationships is to use the `addSubIssue` mutation with the required `GraphQL-Features: sub_issues` header.

### Working Example
```bash
#!/bin/bash

# Define variables
PARENT_ID="I_kwDOOrzncs63D8wW"  # GraphQL node ID for the parent issue
CHILD_ID="I_kwDOOrzncs63EcK9"   # GraphQL node ID for the child issue

# GraphQL mutation with the required header
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

### Getting Issue Node IDs
To get the GraphQL node ID for an issue:
```bash
gh issue view ISSUE_NUMBER --json id,title
```

## Common Errors

### "Field 'addSubIssue' doesn't exist on type 'Mutation'"
This error occurs when the `GraphQL-Features: sub_issues` header is missing. Always include this header.

### "Issue may not contain duplicate sub-issues"
This error indicates the parent-child relationship already exists, which is not actually an error.

## Notes
- These relationships are established at the GitHub Issues level and should propagate to GitHub Projects
- The Parent Issue field in GitHub Projects can sometimes be distinct from these relationships
- For batch operations, add a small delay (e.g., `sleep 1`) between requests to avoid rate limiting
- Always check for existing relationships before attempting to create new ones

## References
- [GitHub GraphQL API Documentation](https://docs.github.com/en/graphql)
- [GitHub Sub-issues API Documentation](https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue#creating-a-sub-issue)
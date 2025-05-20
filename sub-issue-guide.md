# GitHub Sub-Issue Guide

## 📋 Overview

This guide explains how to use GitHub's built-in sub-issue functionality to establish parent-child relationships between issues.

## 🧰 Tools and Scripts

We have created several scripts to help manage these relationships:

### 1. Create a New Sub-Issue

```bash
./scripts/create-sub-issue.sh <parent_issue_number> "Title" "Description" "label1,label2"

# Example:
./scripts/create-sub-issue.sh 1 "Implement feature X" "This is a description" "user-story,priority:high"
```

This script:
- Creates a new issue with the specified title, body, and labels
- References the parent issue in the description
- Uses GitHub's GraphQL API to establish the sub-issue relationship
- Adds the new issue to the project

### 2. Set an Existing Issue as a Sub-Issue

```bash
./scripts/add-sub-issue-graphql.sh <parent_issue_number> <child_issue_number>

# Example:
./scripts/add-sub-issue-graphql.sh 1 42
```

This script:
- Takes an existing parent and child issue
- Establishes the sub-issue relationship using GitHub's GraphQL API
- Ensures the parent-child relationship is visible in the GitHub UI

### 3. Update All Parent-Child Relationships

```bash
./scripts/update-all-sub-issues.sh
```

This script:
- Processes all known parent-child relationships
- Establishes sub-issue relationships for each pair
- Reports success and failure counts

## 🏷️ Benefits of Using Sub-Issues

GitHub's built-in sub-issue functionality offers several advantages:

1. **Official Support**: Uses GitHub's official GraphQL API
2. **UI Integration**: Relationships appear in the standard GitHub interface
3. **Project Fields**: The built-in "Parent issue" and "Sub-issue progress" fields work automatically
4. **Tracking**: Progress of child issues is reflected in the parent

## 📊 Viewing Sub-Issues

You can view sub-issues in several ways:

1. **Issue Page**: Visit a parent issue to see all sub-issues listed
2. **Project Views**: 
   - Group by "Parent issue" to see hierarchical organization
   - Sort by "Parent issue" to keep related items together
   - Filter by "Parent issue" to focus on specific epics

## 🔄 Technical Details

The sub-issue functionality is implemented using GitHub's GraphQL API:

```graphql
mutation($parentId:ID!, $childId:ID!) {
  addSubIssue(input: {
    issueId: $parentId,
    subIssueId: $childId
  }) {
    issue {
      number
      title
    }
    subIssue {
      number
      title
    }
  }
}
```

This mutation establishes the parent-child relationship that is recognized throughout GitHub's systems.

## 🔗 Related Information

- [GitHub Documentation on Sub-Issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues#sub-issues)
- [GraphQL API Reference](https://docs.github.com/en/graphql/reference/mutations#addsubissue)

---

🧭 **Navigation**: [Home](/README.md) | [Architecture Documentation](/docs/architecture/README.md)
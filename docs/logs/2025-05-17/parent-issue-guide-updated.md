# Parent Issue Field Configuration Guide - Updated

Date: 2025-05-17

## 📋 Overview

This updated guide provides additional instructions for setting the Parent issue field values in GitHub Projects, including our exploration of custom fields as an alternative approach.

## 🔄 Parent-Child Relationships

GitHub Projects provides a built-in "Parent issue" field for establishing hierarchical relationships between issues. This field is useful for:

- Connecting user stories to epics
- Tracking dependencies between issues
- Creating task hierarchies
- Enabling roll-up progress tracking

## 🚫 API Limitations & Attempted Solutions

Despite extensive research and experimentation, we've concluded that programmatically setting the parent-child relationships in GitHub Projects is not currently possible:

1. **GraphQL API for ProjectV2 fields**: The GitHub GraphQL API doesn't support setting the built-in Parent issue field
   - Error: "InputObject 'ProjectV2FieldValue' doesn't accept argument 'projectV2Item'"

2. **REST API for Sub-issues**: The documented REST API endpoints for sub-issues return 404 errors
   - Error: "The provided sub-issue does not exist"

3. **GraphQL Issue Relations**: The mutation for adding issue relationships doesn't exist
   - Error: "Field 'addIssueRelation' doesn't exist on type 'Mutation'"

4. **Custom Fields Approach**: We attempted to create a custom field to track parent-child relationships
   - Finding: GitHub API doesn't support creating custom fields programmatically

## 💡 Recommended Workflow

Based on our investigation, we recommend the following workflow for managing parent-child relationships:

### 1. Create Issues with Parent References

Use our script to create issues with references to their parent in the body:

```bash
./scripts/add-sub-issue.sh <parent_issue_number> "Child Title" "Description" "label1,label2"
```

This script:
- Creates a child issue with a reference to the parent
- Adds both issues to the project
- Includes instructions for manual Parent field setup

### 2. Manual Parent Field Configuration

After creating issues, set the Parent issue field manually:

1. Go to your GitHub Project: https://github.com/users/o2alexanderfedin/projects/2
2. For each child issue:
   - Click on the issue to open its details panel
   - Find the "Parent issue" field in the side panel
   - Type "#" and select the appropriate parent epic
   - Save the change

### 3. Creating Views with Parent Grouping

Once parent relationships are set, create useful views:

1. Create a "Stories by Parent" view
   - Group by: Parent issue
   - Sort by: Priority, Status
   - This view provides a hierarchical overview of your issues

2. Create a "Progress by Epic" view
   - Filter: Type = Epic
   - Show the "Sub-issue progress" field
   - This view shows completion status of epics based on their child issues

## 🔮 Future Possibilities

GitHub continues to improve their API. We'll monitor for changes that might enable programmatic parent-child relationships:

1. Expansion of the REST API for sub-issues
2. Addition of parent field support in the GraphQL API
3. Support for creating and configuring custom fields via API

Until such improvements are available, the manual configuration process described above is the recommended approach.

## 🔄 Related Documents

- [Original Parent Issue Guide](/docs/logs/2025-05-17/parent-issue-guide.md)
- [GitHub Project Migration](/docs/logs/2025-05-17/github-project-migration.md)
- [GitHub Project Setup Guide](/docs/logs/2025-05-17/github-project-setup-guide.md)

---

🧭 **Navigation**: [Home](/README.md) | [Up](../README.md) | [GitHub Project Setup Guide](/docs/logs/2025-05-17/github-project-setup-guide.md)
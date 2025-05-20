# Parent-Child Relationship Scripts

This directory contains scripts for managing parent-child relationships between GitHub issues.

## Scripts

| Script | Description |
|--------|-------------|
| `set-parent.sh` | Sets parent relationship for a single child issue |
| `batch-set-parents.sh` | Sets parent relationships for multiple issues |
| `add-sub-issue.sh` | Adds an existing issue as a sub-issue of another |
| `create-sub-issue.sh` | Creates a new issue as a sub-issue |
| `set-missing-parents.sh` | Sets parent relationships for issues missing parents |
| `update-all-sub-issues.sh` | Updates all sub-issues in the repository |

## Usage

### Setting a Single Parent Relationship

```bash
./set-parent.sh <parent_issue_number> <child_issue_number>
```

### Setting Multiple Parent Relationships

```bash
./batch-set-parents.sh
```

This script uses predefined relationships in the script file. Edit the `RELATIONSHIPS` array to customize.

### Adding a Sub-Issue

```bash
./add-sub-issue.sh <parent_issue_number> <sub_issue_number>
```

## Important Notes

- The GitHub GraphQL API requires the `GraphQL-Features: sub_issues` header for parent-child operations
- These scripts set the relationship at the GitHub Issues level, which should propagate to GitHub Projects

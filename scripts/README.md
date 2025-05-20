# Project Scripts

This directory contains utility scripts for GitHub Project management and automation.

## Directory Structure

- [migration/](./migration/) - GitHub Project migration scripts
- [parent-child/](./parent-child/) - Parent-child relationship management scripts
- [fields/](./fields/) - Field management scripts
- [utilities/](./utilities/) - Helper and utility scripts
- [deprecated/](./deprecated/) - Outdated or superseded scripts

## GitHub Token Requirements

**Important**: GitHub Project API requires special token scope:

```bash
# Refresh your GitHub token with project scope
gh auth refresh -h github.com -s project

# Verify token has project scope
gh auth status
```

## Common Workflows

### Complete Project Migration

1. Create a GitHub Project:
   ```bash
   ./migration/create-github-project.sh
   ```

2. Add all issues to the project:
   ```bash
   ./migration/add-issues.sh
   ```

3. Set up custom fields:
   ```bash
   ./fields/create-fields.sh
   ./fields/set-types.sh
   ./fields/set-components.sh
   ```

4. Set parent-child relationships:
   ```bash
   ./parent-child/batch-set-parents.sh
   ```

### Setting Parent-Child Relationships

To set parent-child relationships between issues:

```bash
# Set a single relationship
./parent-child/set-parent.sh <parent_issue_number> <child_issue_number>

# Set multiple relationships from a predefined list
./parent-child/batch-set-parents.sh
```

### Managing Fields

```bash
# Create all fields
./fields/create-fields.sh

# Set Type field values
./fields/set-types.sh

# Set Component field values
./fields/set-components.sh
```

## Troubleshooting

If you encounter issues:

1. **Authentication errors**: Ensure you've refreshed your token with the project scope
2. **Rate limiting**: Add delays between API calls or break operations into smaller batches
3. **Field creation failures**: Check if fields already exist in the project
4. **Permission issues**: Verify you have admin access to the repository and project

## Documentation

For detailed information on the GitHub Project migration process, see:
- [GitHub Project Migration](/docs/logs/2025-05-17/github-project-migration.md)
- [Parent Issue Field Configuration Guide](/docs/logs/2025-05-17/parent-issue-guide.md)
- [GitHub Parent Issue Resolution](/docs/logs/2025-05-19/github-parent-issue-resolution.md)

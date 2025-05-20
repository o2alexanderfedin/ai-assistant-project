#!/bin/bash

# Title: Script Cleanup and Organization
# Description: Reorganizes scripts into logical directories and standardizes naming using move operations
# Usage: ./cleanup.sh
# Author: AI Assistant Team
# Date: 2025-05-19
# Last Updated: 2025-05-19

# ----------- CONFIG ----------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# ----------- FUNCTIONS ----------- #
create_directories() {
  echo "Creating directory structure..."
  mkdir -p "$BASE_DIR/migration" \
           "$BASE_DIR/parent-child" \
           "$BASE_DIR/fields" \
           "$BASE_DIR/utilities" \
           "$BASE_DIR/deprecated"
  
  echo "✅ Directory structure created"
}

move_migration_scripts() {
  echo "Moving migration scripts..."
  
  # Core migration scripts
  mv_with_rename "$BASE_DIR/add-all-issues-to-project.sh" "$BASE_DIR/migration/add-issues.sh" 
  mv_with_rename "$BASE_DIR/add-missing-user-stories.sh" "$BASE_DIR/migration/add-missing-stories.sh" 
  mv_with_rename "$BASE_DIR/migrate-issues.sh" "$BASE_DIR/migration/migrate-issues.sh" 
  mv_with_rename "$BASE_DIR/migrate-all-comments.sh" "$BASE_DIR/migration/migrate-comments.sh" 
  mv_with_rename "$BASE_DIR/simple_migration.py" "$BASE_DIR/migration/simple-migration.py" 
  mv_with_rename "$BASE_DIR/batch_migration.py" "$BASE_DIR/migration/batch-migration.py" 
  mv_with_rename "$BASE_DIR/complete_migration.py" "$BASE_DIR/migration/complete-migration.py" 
  mv_with_rename "$BASE_DIR/comprehensive_migration.py" "$BASE_DIR/migration/comprehensive-migration.py" 
  mv_with_rename "$BASE_DIR/migrate.py" "$BASE_DIR/migration/migrate.py" 
  
  echo "✅ Migration scripts moved"
}

move_parent_child_scripts() {
  echo "Moving parent-child relationship scripts..."
  
  # Parent-child scripts
  mv_with_rename "$BASE_DIR/set-direct-parent-improved.sh" "$BASE_DIR/parent-child/set-parent.sh" 
  mv_with_rename "$BASE_DIR/batch-set-parent-improved.sh" "$BASE_DIR/parent-child/batch-set-parents.sh" 
  mv_with_rename "$BASE_DIR/add-sub-issue-graphql.sh" "$BASE_DIR/parent-child/add-sub-issue.sh" 
  mv_with_rename "$BASE_DIR/create-sub-issue.sh" "$BASE_DIR/parent-child/create-sub-issue.sh" 
  mv_with_rename "$BASE_DIR/set-missing-parents.sh" "$BASE_DIR/parent-child/set-missing-parents.sh" 
  mv_with_rename "$BASE_DIR/update-all-sub-issues.sh" "$BASE_DIR/parent-child/update-all-sub-issues.sh" 
  
  echo "✅ Parent-child scripts moved"
}

move_field_scripts() {
  echo "Moving field management scripts..."
  
  # Field management scripts
  mv_with_rename "$BASE_DIR/create-fields.sh" "$BASE_DIR/fields/create-fields.sh" 
  mv_with_rename "$BASE_DIR/create-component-field.sh" "$BASE_DIR/fields/create-component-field.sh" 
  mv_with_rename "$BASE_DIR/create-epic-field.sh" "$BASE_DIR/fields/create-epic-field.sh" 
  mv_with_rename "$BASE_DIR/update-component-values.sh" "$BASE_DIR/fields/set-components.sh" 
  mv_with_rename "$BASE_DIR/update_missing_components.py" "$BASE_DIR/fields/update-missing-components.py" 
  mv_with_rename "$BASE_DIR/set-types-direct.sh" "$BASE_DIR/fields/set-types.sh" 
  mv_with_rename "$BASE_DIR/set_story_points.py" "$BASE_DIR/fields/set-story-points.py" 
  mv_with_rename "$BASE_DIR/update_parent_and_story_points.py" "$BASE_DIR/fields/update-parent-and-points.py" 
  
  echo "✅ Field scripts moved"
}

move_utility_scripts() {
  echo "Moving utility scripts..."
  
  # Utility scripts
  mv_with_rename "$BASE_DIR/list_project_items.py" "$BASE_DIR/utilities/list-project-items.py" 
  mv_with_rename "$BASE_DIR/find_missing_issues.py" "$BASE_DIR/utilities/find-missing-issues.py" 
  mv_with_rename "$BASE_DIR/find_duplicate_issues.py" "$BASE_DIR/utilities/find-duplicate-issues.py" 
  mv_with_rename "$BASE_DIR/check_missing_epics.py" "$BASE_DIR/utilities/check-missing-parents.py" 
  mv_with_rename "$BASE_DIR/test-project-access.sh" "$BASE_DIR/utilities/test-access.sh" 
  
  # We don't move cleanup.sh since we're currently running it
  # We'll copy it to utilities at the end
  
  echo "✅ Utility scripts moved"
}

set_executable_permissions() {
  echo "Setting executable permissions..."
  
  find "$BASE_DIR/migration" "$BASE_DIR/parent-child" "$BASE_DIR/fields" "$BASE_DIR/utilities" -name "*.sh" -exec chmod +x {} \;
  
  echo "✅ Executable permissions set"
}

create_readme_files() {
  echo "Creating README files..."
  
  # Create README for migration directory
  cat > "$BASE_DIR/migration/README.md" << 'EOF'
# Migration Scripts

This directory contains scripts for migrating GitHub issues to GitHub Projects.

## Scripts

| Script | Description |
|--------|-------------|
| `add-issues.sh` | Adds all issues to the GitHub Project |
| `add-missing-stories.sh` | Adds missing user stories to the Project |
| `migrate-issues.sh` | Migrates all issues with proper metadata |
| `migrate-comments.sh` | Extracts and migrates comments |
| `simple-migration.py` | Simple Python-based migration script |
| `batch-migration.py` | Processes issues in batches |
| `complete-migration.py` | End-to-end migration script |

## Usage

1. First ensure you have the proper GitHub token permissions:
   ```bash
   gh auth refresh -h github.com -s project
   ```

2. Create a GitHub Project (if not exists):
   ```bash
   ./create-github-project.sh
   ```

3. Add issues to the project:
   ```bash
   ./add-issues.sh
   ```

4. For a more comprehensive migration, use:
   ```bash
   ./migrate-issues.sh
   ```
EOF

  # Create README for parent-child directory
  cat > "$BASE_DIR/parent-child/README.md" << 'EOF'
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
EOF

  # Create README for fields directory
  cat > "$BASE_DIR/fields/README.md" << 'EOF'
# Field Management Scripts

This directory contains scripts for managing custom fields in GitHub Projects.

## Scripts

| Script | Description |
|--------|-------------|
| `create-fields.sh` | Creates all custom fields in the project |
| `create-component-field.sh` | Creates the Component field with options |
| `create-epic-field.sh` | Creates the Epic field |
| `set-components.sh` | Sets Component field values |
| `update-missing-components.py` | Updates missing Component field values |
| `set-types.sh` | Sets Type field values |
| `set-story-points.py` | Sets Story Points field values |
| `update-parent-and-points.py` | Updates both Parent and Story Points fields |

## Usage

### Creating All Fields

```bash
./create-fields.sh
```

### Setting Type Field Values

```bash
./set-types.sh
```

### Setting Component Field Values

```bash
./set-components.sh
```

### Setting Story Points

```bash
python set-story-points.py
```
EOF

  # Create README for utilities directory
  cat > "$BASE_DIR/utilities/README.md" << 'EOF'
# Utility Scripts

This directory contains utility scripts for working with GitHub Projects.

## Scripts

| Script | Description |
|--------|-------------|
| `list-project-items.py` | Lists all items in the GitHub Project |
| `find-missing-issues.py` | Finds issues not in the GitHub Project |
| `find-duplicate-issues.py` | Finds duplicate issues |
| `check-missing-parents.py` | Checks for issues missing parent relationships |
| `test-access.sh` | Tests GitHub token permissions |
| `cleanup.sh` | Cleans up and organizes scripts |

## Usage

### Listing Project Items

```bash
python list-project-items.py
```

### Finding Missing Issues

```bash
python find-missing-issues.py
```

### Checking for Missing Parents

```bash
python check-missing-parents.py
```

### Testing Access

```bash
./test-access.sh
```
EOF

  # Create README for deprecated directory
  cat > "$BASE_DIR/deprecated/README.md" << 'EOF'
# Deprecated Scripts

This directory contains scripts that have been replaced by newer versions or are no longer needed.

These scripts are kept for reference purposes but should not be used in production.

If you need functionality from these scripts, please check the main script directories:
- `../migration/` - For migration-related scripts
- `../parent-child/` - For parent-child relationship scripts
- `../fields/` - For field management scripts
- `../utilities/` - For utility scripts
EOF

  echo "✅ README files created"
}

update_main_readme() {
  echo "Updating main README..."
  
  cat > "$BASE_DIR/README.md" << 'EOF'
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
EOF

  echo "✅ Main README updated"
}

move_deprecated_scripts() {
  echo "Moving outdated scripts to deprecated directory..."
  
  # Move the original versions of improved scripts
  mv "$BASE_DIR/set-direct-parent.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/batch-set-parent-relationships.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  
  # Move the backup directory contents
  if [ -d "$BASE_DIR/backup" ]; then
    find "$BASE_DIR/backup" -type f -name "*.sh" -exec mv {} "$BASE_DIR/deprecated/" \; 2>/dev/null
  fi
  
  # Move other deprecated scripts
  mv "$BASE_DIR/part1-add-issues-set-types.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/part2-set-parent-relationships.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/process-issue-range.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/set-parent-manual.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/python-set-parent-issues.py" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/assign-missing-parents.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  mv "$BASE_DIR/set-single-parent.sh" "$BASE_DIR/deprecated/" 2>/dev/null
  
  # Move remaining scripts to deprecated (anything not already organized)
  find "$BASE_DIR" -maxdepth 1 -type f -name "*.sh" -not -name "cleanup.sh" | while read -r file; do
    if [[ -f "$file" ]]; then
      echo "  Moving $file to deprecated/"
      mv "$file" "$BASE_DIR/deprecated/" 2>/dev/null
    fi
  done
  
  find "$BASE_DIR" -maxdepth 1 -type f -name "*.py" | while read -r file; do
    if [[ -f "$file" ]]; then
      echo "  Moving $file to deprecated/"
      mv "$file" "$BASE_DIR/deprecated/" 2>/dev/null
    fi
  done
  
  echo "✅ Deprecated scripts moved"
}

finalize_cleanup() {
  echo "Finalizing cleanup..."
  
  # Copy the cleanup script to utilities
  cp "$BASE_DIR/cleanup.sh" "$BASE_DIR/utilities/cleanup.sh" 2>/dev/null
  
  # Create log file listing all scripts in their new locations
  {
    echo "# Script Reorganization Log"
    echo "Date: $(date)"
    echo ""
    echo "## Migration Scripts"
    ls -la "$BASE_DIR/migration/"
    echo ""
    echo "## Parent-Child Scripts"
    ls -la "$BASE_DIR/parent-child/"
    echo ""
    echo "## Field Scripts"
    ls -la "$BASE_DIR/fields/"
    echo ""
    echo "## Utility Scripts"
    ls -la "$BASE_DIR/utilities/"
    echo ""
    echo "## Deprecated Scripts"
    ls -la "$BASE_DIR/deprecated/"
  } > "$BASE_DIR/script-reorganization.log"
  
  echo "✅ Cleanup finalized"
}

# Custom move function that handles renaming
mv_with_rename() {
  local source="$1"
  local dest="$2"
  
  if [ -f "$source" ]; then
    echo "  Moving $source to $dest"
    mv "$source" "$dest" 2>/dev/null || echo "  ⚠️ Failed to move $source"
  else
    echo "  ⚠️ Source file not found: $source"
  fi
}

# ----------- MAIN ----------- #
echo "🧹 Starting scripts cleanup and organization..."

create_directories
move_migration_scripts
move_parent_child_scripts
move_field_scripts
move_utility_scripts
set_executable_permissions
create_readme_files
update_main_readme
move_deprecated_scripts
finalize_cleanup

echo "🏁 Script cleanup and organization completed!"
echo "The scripts are now organized into the following directories:"
echo "- migration/: GitHub Project migration scripts"
echo "- parent-child/: Parent-child relationship scripts"
echo "- fields/: Field management scripts"
echo "- utilities/: Helper and utility scripts"
echo "- deprecated/: Outdated or superseded scripts"
echo ""
echo "Each directory has a README.md file with more information."
echo "A complete log of the reorganization can be found in script-reorganization.log"
echo ""
echo "Please review the new organization and test the scripts to ensure they work correctly."
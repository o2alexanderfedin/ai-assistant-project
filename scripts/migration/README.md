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

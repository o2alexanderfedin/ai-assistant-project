# Script Cleanup Plan

## Directory Structure

```
scripts/
├── README.md                     # Main README with script documentation
├── migration/                    # GitHub Project migration scripts
│   ├── README.md                 # Migration-specific documentation
│   ├── create-github-project.sh  # Project creation
│   ├── migrate-issues.sh         # Add issues to project
│   ├── batch-migration.sh        # Process issues in batches
│   └── migrate-comments.sh       # Extract and migrate comments
│
├── fields/                       # Field management scripts
│   ├── README.md                 # Fields-specific documentation
│   ├── create-fields.sh          # Create all custom fields
│   ├── set-types.sh              # Set Type field values
│   ├── set-components.sh         # Set Component field values
│   ├── set-priorities.sh         # Set Priority field values
│   └── set-story-points.sh       # Set Story Points field values
│
├── parent-child/                 # Parent-child relationship scripts
│   ├── README.md                 # Parent-child specific documentation
│   ├── set-parent.sh             # Set a single parent-child relationship
│   ├── batch-set-parents.sh      # Set multiple parent-child relationships
│   └── verify-parents.sh         # Verify parent-child relationships
│
├── utilities/                    # Helper and utility scripts
│   ├── README.md                 # Utilities documentation
│   ├── test-access.sh            # Test GitHub token permissions
│   ├── list-items.sh             # List all project items
│   ├── find-missing.sh           # Find missing issues/fields
│   └── cleanup.sh                # Clean up temporary files
│
└── deprecated/                   # Outdated or superseded scripts
    └── README.md                 # Documentation of deprecated scripts
```

## Script Naming Conventions

1. Use kebab-case for all script names (e.g., `create-fields.sh` instead of `create_fields.sh`)
2. Prefix script names with verbs (create-, set-, update-, migrate-, find-, etc.)
3. For related scripts, use the same prefix (e.g., `set-types.sh`, `set-components.sh`)
4. Use simple, descriptive names that indicate the script's purpose

## Script Standardization

Each script should follow this standard format:

```bash
#!/bin/bash

# Title: Script Name
# Description: Brief description of what the script does
# Usage: ./script-name.sh [arguments]
# Author: AI Assistant Team
# Date: YYYY-MM-DD
# Last Updated: YYYY-MM-DD

# ----------- CONFIG ----------- #
# Configuration variables here

# ----------- FUNCTIONS ----------- #
# Helper functions here

# ----------- MAIN ----------- #
# Main script logic here

# ----------- CLEANUP ----------- #
# Cleanup operations here
```

## Documentation Improvements

1. Each directory should have its own README.md explaining the scripts in that directory
2. The main README.md should be updated to reflect the new organization
3. Each script should include clear usage instructions and examples
4. Document dependencies between scripts (which scripts must be run first)
5. Add error handling and reporting to all scripts

## Migration Approach

1. Copy all active scripts to their new locations based on functionality
2. Standardize format and naming
3. Move deprecated scripts to the deprecated directory
4. Update documentation
5. Test the reorganized scripts
6. Remove duplicate or redundant scripts

## Timeline

1. Directory creation: Completed
2. Script categorization and copying: In progress
3. Standardization and documentation: Pending
4. Testing: Pending
5. Cleanup: Pending
#!/bin/bash

# This script moves test scripts to a backup directory

# ----------- CONFIG ----------- #
BACKUP_DIR="/Users/alexanderfedin/Projects/ai-assistant-project/scripts/backup"

# Scripts to keep
KEEP_SCRIPTS=(
  "add-sub-issue-graphql.sh"
  "create-sub-issue.sh"
  "update-all-sub-issues.sh"
  "delete-test-issues.sh"
  "cleanup-test-scripts.sh"
)

# ----------- BACKUP SCRIPTS ----------- #
echo "📦 Creating backup directory..."
mkdir -p "$BACKUP_DIR"

echo "🔍 Identifying test scripts to move..."
for SCRIPT in /Users/alexanderfedin/Projects/ai-assistant-project/scripts/*.sh; do
  SCRIPT_NAME=$(basename "$SCRIPT")
  
  # Check if script is in the keep list
  KEEP=false
  for KEEP_SCRIPT in "${KEEP_SCRIPTS[@]}"; do
    if [ "$SCRIPT_NAME" == "$KEEP_SCRIPT" ]; then
      KEEP=true
      break
    fi
  done
  
  # Move script to backup if not in keep list
  if [ "$KEEP" == "false" ]; then
    echo "📦 Moving $SCRIPT_NAME to backup directory..."
    mv "$SCRIPT" "$BACKUP_DIR/$SCRIPT_NAME"
  else
    echo "✅ Keeping $SCRIPT_NAME"
  fi
done

echo ""
echo "🎉 Done! Test scripts have been moved to $BACKUP_DIR"
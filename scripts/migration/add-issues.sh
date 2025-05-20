#!/bin/bash

# This script ensures all issues are added to the project

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number

# ----------- PROCESS ISSUES ----------- #
echo "🔍 Finding all issues..."

# Get all issues
ALL_ISSUES=$(gh issue list --repo $OWNER/$REPO --limit 100 --json number,title)
ISSUE_COUNT=$(echo "$ALL_ISSUES" | jq length)
echo "Found $ISSUE_COUNT issues in the repository"

# Get project items
echo "📋 Checking project items..."
PROJECT_ITEMS=$(gh project item-list $PROJECT_NUM --owner $OWNER --limit 100)

# Process each issue
echo "🔄 Adding issues to project..."
SUCCESS_COUNT=0
ALREADY_EXISTS=0
FAILURE_COUNT=0

for ISSUE_NUM in $(echo "$ALL_ISSUES" | jq -r '.[].number'); do
  # Skip issues we've already deleted
  if [[ $ISSUE_NUM -gt 68 ]]; then
    continue
  fi
  
  ISSUE_TITLE=$(echo "$ALL_ISSUES" | jq -r ".[] | select(.number == $ISSUE_NUM) | .title")
  echo "Processing issue #$ISSUE_NUM: '$ISSUE_TITLE'..."
  
  # Check if issue is already in project (this is approximate since we don't have direct number access)
  if echo "$PROJECT_ITEMS" | grep -q "$ISSUE_TITLE"; then
    echo "  ⚠️ Issue might already be in project, skipping"
    ALREADY_EXISTS=$((ALREADY_EXISTS + 1))
    continue
  fi
  
  # Add issue to project
  gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$ISSUE_NUM" &>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully added issue #$ISSUE_NUM to project"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to add issue #$ISSUE_NUM to project"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo ""
echo "🏁 Finished adding issues to project!"
echo "✅ Added: $SUCCESS_COUNT issues"
echo "⚠️ Potentially already existed: $ALREADY_EXISTS issues"
echo "❌ Failed: $FAILURE_COUNT issues"
echo ""
echo "All issues should now be in the project."
#!/bin/bash

# This script deletes test issues created during our experimentation

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# List of test issue numbers
TEST_ISSUES=(71 72 73 74 75 70 69)

# ----------- DELETE ISSUES ----------- #
echo "🗑️ Deleting test issues..."

for ISSUE_NUM in "${TEST_ISSUES[@]}"; do
  echo "Deleting issue #$ISSUE_NUM..."
  
  # Get issue title for verification
  ISSUE_DATA=$(gh issue view $ISSUE_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo "  ⚠️ Issue #$ISSUE_NUM not found, skipping"
    continue
  fi
  
  ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')
  
  # Only delete issues with "Test" in the title as a safety measure
  if [[ ! "$ISSUE_TITLE" =~ "Test" ]]; then
    echo "  ⚠️ Issue #$ISSUE_NUM doesn't contain 'Test' in the title, skipping for safety"
    continue
  fi
  
  echo "  🗑️ Deleting issue #$ISSUE_NUM: '$ISSUE_TITLE'"
  gh issue close $ISSUE_NUM --repo $OWNER/$REPO --reason "Not planned" --comment "Closing test issue created during automation testing"
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully closed issue #$ISSUE_NUM"
  else
    echo "  ❌ Failed to close issue #$ISSUE_NUM"
  fi
done

echo ""
echo "🎉 Done! All test issues have been closed."
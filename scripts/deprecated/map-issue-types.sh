#!/bin/bash
# Map GitHub issue labels to GitHub Project item types
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Mapping issue labels to GitHub Project item types..."

# Get all issues with labels
ISSUES=$(gh issue list --limit 100 --json number,title,labels --repo "$REPO")

# Process each issue
echo "$ISSUES" | jq -c '.[]' | while read -r ISSUE; do
  ISSUE_NUM=$(echo "$ISSUE" | jq -r '.number')
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r '.title')
  LABELS=$(echo "$ISSUE" | jq -r '.labels[].name' 2>/dev/null || echo "")
  
  echo "  🔍 Processing issue #$ISSUE_NUM: $ISSUE_TITLE"
  
  # Determine item type based on labels
  TYPE=""
  if echo "$LABELS" | grep -q "epic"; then
    TYPE="Epic"
    echo "    📊 Found label 'epic' -> Type = Epic"
  elif echo "$LABELS" | grep -q "user-story"; then
    TYPE="User Story"
    echo "    📊 Found label 'user-story' -> Type = User Story"
  else
    # Default
    TYPE="Task"
    echo "    📊 No specific type label found -> Type = Task"
  fi
  
  echo "    📝 Issue #$ISSUE_NUM is of type: $TYPE"
  echo "    ℹ️ To set the Type field in GitHub Project:"
  echo "       1. Go to https://github.com/users/o2alexanderfedin/projects/2"
  echo "       2. Find issue #$ISSUE_NUM: $ISSUE_TITLE"
  echo "       3. Set the Type field to: $TYPE"
  echo ""
done

echo "🎉 Mapping complete!"
echo ""
echo "To apply these types to your GitHub Project:"
echo "1. Open your project at https://github.com/users/o2alexanderfedin/projects/2"
echo "2. Add the 'Type' field if you haven't already (Single select with options: Epic, User Story, Task)"
echo "3. Update each issue with the type as indicated above"
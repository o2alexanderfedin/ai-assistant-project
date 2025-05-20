#!/bin/bash

# This script creates a child issue and sets it as a sub-issue of a parent

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# ----------- INPUT ----------- #
PARENT_NUM="$1"
CHILD_TITLE="$2"
CHILD_BODY="$3"
CHILD_LABELS="${4:-"task"}"

if [[ -z "$PARENT_NUM" || -z "$CHILD_TITLE" ]]; then
  echo "Usage: $0 <parent_issue_number> \"Child Title\" \"Child Body\" \"label1,label2,...\""
  echo "Example: $0 1 \"Implement X feature\" \"This task is to implement X\" \"task,priority:high\""
  exit 1
fi

# ----------- VERIFY PARENT ----------- #
echo "🔍 Verifying parent issue #$PARENT_NUM..."
PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ Parent issue #$PARENT_NUM not found"
  exit 1
fi

PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
echo "Found parent: #$PARENT_NUM '$PARENT_TITLE'"

# ----------- CREATE CHILD ISSUE ----------- #
echo "📝 Creating child issue '$CHILD_TITLE'..."

# Add reference to parent in the body
FULL_BODY="$CHILD_BODY

---
Parent: #$PARENT_NUM"

CHILD_ISSUE=$(gh issue create --repo $OWNER/$REPO --title "$CHILD_TITLE" --body "$FULL_BODY" --label "$CHILD_LABELS")

if [ $? -ne 0 ]; then
  echo "❌ Failed to create child issue"
  exit 1
fi

CHILD_NUM=$(echo $CHILD_ISSUE | grep -o '[0-9]*$')
echo "✅ Created child issue #$CHILD_NUM: $CHILD_ISSUE"

# ----------- ADD TO PROJECT ----------- #
echo "📋 Adding issue to project..."
PROJECT_NUM=1  # Adjust to your project number

# Add both issues to project (just in case)
gh project item-add $PROJECT_NUM --owner $OWNER --url $CHILD_ISSUE &>/dev/null
gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$PARENT_NUM" &>/dev/null

# ----------- ATTEMPT TO SET PARENT ----------- #
echo "⚠️ Note: Setting parent/child relationships requires manual action in the GitHub UI"
echo "🔗 Please go to: https://github.com/users/$OWNER/projects/$PROJECT_NUM"
echo "   And set issue #$CHILD_NUM parent field to issue #$PARENT_NUM"

echo "✅ Done! Created child issue #$CHILD_NUM linked to parent #$PARENT_NUM"
echo "🔗 Child URL: $CHILD_ISSUE"
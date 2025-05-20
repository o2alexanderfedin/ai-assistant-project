#!/bin/bash

# This script creates a new issue with a parent link and adds it to the project

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number
FIELD_ID="PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y"  # ID of "Parent Link" field

# ----------- INPUT ----------- #
PARENT_NUM="$1"
TITLE="$2"
BODY="$3"
LABELS="${4:-user-story}"

if [[ -z "$PARENT_NUM" || -z "$TITLE" ]]; then
  echo "Usage: $0 <parent_issue_number> \"Title\" \"Body\" \"label1,label2,...\""
  echo "Example: $0 1 \"Implement feature X\" \"This is a description\" \"user-story,priority:high\""
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
echo "📝 Creating issue '$TITLE'..."

# Add reference to parent in the body
FULL_BODY="$BODY

---
Parent Issue: #$PARENT_NUM"

ISSUE_URL=$(gh issue create --repo $OWNER/$REPO --title "$TITLE" --body "$FULL_BODY" --label "$LABELS")

if [ $? -ne 0 ]; then
  echo "❌ Failed to create issue"
  exit 1
fi

CHILD_NUM=$(echo $ISSUE_URL | grep -o '[0-9]*$')
echo "✅ Created issue #$CHILD_NUM: $ISSUE_URL"

# ----------- ADD TO PROJECT & SET PARENT LINK ----------- #
echo "📌 Adding issue to project..."
gh project item-add $PROJECT_NUM --owner $OWNER --url "$ISSUE_URL" &>/dev/null

# Wait a moment for the project to update
sleep 1

# ----------- GET PROJECT ID ----------- #
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi

# ----------- GET ITEM ID ----------- #
echo "🔍 Getting project item ID..."

# Get item ID from project item list
ITEMS_LIST=$(gh project item-list $PROJECT_NUM --owner $OWNER --limit 100)
ITEM_ID=$(echo "$ITEMS_LIST" | grep "Issue.*$CHILD_NUM.*$OWNER/$REPO" | awk '{print $NF}')

if [ -z "$ITEM_ID" ]; then
  echo "❌ Issue #$CHILD_NUM not found in project items"
  echo "⚠️ You'll need to manually set the parent link field"
  exit 1
fi
echo "Found item ID: $ITEM_ID"

# ----------- SET PARENT LINK FIELD ----------- #
echo "🔗 Setting parent link field..."

# Create parent link with markdown format
PARENT_URL="https://github.com/$OWNER/$REPO/issues/$PARENT_NUM"
PARENT_LINK="[#$PARENT_NUM]($PARENT_URL) - $PARENT_TITLE"

# Create a mutation with variables
MUTATION='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { 
        text: $text
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'

# Execute the mutation with variables
RESULT=$(gh api graphql \
  -f query="$MUTATION" \
  -f projectId="$PROJECT_ID" \
  -f itemId="$ITEM_ID" \
  -f fieldId="$FIELD_ID" \
  -f text="$PARENT_LINK")

if [[ "$RESULT" == *"projectV2Item"* ]]; then
  echo "✅ Successfully set parent link for issue #$CHILD_NUM to parent #$PARENT_NUM"
else
  echo "⚠️ Failed to set parent link automatically"
  echo "Error: $RESULT"
  echo "You'll need to manually set the parent link field"
fi

echo ""
echo "🎉 Issue #$CHILD_NUM created successfully with parent #$PARENT_NUM"
echo "🔗 Issue URL: $ISSUE_URL"
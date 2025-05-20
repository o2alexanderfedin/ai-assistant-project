#!/bin/bash

# This script sets the custom "Parent Link" field for an issue in a GitHub project

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number 
FIELD_ID="PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y"  # ID of "Parent Link" field

# ----------- INPUT ----------- #
CHILD_NUM="$1"
PARENT_NUM="$2"

if [[ -z "$CHILD_NUM" || -z "$PARENT_NUM" ]]; then
  echo "Usage: $0 <child_issue_number> <parent_issue_number>"
  echo "Example: $0 42 1"
  exit 1
fi

# ----------- VERIFY ISSUES ----------- #
echo "🔍 Verifying issues..."

# Verify parent issue
PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Parent issue #$PARENT_NUM not found"
  exit 1
fi
PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
echo "Found parent: #$PARENT_NUM '$PARENT_TITLE'"

# Verify child issue
CHILD_DATA=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Child issue #$CHILD_NUM not found"
  exit 1
fi
CHILD_TITLE=$(echo "$CHILD_DATA" | jq -r '.title')
echo "Found child: #$CHILD_NUM '$CHILD_TITLE'"

# ----------- CREATE PARENT LINK ----------- #
PARENT_URL="https://github.com/$OWNER/$REPO/issues/$PARENT_NUM"
PARENT_LINK="[#$PARENT_NUM]($PARENT_URL) - $PARENT_TITLE"
echo "🔗 Parent link: $PARENT_LINK"

# ----------- GET PROJECT ID ----------- #
echo "📋 Getting project details..."

# Get project ID 
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi
echo "Found project ID: $PROJECT_ID"

# ----------- ADD ISSUE TO PROJECT ----------- #
echo "📌 Adding issue to project if needed..."
gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$CHILD_NUM" &>/dev/null

# ----------- GET ITEM ID ----------- #
echo "🔍 Getting project item ID..."

# Get item ID from project item list
ITEMS_LIST=$(gh project item-list $PROJECT_NUM --owner $OWNER --limit 100)
ITEM_ID=$(echo "$ITEMS_LIST" | grep "Issue.*$CHILD_NUM.*$OWNER/$REPO" | awk '{print $NF}')

if [ -z "$ITEM_ID" ]; then
  echo "❌ Issue #$CHILD_NUM not found in project items"
  exit 1
fi
echo "Found item ID: $ITEM_ID"

# ----------- SET PARENT LINK FIELD ----------- #
echo "🔄 Setting parent link field..."

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
  echo "❌ Failed to set parent link"
  echo "Error: $RESULT"
  exit 1
fi

echo ""
echo "💡 The Parent Link field now contains a clickable link to issue #$PARENT_NUM"
echo "🔗 You can now create views grouped by this field to see child issues under their parents"
#!/bin/bash

# This script creates a new issue with a parent link and adds it to the project

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="1"  # Adjust to your project number
FIELD_NAME="Parent Link"  # Name of your custom field

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

# ----------- ADD TO PROJECT ----------- #
echo "📋 Adding issue to project..."
gh project item-add $PROJECT_NUM --owner $OWNER --url "$ISSUE_URL" &>/dev/null

# ----------- SET PARENT LINK ----------- #
echo "🔗 Setting parent link field..."

# Get project ID
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi

# Get field ID for Parent Link
FIELDS_DATA=$(gh api graphql -f query='
  query($owner:String!, $number:Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        fields(first: 20) {
          nodes {
            ... on ProjectV2Field {
              id
              name
            }
            ... on ProjectV2IterationField {
              id
              name
            }
            ... on ProjectV2SingleSelectField {
              id
              name
            }
          }
        }
      }
    }
  }
' -f owner="$OWNER" -f number="$PROJECT_NUM")

FIELD_ID=$(echo "$FIELDS_DATA" | jq -r --arg name "$FIELD_NAME" '.data.user.projectV2.fields.nodes[] | select(.name == $name) | .id')
if [ -z "$FIELD_ID" ]; then
  echo "❌ Field '$FIELD_NAME' not found"
  exit 1
fi

# Get item ID for the child issue
ITEMS_DATA=$(gh api graphql -f query='
  query($owner:String!, $number:Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue {
                number
              }
            }
          }
        }
      }
    }
  }
' -f owner="$OWNER" -f number="$PROJECT_NUM")

ITEM_ID=$(echo "$ITEMS_DATA" | jq -r --arg num "$CHILD_NUM" '.data.user.projectV2.items.nodes[] | select(.content.number == ($num|tonumber)) | .id')
if [ -z "$ITEM_ID" ]; then
  echo "❌ Issue #$CHILD_NUM not found in project"
  exit 1
fi

# Create parent link
PARENT_URL="https://github.com/$OWNER/$REPO/issues/$PARENT_NUM"
PARENT_LINK="[#$PARENT_NUM]($PARENT_URL) - $PARENT_TITLE"

# Set parent link field
RESULT=$(gh api graphql -f query='
  mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $text:String!) {
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
' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$FIELD_ID" -f text="$PARENT_LINK")

if [[ "$RESULT" == *"projectV2Item"* ]]; then
  echo "✅ Successfully set parent link for issue #$CHILD_NUM to parent #$PARENT_NUM"
else
  echo "❌ Failed to set parent link"
  echo "Error: $RESULT"
fi

echo ""
echo "🎉 Issue #$CHILD_NUM created successfully with parent #$PARENT_NUM"
echo "🔗 Issue URL: $ISSUE_URL"
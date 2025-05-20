#!/bin/bash

# Script to set a custom parent field value for an issue in GitHub Project

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="1"  # Adjust to your project number

# ----------- INPUT ----------- #
CHILD_NUM="$1"
PARENT_TITLE="$2"

if [[ -z "$CHILD_NUM" || -z "$PARENT_TITLE" ]]; then
  echo "Usage: $0 <child_issue_number> \"<parent_title>\""
  echo "Example: $0 42 \"🔄 Core Agent System Implementation\""
  exit 1
fi

# ----------- VALIDATE AUTHENTICATION ----------- #
echo "🔑 Validating GitHub authentication..."
gh auth status > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub authentication failed. Please run 'gh auth login' first."
  echo "🔑 Also ensure token has 'project' scope: gh auth refresh -h github.com -s project"
  exit 1
fi

# ----------- GET PROJECT AND FIELD IDs ----------- #
echo "🔍 Getting project information..."

# Get project ID
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi

echo "Found project ID: $PROJECT_ID"

# Get custom parent field ID
echo "🔍 Finding custom parent field ID..."
FIELDS_DATA=$(gh api graphql -f query='
  query($owner:String!, $number:Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }
' -f owner="$OWNER" -f number="$PROJECT_NUM")

PARENT_FIELD_DATA=$(echo "$FIELDS_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name == "Custom Parent")')

if [ -z "$PARENT_FIELD_DATA" ]; then
  echo "❌ Custom Parent field not found. Run create-custom-parent-field.sh first."
  exit 1
fi

PARENT_FIELD_ID=$(echo "$PARENT_FIELD_DATA" | jq -r '.id')
echo "Found Custom Parent field ID: $PARENT_FIELD_ID"

# Get option ID for the parent title
OPTION_ID=$(echo "$PARENT_FIELD_DATA" | jq -r --arg title "$PARENT_TITLE" '.options[] | select(.name == $title) | .id')

if [ -z "$OPTION_ID" ]; then
  echo "❌ Parent title '$PARENT_TITLE' not found in options"
  echo "Available options:"
  echo "$PARENT_FIELD_DATA" | jq -r '.options[].name' | sed 's/^/  - /'
  exit 1
fi

echo "Found option ID for '$PARENT_TITLE': $OPTION_ID"

# ----------- GET CHILD ITEM ID ----------- #
echo "🔍 Finding child issue #$CHILD_NUM in project..."

# Add child to project if needed
gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$CHILD_NUM" &>/dev/null

# Get child item ID
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
                title
              }
            }
          }
        }
      }
    }
  }
' -f owner="$OWNER" -f number="$PROJECT_NUM")

CHILD_ITEM_ID=$(echo "$ITEMS_DATA" | jq -r --arg num "$CHILD_NUM" '.data.user.projectV2.items.nodes[] | select(.content.number == ($num|tonumber)) | .id')

if [ -z "$CHILD_ITEM_ID" ]; then
  echo "❌ Child issue #$CHILD_NUM not found in project"
  exit 1
fi

CHILD_TITLE=$(echo "$ITEMS_DATA" | jq -r --arg num "$CHILD_NUM" '.data.user.projectV2.items.nodes[] | select(.content.number == ($num|tonumber)) | .content.title')
echo "Found child: #$CHILD_NUM '$CHILD_TITLE' (Item ID: $CHILD_ITEM_ID)"

# ----------- SET CUSTOM PARENT FIELD ----------- #
echo "🔄 Setting custom parent field..."
RESULT=$(gh api graphql -f query='
  mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!) {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { 
          singleSelectOptionId: $optionId
        }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }
' -f projectId="$PROJECT_ID" -f itemId="$CHILD_ITEM_ID" -f fieldId="$PARENT_FIELD_ID" -f optionId="$OPTION_ID")

if [[ "$RESULT" == *"projectV2Item"* ]]; then
  echo "✅ Successfully set custom parent for issue #$CHILD_NUM to '$PARENT_TITLE'"
else
  echo "❌ Failed to set custom parent"
  echo "Error: $RESULT"
  exit 1
fi
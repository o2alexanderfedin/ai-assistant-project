#!/bin/bash

# This script sets types for the newly added user stories

# CONFIG
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_ID="PVT_kwHOBJ7Qkc4A5SDb"  # Use the raw project ID

# Get project items for the newly added issues
echo "🔍 Getting newly added project items..."
PROJECT_ITEMS=$(gh project item-list 2 --owner $OWNER)

# Get Type field info
echo "🔍 Getting Type field info..."
FIELDS_DATA=$(gh api graphql -f query='
  query($projectId:ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2Field {
              id
              name
            }
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
  }' -f projectId="$PROJECT_ID")

# Find the Type field
TYPE_FIELD=$(echo "$FIELDS_DATA" | jq '.data.node.fields.nodes[] | select(.name == "Type")')
TYPE_FIELD_ID=$(echo "$TYPE_FIELD" | jq -r '.id')
echo "Type Field ID: $TYPE_FIELD_ID"

# Get User Story option ID
USER_STORY_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "User Story") | .id')
echo "User Story Option ID: $USER_STORY_OPTION_ID"

# Get all project items
ITEMS_DATA=$(gh api graphql -f query='
  query($projectId:ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue {
                id
                number
                title
              }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID")

echo "🔄 Setting types for newly added issues..."
echo "$ITEMS_DATA" | jq -c '.data.node.items.nodes[]' | while read -r ITEM; do
  ISSUE_NUMBER=$(echo "$ITEM" | jq -r '.content.number')
  
  # Process only the newly added issues (37-43)
  if [[ $ISSUE_NUMBER -ge 37 && $ISSUE_NUMBER -le 43 ]]; then
    ITEM_ID=$(echo "$ITEM" | jq -r '.id')
    ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
    
    echo "Processing issue #$ISSUE_NUMBER: $ISSUE_TITLE"
    echo "  Setting type to User Story"
    
    # Set the type
    MUTATION_RESULT=$(gh api graphql -f query='
      mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: {
            singleSelectOptionId: $optionId
          }
        }) {
          projectV2Item {
            id
          }
        }
      }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$USER_STORY_OPTION_ID")
    
    if [ $? -eq 0 ]; then
      echo "  ✅ Successfully set type to User Story"
    else
      echo "  ❌ Failed to set type"
    fi
  fi
done

echo ""
echo "🏁 Finished setting types for newly added issues!"
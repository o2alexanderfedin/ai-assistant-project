#!/bin/bash

# This script uses the raw project node ID to set the types for all issues

# CONFIG
OWNER="o2alexanderfedin"
REPO="ai-assistant-project" 
PROJECT_ID="PVT_kwHOBJ7Qkc4A5SDb"  # Use the raw project ID from gh project list

# Step 1: Get fields and find the Type field ID
echo "🔍 Getting fields to find Type field ID..."
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

# Get option IDs for Epic and User Story
EPIC_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "Epic") | .id')
USER_STORY_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "User Story") | .id')
echo "Epic Option ID: $EPIC_OPTION_ID"
echo "User Story Option ID: $USER_STORY_OPTION_ID"

# Step 2: Get all project items
echo "🔍 Getting all project items..."
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
                repository {
                  name
                }
              }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID")

# Get all issues from the repository
echo "🔍 Getting all repository issues with labels..."
REPO_ISSUES=$(gh issue list --repo "$OWNER/$REPO" --limit 100 --json number,title,labels)

# Process each project item and set its type based on labels
echo "🔄 Setting types for project items..."
SUCCESS_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

echo "$ITEMS_DATA" | jq -c '.data.node.items.nodes[]' | while read -r ITEM; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  CONTENT=$(echo "$ITEM" | jq '.content')
  
  # Skip if no content (e.g., draft issues)
  if [ "$CONTENT" = "null" ]; then
    echo "Skipping draft item"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi
  
  ISSUE_NUMBER=$(echo "$ITEM" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
  REPO_NAME=$(echo "$ITEM" | jq -r '.content.repository.name')
  
  # Only process items from our target repository
  if [ "$REPO_NAME" != "$REPO" ]; then
    echo "Skipping item from different repository: $REPO_NAME"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi
  
  echo "Processing project item for issue #$ISSUE_NUMBER: $ISSUE_TITLE"
  
  # Find the corresponding issue in our repository issues to get its labels
  ISSUE_DATA=$(echo "$REPO_ISSUES" | jq -r ".[] | select(.number == $ISSUE_NUMBER)")
  
  # Check if issue has the epic label
  IS_EPIC=$(echo "$ISSUE_DATA" | jq -r '.labels[] | select(.name == "epic") | .name')
  
  if [ -n "$IS_EPIC" ]; then
    OPTION_ID="$EPIC_OPTION_ID"
    TYPE_NAME="Epic"
  else
    OPTION_ID="$USER_STORY_OPTION_ID"
    TYPE_NAME="User Story"
  fi
  
  echo "  Setting type to $TYPE_NAME"
  
  # Set the type field
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
    }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$OPTION_ID")
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully set type to $TYPE_NAME"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to set type"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

echo ""
echo "🏁 Finished setting types for all project items!"
echo "✅ Successfully updated: $SUCCESS_COUNT items"
echo "⚠️ Skipped: $SKIPPED_COUNT items"
echo "❌ Failed: $ERROR_COUNT items"
echo ""
echo "All issues should now have appropriate types in the project."
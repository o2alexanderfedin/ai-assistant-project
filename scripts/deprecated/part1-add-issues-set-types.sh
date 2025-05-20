#!/bin/bash

# Part 1: Add all issues to project and set their types

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"
PROJECT_ID="PVT_kwHOBJ7Qkc4A5SDb"

# Get Type field info
echo "🔍 Getting project fields..."
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

# Extract Type field and options
TYPE_FIELD=$(echo "$FIELDS_DATA" | jq '.data.node.fields.nodes[] | select(.name == "Type")')
TYPE_FIELD_ID=$(echo "$TYPE_FIELD" | jq -r '.id')
EPIC_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "Epic") | .id')
USER_STORY_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "User Story") | .id')

echo "Type Field ID: $TYPE_FIELD_ID"
echo "Epic Option ID: $EPIC_OPTION_ID"
echo "User Story Option ID: $USER_STORY_OPTION_ID"

# Get all GitHub repository issues
echo "🔍 Getting all repository issues..."
REPO_ISSUES=$(gh issue list --repo "$OWNER/$REPO" --limit 100 --json number,title,labels,body)
ISSUE_COUNT=$(echo "$REPO_ISSUES" | jq length)
echo "Found $ISSUE_COUNT issues in the repository"

# Get all existing project items
echo "🔍 Getting current project items..."
PROJECT_ITEMS=$(gh project item-list $PROJECT_NUM --owner $OWNER)

# Function to set issue type in project
set_issue_type() {
  local ITEM_ID=$1
  local TYPE_ID=$2
  local TYPE_NAME=$3
  
  echo "  Setting type to $TYPE_NAME"
  
  # Execute mutation to set the type
  RESULT=$(gh api graphql -f query='
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
    }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$TYPE_ID")
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully set type to $TYPE_NAME"
  else
    echo "  ❌ Failed to set type"
  fi
}

# Process each issue from the repository
echo "🔄 Processing issues..."
echo "$REPO_ISSUES" | jq -c '.[]' | while read -r ISSUE; do
  ISSUE_NUM=$(echo "$ISSUE" | jq -r '.number')
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r '.title')
  ISSUE_BODY=$(echo "$ISSUE" | jq -r '.body')
  
  echo "Processing issue #$ISSUE_NUM: '$ISSUE_TITLE'"
  
  # Check if issue is in project
  if echo "$PROJECT_ITEMS" | grep -q "$ISSUE_TITLE"; then
    echo "  ✓ Issue already in project"
    # Get the item ID
    ITEM_ID=$(gh api graphql -f query='
      query($projectId:ID!) {
        node(id: $projectId) {
          ... on ProjectV2 {
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
      }' -f projectId="$PROJECT_ID" | jq -r ".data.node.items.nodes[] | select(.content.title == \"$ISSUE_TITLE\") | .id")
    
    # If there's an item ID, continue with updating
    if [ -n "$ITEM_ID" ]; then
      # Check if issue has epic label and set type accordingly
      IS_EPIC=$(echo "$ISSUE" | jq -r '.labels[] | select(.name == "epic") | .name')
      
      if [ -n "$IS_EPIC" ]; then
        set_issue_type "$ITEM_ID" "$EPIC_OPTION_ID" "Epic"
      else
        set_issue_type "$ITEM_ID" "$USER_STORY_OPTION_ID" "User Story"
      fi
    else
      echo "  ⚠️ Could not find item ID in project"
    fi
  else
    echo "  ➕ Adding issue to project"
    # Add issue to project
    gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$ISSUE_NUM"
    
    if [ $? -eq 0 ]; then
      echo "  ✅ Successfully added issue to project"
      
      # Get the new item ID
      sleep 2  # Short pause to ensure the item is registered
      ITEM_ID=$(gh api graphql -f query='
        query($projectId:ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
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
        }' -f projectId="$PROJECT_ID" | jq -r ".data.node.items.nodes[] | select(.content.number == $ISSUE_NUM) | .id")
      
      # Set type based on labels
      IS_EPIC=$(echo "$ISSUE" | jq -r '.labels[] | select(.name == "epic") | .name')
      
      if [ -n "$ITEM_ID" ]; then
        if [ -n "$IS_EPIC" ]; then
          set_issue_type "$ITEM_ID" "$EPIC_OPTION_ID" "Epic"
        else
          set_issue_type "$ITEM_ID" "$USER_STORY_OPTION_ID" "User Story"
        fi
      else
        echo "  ⚠️ Could not find item ID for newly added issue"
      fi
    else
      echo "  ❌ Failed to add issue to project"
    fi
  fi
done

echo ""
echo "🏁 Finished adding all issues to project and setting their types!"
echo ""
echo "Now run part2-set-parent-relationships.sh to establish the parent-child relationships."
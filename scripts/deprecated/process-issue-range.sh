#!/bin/bash

# Process a range of issues (adding to project and setting types)
# Usage: ./process-issue-range.sh start_number end_number
# Example: ./process-issue-range.sh 20 30

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"
PROJECT_ID="PVT_kwHOBJ7Qkc4A5SDb"

# Get command line arguments
START_NUM=$1
END_NUM=$2

if [ -z "$START_NUM" ] || [ -z "$END_NUM" ]; then
  echo "Usage: $0 start_number end_number"
  exit 1
fi

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

# Process issues in the given range
echo "🔄 Processing issues from #$START_NUM to #$END_NUM..."
for ISSUE_NUM in $(seq $START_NUM $END_NUM); do
  # Get issue details
  ISSUE_DATA=$(gh issue view $ISSUE_NUM --repo "$OWNER/$REPO" --json number,title,labels,body 2>/dev/null)
  
  # Check if issue exists
  if [ $? -ne 0 ]; then
    echo "Issue #$ISSUE_NUM does not exist, skipping"
    continue
  fi
  
  ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')
  ISSUE_LABELS=$(echo "$ISSUE_DATA" | jq -r '.labels[].name' 2>/dev/null || echo "")
  
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
      # Check if issue has epic label
      if echo "$ISSUE_LABELS" | grep -q "epic"; then
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
      
      # If there's an item ID, set the type
      if [ -n "$ITEM_ID" ]; then
        # Check if issue has epic label
        if echo "$ISSUE_LABELS" | grep -q "epic"; then
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
echo "🏁 Finished processing issues from #$START_NUM to #$END_NUM"
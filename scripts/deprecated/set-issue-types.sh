#!/bin/bash

# This script sets issue types in GitHub Project based on issue labels
# Epic for issues with "epic" label
# User Story for issues with "user-story" label

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number
TYPE_FIELD_ID="PVTF_lADOAGD9swUAM8qzgHfWyQ"  # Type field ID

# ----------- FUNCTIONS ----------- #
# Get the project ID
get_project_id() {
  PROJECT_DATA=$(gh api graphql -f query='
    query($owner:String!, $number:Int!) {
      organization(login: $owner) {
        projectV2(number: $number) {
          id
        }
      }
    }' -f owner="$OWNER" -f number="$PROJECT_NUM")
  
  PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.organization.projectV2.id')
  echo "$PROJECT_ID"
}

# Get option IDs for the type field
get_type_options() {
  FIELD_DATA=$(gh api graphql -f query='
    query($owner:String!, $number:Int!, $fieldId:ID!) {
      organization(login: $owner) {
        projectV2(number: $number) {
          field(id: $fieldId) {
            ... on ProjectV2SingleSelectField {
              options {
                id
                name
              }
            }
          }
        }
      }
    }' -f owner="$OWNER" -f number="$PROJECT_NUM" -f fieldId="$TYPE_FIELD_ID")
  
  echo "$FIELD_DATA" | jq -r '.data.organization.projectV2.field.options'
}

# Get all project items
get_project_items() {
  PROJECT_ID=$1
  
  ITEMS_DATA=$(gh api graphql -f query='
    query($projectId:ID!, $first:Int!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: $first) {
            nodes {
              id
              content {
                ... on Issue {
                  id
                  number
                  title
                  labels(first: 10) {
                    nodes {
                      name
                    }
                  }
                }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" -f first=100)
  
  echo "$ITEMS_DATA" | jq -r '.data.node.items.nodes'
}

# Set type for a project item
set_item_type() {
  PROJECT_ID=$1
  ITEM_ID=$2
  OPTION_ID=$3
  
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
    }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$TYPE_FIELD_ID" -f optionId="$OPTION_ID")
  
  echo "$RESULT"
}

# ----------- MAIN PROCESS ----------- #
echo "🔍 Getting project information..."
PROJECT_ID=$(get_project_id)
echo "Project ID: $PROJECT_ID"

echo "🔍 Getting type options..."
TYPE_OPTIONS=$(get_type_options)
EPIC_OPTION_ID=$(echo "$TYPE_OPTIONS" | jq -r '.[] | select(.name == "Epic") | .id')
USER_STORY_OPTION_ID=$(echo "$TYPE_OPTIONS" | jq -r '.[] | select(.name == "User Story") | .id')

echo "Type options:"
echo "- Epic: $EPIC_OPTION_ID"
echo "- User Story: $USER_STORY_OPTION_ID"

echo "🔍 Getting all project items..."
PROJECT_ITEMS=$(get_project_items "$PROJECT_ID")

echo "🔄 Processing project items..."
SUCCESS_COUNT=0
FAILURE_COUNT=0
ALREADY_SET=0

# Process each item
echo "$PROJECT_ITEMS" | jq -c '.[]' | while read -r ITEM; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  CONTENT=$(echo "$ITEM" | jq -r '.content')
  
  # Skip if no content (draft issues)
  if [ "$CONTENT" = "null" ]; then
    continue
  fi
  
  ISSUE_NUMBER=$(echo "$ITEM" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
  LABELS=$(echo "$ITEM" | jq -r '.content.labels.nodes[].name' 2>/dev/null || echo "")
  
  echo "Processing #$ISSUE_NUMBER: $ISSUE_TITLE"
  
  # Determine type based on labels
  TYPE_OPTION_ID=""
  if echo "$LABELS" | grep -q "epic"; then
    TYPE_OPTION_ID="$EPIC_OPTION_ID"
    TYPE_NAME="Epic"
  else
    TYPE_OPTION_ID="$USER_STORY_OPTION_ID"
    TYPE_NAME="User Story"
  fi
  
  echo "  Setting type to: $TYPE_NAME"
  
  # Set the type
  RESULT=$(set_item_type "$PROJECT_ID" "$ITEM_ID" "$TYPE_OPTION_ID")
  
  if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
    echo "  ✅ Success"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo ""
echo "🏁 Finished setting types for project items!"
echo "✅ Updated: $SUCCESS_COUNT items"
echo "⚠️ Already set or skipped: $ALREADY_SET items"
echo "❌ Failed: $FAILURE_COUNT items"
echo ""
echo "All issues should now have appropriate types in the project."
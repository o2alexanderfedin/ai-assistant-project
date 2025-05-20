#!/bin/bash

# This script gets the project ID, field ID, and option IDs for the Type field
# Then uses GraphQL to set the types for all issues

# CONFIG
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUMBER=2

# Step 1: Get project ID
echo "🔍 Getting project ID..."
PROJECT_DATA=$(gh api graphql -f query='
  query($owner:String!, $number:Int!) {
    organization(login: $owner) {
      projectV2(number: $number) {
        id
      }
    }
  }' -f owner="$OWNER" -f number=$PROJECT_NUMBER)

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.organization.projectV2.id')
echo "Project ID: $PROJECT_ID"

# Step 2: Get fields and find the Type field ID
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
TYPE_FIELD=$(echo "$FIELDS_DATA" | jq -r '.data.node.fields.nodes[] | select(.name == "Type")')
TYPE_FIELD_ID=$(echo "$TYPE_FIELD" | jq -r '.id')
echo "Type Field ID: $TYPE_FIELD_ID"

# Get option IDs for Epic and User Story
EPIC_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "Epic") | .id')
USER_STORY_OPTION_ID=$(echo "$TYPE_FIELD" | jq -r '.options[] | select(.name == "User Story") | .id')
echo "Epic Option ID: $EPIC_OPTION_ID"
echo "User Story Option ID: $USER_STORY_OPTION_ID"

# Step 3: Get all project items
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
                labels(first: 10) {
                  nodes {
                    name
                  }
                }
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
echo "🔍 Getting all repository issues..."
REPO_ISSUES=$(gh issue list --repo "$OWNER/$REPO" --limit 100 --json number,title,labels)

# Get all epic issues (with epic label)
EPIC_ISSUES=$(echo "$REPO_ISSUES" | jq '[.[] | select(.labels[].name == "epic")]')
EPIC_COUNT=$(echo "$EPIC_ISSUES" | jq length)
echo "Found $EPIC_COUNT epic issues in the repository"

# Get all user story issues (with user-story label)
USER_STORY_ISSUES=$(echo "$REPO_ISSUES" | jq '[.[] | select(.labels[].name == "user-story")]')
USER_STORY_COUNT=$(echo "$USER_STORY_ISSUES" | jq length)
echo "Found $USER_STORY_COUNT user story issues in the repository"

# Process each project item and set its type based on labels
echo "🔄 Setting types for project items..."
PROJECT_ITEMS=$(echo "$ITEMS_DATA" | jq -r '.data.node.items.nodes')
echo "$PROJECT_ITEMS" | jq -c '.[]' | while read -r ITEM; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  CONTENT=$(echo "$ITEM" | jq '.content')
  
  # Skip if no content (e.g., draft issues)
  if [ "$CONTENT" = "null" ]; then
    continue
  fi
  
  ISSUE_NUMBER=$(echo "$ITEM" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
  
  echo "Processing project item for issue #$ISSUE_NUMBER: $ISSUE_TITLE"
  
  # Find the corresponding issue in our repository issues
  ISSUE_DATA=$(echo "$REPO_ISSUES" | jq -r ".[] | select(.number == $ISSUE_NUMBER)")
  
  # Skip if issue not found
  if [ -z "$ISSUE_DATA" ]; then
    echo "  ⚠️ Issue not found in repository data, skipping"
    continue
  fi
  
  # Check labels to determine type
  LABELS=$(echo "$ISSUE_DATA" | jq -r '.labels[].name' 2>/dev/null || echo "")
  
  if echo "$LABELS" | grep -q "epic"; then
    OPTION_ID="$EPIC_OPTION_ID"
    TYPE_NAME="Epic"
  else
    OPTION_ID="$USER_STORY_OPTION_ID"
    TYPE_NAME="User Story"
  fi
  
  echo "  Setting type to $TYPE_NAME"
  
  # Set the type field
  MUTATION=$(gh api graphql -f query='
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
    echo "  ✅ Successfully set type"
  else
    echo "  ❌ Failed to set type"
  fi
done

echo ""
echo "🏁 Finished setting types for all project items!"
echo ""
echo "All issues should now have appropriate types in the project."
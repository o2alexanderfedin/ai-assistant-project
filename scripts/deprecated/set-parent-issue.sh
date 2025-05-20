#!/bin/bash
# set-parent-issue.sh
# Script to set the Parent issue field for a specific issue

set -e  # Exit on error

# Configuration
PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"
ORG_OR_USER="o2alexanderfedin"

# Arguments
CHILD_NUM=$1
PARENT_NUM=$2

if [ -z "$CHILD_NUM" ] || [ -z "$PARENT_NUM" ]; then
  echo "Usage: ./set-parent-issue.sh <child_issue_number> <parent_issue_number>"
  echo "Example: ./set-parent-issue.sh 66 1"
  exit 1
fi

echo "🔍 Setting Parent issue field for issue #$CHILD_NUM to parent #$PARENT_NUM in Project #$PROJECT_NUM..."

# Get project ID
echo "Getting project information..."
PROJECT_DATA=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
      id
      title
    }
  }
}')

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')
PROJECT_TITLE=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.title')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Could not find project #$PROJECT_NUM. Please check the project number."
  exit 1
fi

echo "Found project: $PROJECT_TITLE (ID: $PROJECT_ID)"

# Get parent issue ID
echo "Getting parent issue #$PARENT_NUM..."
PARENT_DATA=$(gh issue view $PARENT_NUM --json id,number,title --repo "$REPO")
PARENT_ISSUE_ID=$(echo "$PARENT_DATA" | jq -r '.id')
PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')

if [ -z "$PARENT_ISSUE_ID" ]; then
  echo "❌ Could not find parent issue #$PARENT_NUM."
  exit 1
fi

echo "Found parent: #$PARENT_NUM '$PARENT_TITLE' (ID: $PARENT_ISSUE_ID)"

# Get child issue item ID from project
echo "Getting child issue #$CHILD_NUM in project..."
CHILD_ITEM_DATA=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
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
}')

CHILD_ITEM_ID=$(echo "$CHILD_ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number == $CHILD_NUM) | .id")
CHILD_ISSUE_ID=$(echo "$CHILD_ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number == $CHILD_NUM) | .content.id")
CHILD_TITLE=$(echo "$CHILD_ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number == $CHILD_NUM) | .content.title")

if [ -z "$CHILD_ITEM_ID" ]; then
  echo "❌ Could not find issue #$CHILD_NUM in project #$PROJECT_NUM."
  exit 1
fi

echo "Found child: #$CHILD_NUM '$CHILD_TITLE' (Item ID: $CHILD_ITEM_ID, Issue ID: $CHILD_ISSUE_ID)"

# Get the field ID for the built-in Parent field
echo "Getting Parent issue field ID..."
FIELD_DATA=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
      field(name: "Parent issue") {
        ... on ProjectV2Field {
          id
          name
        }
      }
    }
  }
}')

PARENT_FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.field.id')

if [ -z "$PARENT_FIELD_ID" ]; then
  echo "⚠️ Could not find Parent issue field ID. Using built-in field ID 'PARENT' instead."
  PARENT_FIELD_ID="PARENT"
fi

echo "Parent issue field ID: $PARENT_FIELD_ID"

# Try to set the parent issue field
echo "Setting Parent issue field..."
echo "Approach 1: Using explicit mutation..."

# Approach 1: Use explicit GraphQL mutation
MUTATION=$(cat <<EOF
mutation {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: "$PROJECT_ID"
      itemId: "$CHILD_ITEM_ID"
      fieldId: "$PARENT_FIELD_ID"
      value: {
        projectV2Item: "$PARENT_ISSUE_ID"
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
EOF
)

# Print the mutation for debugging
if [ -n "$DEBUG" ]; then
  echo "Mutation:"
  echo "$MUTATION"
fi

RESULT=$(echo "$MUTATION" | gh api graphql -f query=@- 2>&1)

if [ $? -eq 0 ] && ! echo "$RESULT" | grep -q "error"; then
  echo "✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM (Approach 1)"
  exit 0
else
  echo "❌ Approach 1 failed"
  echo "Error: $RESULT"
  
  # Approach 2: Use variables
  echo "Approach 2: Using variables..."
  
  # Debug variables
  if [ -n "$DEBUG" ]; then
    echo "Variables:"
    echo "PROJECT_ID: $PROJECT_ID"
    echo "CHILD_ITEM_ID: $CHILD_ITEM_ID"
    echo "PARENT_FIELD_ID: $PARENT_FIELD_ID"
    echo "PARENT_ISSUE_ID: $PARENT_ISSUE_ID"
  fi
  
  ALT_RESULT=$(gh api graphql -f query='
    mutation($project:ID!, $item:ID!, $field:ID!, $parentId:ID!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $project
          itemId: $item
          fieldId: $field
          value: { 
            projectV2Item: $parentId
          }
        }
      ) {
        projectV2Item {
          id
        }
      }
    }
  ' -F project="$PROJECT_ID" -F item="$CHILD_ITEM_ID" -F field="$PARENT_FIELD_ID" -F parentId="$PARENT_ISSUE_ID" 2>&1)
  
  if [ $? -eq 0 ] && ! echo "$ALT_RESULT" | grep -q "error"; then
    echo "✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM (Approach 2)"
    exit 0
  else
    echo "❌ Approach 2 failed"
    echo "Error: $ALT_RESULT"
    
    # Approach 3: Use an item ID instead of issue ID
    echo "Approach 3: Using parent item ID instead of issue ID..."
    
    # Get parent item ID
    PARENT_ITEM_ID=$(echo "$CHILD_ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number == $PARENT_NUM) | .id")
    
    if [ -z "$PARENT_ITEM_ID" ]; then
      echo "❌ Could not find parent item ID for issue #$PARENT_NUM in project #$PROJECT_NUM."
      exit 1
    fi
    
    echo "Parent item ID: $PARENT_ITEM_ID"
    
    LAST_RESULT=$(gh api graphql -f query='
      mutation($project:ID!, $item:ID!, $field:ID!, $parentItem:ID!) {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: $project
            itemId: $item
            fieldId: $field
            value: { 
              projectV2Item: $parentItem
            }
          }
        ) {
          projectV2Item {
            id
          }
        }
      }
    ' -F project="$PROJECT_ID" -F item="$CHILD_ITEM_ID" -F field="$PARENT_FIELD_ID" -F parentItem="$PARENT_ITEM_ID" 2>&1)
    
    if [ $? -eq 0 ] && ! echo "$LAST_RESULT" | grep -q "error"; then
      echo "✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM (Approach 3)"
      exit 0
    else
      echo "❌ Approach 3 failed"
      echo "Error: $LAST_RESULT"
      
      echo "❌ All approaches failed to set the Parent issue field."
      echo "Please set the relationship manually in the GitHub UI:"
      echo "1. Go to: https://github.com/users/$ORG_OR_USER/projects/$PROJECT_NUM"
      echo "2. Find issue #$CHILD_NUM and set its Parent issue field to #$PARENT_NUM"
      exit 1
    fi
  fi
fi
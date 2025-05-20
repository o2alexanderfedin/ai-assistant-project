#!/bin/bash

# Comprehensive script to ensure all GitHub issues are properly migrated to the project
# including their type, parent relationships, and other metadata

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

# Known parent-child relationships (epic number => array of child issue numbers)
# This will be used for setting parent relationships
declare -A PARENT_RELATIONSHIPS=(
  # Core Agent System (Epic #1)
  ["1"]="66,65,64,63,62,61,60,59"
  
  # MCP Implementation (Epic #2)
  ["2"]="17,18,19,20,21,22,23,24"
  
  # Specialized Agent Implementation (Epic #3)
  ["3"]="54,55,56,57,58"
  
  # Agent Task Workflow (Epic #4)
  ["4"]="25,26,27,28,29,30,31,32"
  
  # Shared Component Implementation (Epic #5)
  ["5"]="33,34,35,36,37,38,39,40"
  
  # External Integration Implementation (Epic #6)
  ["6"]="41,42,43,44,45,46,47"
  
  # System Testing and Quality Assurance (Epic #7)
  ["7"]="48,49,50,51,52,53"
)

# Function to set parent epic for a child issue
set_parent_relationship() {
  local PARENT_ID=$1
  local CHILD_ID=$2
  
  echo "  Setting parent relationship: Parent #$PARENT_ID for Child #$CHILD_ID"
  
  # Get the parent and child issue node IDs
  PARENT_NODE_ID=$(gh api graphql -f query='
    query($owner:String!, $repo:String!, $number:Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          id
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -f number=$PARENT_ID | jq -r '.data.repository.issue.id')
    
  CHILD_NODE_ID=$(gh api graphql -f query='
    query($owner:String!, $repo:String!, $number:Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          id
        }
      }
    }' -f owner="$OWNER" -f repo="$REPO" -f number=$CHILD_ID | jq -r '.data.repository.issue.id')
  
  # Set the parent-child relationship using addSubIssue mutation
  RESULT=$(gh api graphql -f query='
    mutation($parentId:ID!, $childId:ID!) {
      addSubIssue(input: {
        issueId: $parentId,
        subIssueId: $childId,
        replaceParent: true
      }) {
        issue { number, title }
        subIssue { number, title }
      }
    }' -f parentId="$PARENT_NODE_ID" -f childId="$CHILD_NODE_ID")
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully set parent relationship"
  else
    echo "  ❌ Failed to set parent relationship"
  fi
}

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

# Set parent relationships for all user stories
echo "🔄 Setting parent relationships..."
for PARENT_ID in "${!PARENT_RELATIONSHIPS[@]}"; do
  CHILDREN="${PARENT_RELATIONSHIPS[$PARENT_ID]}"
  echo "Processing parent #$PARENT_ID with children: $CHILDREN"
  
  # Process each child
  IFS=',' read -ra CHILD_ARRAY <<< "$CHILDREN"
  for CHILD_ID in "${CHILD_ARRAY[@]}"; do
    set_parent_relationship "$PARENT_ID" "$CHILD_ID"
  done
done

echo ""
echo "🏁 Finished comprehensive migration of all issues to project!"
echo ""
echo "All issues should now be in the project with correct types and parent relationships."
#!/bin/bash

# This script updates all items in a project to use the custom Parent Link field
# based on known parent-child relationships

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="1"  # Adjust to your project number
FIELD_NAME="Parent Link"  # Name of your custom field

# Known parent-child relationships
declare -A PARENT_RELATIONSHIPS=(
  # Core Agent System (Epic #1)
  ["66"]="1"  # Secure Agent Creation
  ["65"]="1"  # Agent Template Management
  ["64"]="1"  # Agent Instance Creation
  ["63"]="1"  # Task Classification and Prioritization
  ["62"]="1"  # Task Analysis and Agent Matching
  ["61"]="1"  # Orchestrator MCP Communication
  ["60"]="1"  # Agent Lifecycle Management
  ["59"]="1"  # GitHub Task Monitoring
  
  # Specialized Agent Implementation (Epic #3)
  ["58"]="3"  # Implement DevOps Agent
  ["57"]="3"  # Implement Documentation Agent
  ["56"]="3"  # Implement Tester Agent
  ["55"]="3"  # Implement Reviewer Agent
  ["54"]="3"  # Implement Developer Agent
  
  # System Testing and Quality Assurance (Epic #7)
  ["53"]="7"  # Implement Shared Component Unit Tests
  ["52"]="7"  # Develop Core Agent Unit Tests
  ["51"]="7"  # Implement Test Coverage Tracking and Reporting
  ["50"]="7"  # Set Up GitHub Actions Testing Pipeline
  ["49"]="7"  # Create MCP Protocol Test Suite
  ["48"]="7"  # Implement BATS Testing Framework
  
  # Test issues
  ["72"]="71"  # Test Child Issue
  ["73"]="71"  # Test Sub-Issue Creation
)

# ----------- VALIDATE AUTHENTICATION ----------- #
echo "🔑 Validating GitHub authentication..."
gh auth status > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub authentication failed. Please run 'gh auth login' first."
  echo "🔑 Also ensure token has 'project' scope: gh auth refresh -h github.com -s project"
  exit 1
fi

# ----------- GET PROJECT INFO ----------- #
echo "📋 Getting project information..."

# Get project ID
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi
echo "Found project ID: $PROJECT_ID"

# Get field ID for "Parent Link"
echo "🔍 Getting field ID for '$FIELD_NAME'..."
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
  echo "❌ Field '$FIELD_NAME' not found. Please create it first."
  exit 1
fi
echo "Found field ID: $FIELD_ID"

# ----------- UPDATE PARENT LINKS ----------- #
echo "🔄 Updating parent links for all issues..."
SUCCESS_COUNT=0
FAILURE_COUNT=0

for CHILD_NUM in "${!PARENT_RELATIONSHIPS[@]}"; do
  PARENT_NUM="${PARENT_RELATIONSHIPS[$CHILD_NUM]}"
  echo "Processing: Child #$CHILD_NUM → Parent #$PARENT_NUM"
  
  # Get parent issue details
  PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  ❌ Parent issue #$PARENT_NUM not found, skipping"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
  
  # Create parent link
  PARENT_URL="https://github.com/$OWNER/$REPO/issues/$PARENT_NUM"
  PARENT_LINK="[#$PARENT_NUM]($PARENT_URL) - $PARENT_TITLE"
  
  # Get child item ID in project
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
    echo "  ❌ Child issue #$CHILD_NUM not found in project, adding it..."
    gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$CHILD_NUM" &>/dev/null
    
    # Try to get the item ID again
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
      echo "  ❌ Still couldn't find child issue #$CHILD_NUM in project, skipping"
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      continue
    fi
  fi
  
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
    echo "  ✅ Successfully set parent link for #$CHILD_NUM → #$PARENT_NUM"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to set parent link for #$CHILD_NUM"
    echo "  Error: $RESULT"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo ""
echo "🎉 Completed updating parent links:"
echo "✅ Successfully updated: $SUCCESS_COUNT issues"
echo "❌ Failed to update: $FAILURE_COUNT issues"
echo ""
echo "💡 You can now create views grouped by the '$FIELD_NAME' field to see child issues under their parents"
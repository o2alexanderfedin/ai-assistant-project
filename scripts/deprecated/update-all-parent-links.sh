#!/bin/bash

# This script updates all child issues with parent links based on established relationships

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number 
FIELD_ID="PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y"  # ID of "Parent Link" field

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
  ["74"]="71"  # Test Child Issue with Parent Link
)

# ----------- SETUP ----------- #
echo "🔍 Setting up..."

# Get project ID 
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi
echo "Found project ID: $PROJECT_ID"

# GraphQL mutation template
MUTATION='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
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
'

# ----------- PROCESS ISSUES ----------- #
echo "🔄 Processing parent-child relationships..."
echo "Found ${#PARENT_RELATIONSHIPS[@]} relationships to process"

# Get list of project items for quick lookup
echo "📋 Getting all project items..."
ITEMS_LIST=$(gh project item-list $PROJECT_NUM --owner $OWNER --limit 100)

SUCCESS_COUNT=0
FAILURE_COUNT=0

# Process each parent-child relationship
for CHILD_NUM in "${!PARENT_RELATIONSHIPS[@]}"; do
  PARENT_NUM="${PARENT_RELATIONSHIPS[$CHILD_NUM]}"
  
  echo "--------------------------------------------"
  echo "Processing: Child #$CHILD_NUM → Parent #$PARENT_NUM"
  
  # Get parent details
  PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  ❌ Parent issue #$PARENT_NUM not found, skipping"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
  echo "  Found parent: #$PARENT_NUM '$PARENT_TITLE'"
  
  # Get child details
  CHILD_DATA=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json number,title 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  ❌ Child issue #$CHILD_NUM not found, skipping"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  CHILD_TITLE=$(echo "$CHILD_DATA" | jq -r '.title')
  echo "  Found child: #$CHILD_NUM '$CHILD_TITLE'"
  
  # Create parent link format
  PARENT_URL="https://github.com/$OWNER/$REPO/issues/$PARENT_NUM"
  PARENT_LINK="[#$PARENT_NUM]($PARENT_URL) - $PARENT_TITLE"
  
  # Check if child is in project, add if not
  ITEM_ID=$(echo "$ITEMS_LIST" | grep "Issue.*$CHILD_NUM.*$OWNER/$REPO" | awk '{print $NF}')
  if [ -z "$ITEM_ID" ]; then
    echo "  🔸 Adding issue #$CHILD_NUM to project..."
    gh project item-add $PROJECT_NUM --owner $OWNER --url "https://github.com/$OWNER/$REPO/issues/$CHILD_NUM" &>/dev/null
    
    # Get updated items list
    ITEMS_LIST=$(gh project item-list $PROJECT_NUM --owner $OWNER --limit 100)
    ITEM_ID=$(echo "$ITEMS_LIST" | grep "Issue.*$CHILD_NUM.*$OWNER/$REPO" | awk '{print $NF}')
    
    if [ -z "$ITEM_ID" ]; then
      echo "  ❌ Could not add issue #$CHILD_NUM to project, skipping"
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      continue
    fi
  fi
  echo "  Found item ID: $ITEM_ID"
  
  # Set parent link field with GraphQL mutation
  echo "  🔗 Setting parent link field..."
  RESULT=$(gh api graphql \
    -f query="$MUTATION" \
    -f projectId="$PROJECT_ID" \
    -f itemId="$ITEM_ID" \
    -f fieldId="$FIELD_ID" \
    -f text="$PARENT_LINK")
  
  if [[ "$RESULT" == *"projectV2Item"* ]]; then
    echo "  ✅ Successfully set parent link"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to set parent link: $RESULT"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo "--------------------------------------------"
echo "🏁 Finished processing all relationships!"
echo "✅ Success: $SUCCESS_COUNT issues"
echo "❌ Failed: $FAILURE_COUNT issues"
echo ""
echo "You can now create views in GitHub Projects to group issues by the Parent Link field."
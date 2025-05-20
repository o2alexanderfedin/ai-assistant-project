#!/bin/bash

# This script updates all parent-child relationships using the addSubIssue GraphQL mutation

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

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
  
  # Epic Prioritization (Epic #8)
  ["49"]="8"  # Also link to this epic for testing
  ["48"]="8"  # Also link to this epic for testing
  
  # Test issues
  ["72"]="71"  # Test Child Issue
  ["73"]="71"  # Test Sub-Issue Creation
  ["74"]="71"  # Test Child Issue with Parent Link
)

# ----------- SETUP ----------- #
echo "🔍 Setting up..."

# GraphQL mutation template
MUTATION='
mutation($parentId:ID!, $childId:ID!) {
  addSubIssue(input: {
    issueId: $parentId,
    subIssueId: $childId,
    replaceParent: true
  }) {
    issue {
      number
      title
    }
    subIssue {
      number
      title
    }
  }
}
'

# ----------- PROCESS ISSUES ----------- #
echo "🔄 Processing parent-child relationships..."
echo "Found ${#PARENT_RELATIONSHIPS[@]} relationships to process"

SUCCESS_COUNT=0
FAILURE_COUNT=0

# Process each parent-child relationship
for CHILD_NUM in "${!PARENT_RELATIONSHIPS[@]}"; do
  PARENT_NUM="${PARENT_RELATIONSHIPS[$CHILD_NUM]}"
  
  echo "--------------------------------------------"
  echo "Processing: Child #$CHILD_NUM → Parent #$PARENT_NUM"
  
  # Get parent details
  PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  ❌ Parent issue #$PARENT_NUM not found, skipping"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  PARENT_ID=$(echo "$PARENT_DATA" | jq -r '.id')
  PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
  echo "  Found parent: #$PARENT_NUM '$PARENT_TITLE' (ID: $PARENT_ID)"
  
  # Get child details
  CHILD_DATA=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  ❌ Child issue #$CHILD_NUM not found, skipping"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  CHILD_ID=$(echo "$CHILD_DATA" | jq -r '.id')
  CHILD_TITLE=$(echo "$CHILD_DATA" | jq -r '.title')
  echo "  Found child: #$CHILD_NUM '$CHILD_TITLE' (ID: $CHILD_ID)"
  
  # Add sub-issue relationship
  echo "  🔗 Adding sub-issue relationship..."
  RESULT=$(gh api graphql \
    -f query="$MUTATION" \
    -f parentId="$PARENT_ID" \
    -f childId="$CHILD_ID" 2>/dev/null)
  
  if [[ "$RESULT" == *"issue"* && "$RESULT" == *"subIssue"* ]]; then
    echo "  ✅ Successfully added sub-issue relationship"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to add sub-issue relationship: $RESULT"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo "--------------------------------------------"
echo "🏁 Finished processing all relationships!"
echo "✅ Success: $SUCCESS_COUNT relationships"
echo "❌ Failed: $FAILURE_COUNT relationships"
echo ""
echo "The sub-issue relationships have been established in GitHub."
echo "You should be able to see these relationships in the issue UI and in Projects."
#!/bin/bash

# This script assigns parent epics to orphaned user stories

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# Mapping of user stories to parent epics
declare -A PARENT_MAPPING=(
  # External Integration Implementation (Epic #6)
  ["47"]="6"  # Create Documentation for External Integrations
  ["46"]="6"  # Create Integration Tests
  ["45"]="6"  # Implement Error Handling and Monitoring
  ["44"]="6"  # Implement Secure Credential Management
  ["43"]="6"  # Implement Development Environment
  ["42"]="6"  # Implement CI/CD Connector
  ["41"]="6"  # Implement GitHub Connector
  
  # Shared Component Implementation (Epic #5)
  ["40"]="5"  # Document all Shared Components
  ["39"]="5"  # Integrate all Shared Components
  ["38"]="5"  # Implement Performance Metrics component
  ["37"]="5"  # Implement Knowledge Base component
  
  # System Testing and Quality Assurance (Epic #7)
  ["46"]="7"  # Create Integration Tests (adding another parent)
)

# ----------- PROCESS ISSUES ----------- #
echo "🔄 Assigning parent issues to orphaned user stories..."
echo "Found ${#PARENT_MAPPING[@]} relationships to process"

SUCCESS_COUNT=0
FAILURE_COUNT=0

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

# Process each parent-child relationship
for CHILD_NUM in "${!PARENT_MAPPING[@]}"; do
  PARENT_NUM="${PARENT_MAPPING[$CHILD_NUM]}"
  
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
echo "🏁 Finished assigning parent issues!"
echo "✅ Success: $SUCCESS_COUNT relationships"
echo "❌ Failed: $FAILURE_COUNT relationships"
echo ""
echo "All user stories should now have their parent issues assigned."
echo "You can verify this in the GitHub UI or Projects view."
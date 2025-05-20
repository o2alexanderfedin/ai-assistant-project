#!/bin/bash

# Set parent-child relationships for issues missing parents in the screenshot
# Using the required GraphQL-Features header for sub_issues

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# Define parent-child relationships based on the screenshot
# Format: "parent_num:child_num"
RELATIONSHIPS=(
  "1:13"  # Task Classification and Prioritization
  "1:14"  # Agent Instance Creation
  "1:15"  # Agent Template Management
  "1:12"  # Task Analysis and Agent Matching
  "1:10"  # Agent Lifecycle Management
  "1:11"  # Orchestrator MCP Communication
  "1:16"  # Secure Agent Creation
  "1:9"   # GitHub Task Monitoring (already done but included for completeness)
)

# GraphQL mutation template
MUTATION='
mutation($parentId:ID!, $childId:ID!) {
  addSubIssue(input: {
    issueId: $parentId,
    subIssueId: $childId,
    replaceParent: true
  }) {
    issue { number, title }
    subIssue { number, title }
  }
}'

# Process each parent-child relationship
for RELATION in "${RELATIONSHIPS[@]}"; do
  # Split the relation into parent and child
  PARENT_NUM=$(echo "$RELATION" | cut -d':' -f1)
  CHILD_NUM=$(echo "$RELATION" | cut -d':' -f2)
  
  echo "--------------------------------------------"
  echo "Setting parent #$PARENT_NUM for child #$CHILD_NUM"
  
  # Get parent details
  PARENT_RESPONSE=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,title)
  PARENT_ID=$(echo "$PARENT_RESPONSE" | jq -r '.id')
  PARENT_TITLE=$(echo "$PARENT_RESPONSE" | jq -r '.title')
  
  echo "Parent issue: #$PARENT_NUM - $PARENT_TITLE"
  echo "Parent ID: $PARENT_ID"
  
  # Get child details
  CHILD_RESPONSE=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,title)
  CHILD_ID=$(echo "$CHILD_RESPONSE" | jq -r '.id')
  CHILD_TITLE=$(echo "$CHILD_RESPONSE" | jq -r '.title')
  
  echo "Child issue: #$CHILD_NUM - $CHILD_TITLE"
  echo "Child ID: $CHILD_ID"
  
  # Set the parent-child relationship with the required header
  RESULT=$(gh api graphql \
    -H "GraphQL-Features: sub_issues" \
    -f query="$MUTATION" \
    -f parentId="$PARENT_ID" \
    -f childId="$CHILD_ID" 2>/dev/null)
  
  if [ $? -eq 0 ] && [ -z "$(echo "$RESULT" | grep "error")" ]; then
    if [[ "$RESULT" == *"addSubIssue"* ]]; then
      echo "✅ Successfully set parent relationship"
      CHILD_TITLE_RESULT=$(echo "$RESULT" | jq -r '.data.addSubIssue.subIssue.title')
      PARENT_TITLE_RESULT=$(echo "$RESULT" | jq -r '.data.addSubIssue.issue.title')
      echo "Parent: $PARENT_TITLE_RESULT"
      echo "Child: $CHILD_TITLE_RESULT"
    else
      echo "ℹ️ Response without error but unexpected format: $RESULT"
    fi
  else
    if echo "$RESULT" | grep -q "duplicate sub-issues"; then
      echo "ℹ️ Relationship already exists"
    else
      echo "❌ Failed to set parent relationship"
      echo "$RESULT"
    fi
  fi
  
  # Add a small delay to avoid rate limiting
  sleep 1
done

echo "--------------------------------------------"
echo "🏁 Finished setting parent-child relationships for all issues!"
echo "Verify the changes in the GitHub UI."
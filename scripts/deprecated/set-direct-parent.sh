#!/bin/bash

# Set parent relationship for a single child issue using direct IDs
# Usage: ./set-direct-parent.sh <parent_issue_number> <child_issue_number>

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# Get command line arguments
PARENT_NUM=$1
CHILD_NUM=$2

if [ -z "$PARENT_NUM" ] || [ -z "$CHILD_NUM" ]; then
  echo "Usage: $0 <parent_issue_number> <child_issue_number>"
  exit 1
fi

echo "Setting parent relationship: Parent #$PARENT_NUM for Child #$CHILD_NUM"

# Get the parent issue node ID directly
echo "Getting parent issue node ID..."
PARENT_RESPONSE=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,title)
PARENT_ID=$(echo "$PARENT_RESPONSE" | jq -r '.id')
PARENT_TITLE=$(echo "$PARENT_RESPONSE" | jq -r '.title')

echo "Parent issue: #$PARENT_NUM - $PARENT_TITLE"
echo "Parent ID: $PARENT_ID"

# Get the child issue node ID directly
echo "Getting child issue node ID..."
CHILD_RESPONSE=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,title)
CHILD_ID=$(echo "$CHILD_RESPONSE" | jq -r '.id')
CHILD_TITLE=$(echo "$CHILD_RESPONSE" | jq -r '.title')

echo "Child issue: #$CHILD_NUM - $CHILD_TITLE"
echo "Child ID: $CHILD_ID"

# Set the parent-child relationship using addSubIssue mutation
echo "Setting parent relationship..."
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
  }' -f parentId="$PARENT_ID" -f childId="$CHILD_ID")

if [ $? -eq 0 ]; then
  SUB_ISSUE_TITLE=$(echo "$RESULT" | jq -r '.data.addSubIssue.subIssue.title')
  PARENT_ISSUE_TITLE=$(echo "$RESULT" | jq -r '.data.addSubIssue.issue.title')
  echo "✅ Successfully set parent relationship"
  echo "Parent: $PARENT_ISSUE_TITLE"
  echo "Child: $SUB_ISSUE_TITLE"
else
  echo "❌ Failed to set parent relationship"
  echo "$RESULT"
fi
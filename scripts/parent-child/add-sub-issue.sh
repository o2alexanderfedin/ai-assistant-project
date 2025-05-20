#!/bin/bash

# This script uses the addSubIssue GraphQL mutation to set up parent-child relationships

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# ----------- INPUT ----------- #
PARENT_NUM="$1"
CHILD_NUM="$2"

if [[ -z "$PARENT_NUM" || -z "$CHILD_NUM" ]]; then
  echo "Usage: $0 <parent_issue_number> <child_issue_number>"
  echo "Example: $0 1 63"
  exit 1
fi

# ----------- VERIFY ISSUES ----------- #
echo "🔍 Verifying issues..."

# Verify parent issue
PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Parent issue #$PARENT_NUM not found"
  exit 1
fi
PARENT_ID=$(echo "$PARENT_DATA" | jq -r '.id')
PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
echo "Found parent: #$PARENT_NUM '$PARENT_TITLE' (ID: $PARENT_ID)"

# Verify child issue
CHILD_DATA=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Child issue #$CHILD_NUM not found"
  exit 1
fi
CHILD_ID=$(echo "$CHILD_DATA" | jq -r '.id')
CHILD_TITLE=$(echo "$CHILD_DATA" | jq -r '.title')
echo "Found child: #$CHILD_NUM '$CHILD_TITLE' (ID: $CHILD_ID)"

# ----------- ADD SUB-ISSUE ----------- #
echo "🔗 Adding sub-issue relationship..."

# Create a mutation with variables
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

# Execute the mutation with variables
RESULT=$(gh api graphql \
  -f query="$MUTATION" \
  -f parentId="$PARENT_ID" \
  -f childId="$CHILD_ID")

if [[ "$RESULT" == *"issue"* && "$RESULT" == *"subIssue"* ]]; then
  echo "✅ Successfully added issue #$CHILD_NUM as a sub-issue of #$PARENT_NUM"
  echo "$RESULT" | jq '.'
else
  echo "❌ Failed to add sub-issue"
  echo "Error: $RESULT"
  exit 1
fi

echo ""
echo "💡 The sub-issue relationship has been established in GitHub"
echo "🔗 You should be able to see this relationship in the UI"
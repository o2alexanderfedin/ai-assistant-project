#!/bin/bash

# This script creates a new issue and adds it as a sub-issue of a parent

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# ----------- INPUT ----------- #
PARENT_NUM="$1"
TITLE="$2"
BODY="$3"
LABELS="${4:-user-story}"

if [[ -z "$PARENT_NUM" || -z "$TITLE" ]]; then
  echo "Usage: $0 <parent_issue_number> \"Title\" \"Body\" \"label1,label2,...\""
  echo "Example: $0 1 \"Implement feature X\" \"This is a description\" \"user-story,priority:high\""
  exit 1
fi

# ----------- VERIFY PARENT ----------- #
echo "🔍 Verifying parent issue #$PARENT_NUM..."
PARENT_DATA=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ Parent issue #$PARENT_NUM not found"
  exit 1
fi

PARENT_ID=$(echo "$PARENT_DATA" | jq -r '.id')
PARENT_TITLE=$(echo "$PARENT_DATA" | jq -r '.title')
echo "Found parent: #$PARENT_NUM '$PARENT_TITLE' (ID: $PARENT_ID)"

# ----------- CREATE CHILD ISSUE ----------- #
echo "📝 Creating issue '$TITLE'..."

# Add reference to parent in the body
FULL_BODY="$BODY

---
Parent Issue: #$PARENT_NUM"

ISSUE_URL=$(gh issue create --repo $OWNER/$REPO --title "$TITLE" --body "$FULL_BODY" --label "$LABELS")

if [ $? -ne 0 ]; then
  echo "❌ Failed to create issue"
  exit 1
fi

CHILD_NUM=$(echo $ISSUE_URL | grep -o '[0-9]*$')
echo "✅ Created issue #$CHILD_NUM: $ISSUE_URL"

# ----------- ADD SUB-ISSUE RELATIONSHIP ----------- #
echo "🔗 Adding sub-issue relationship..."

# Get child issue ID
CHILD_DATA=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,number,title 2>/dev/null)
CHILD_ID=$(echo "$CHILD_DATA" | jq -r '.id')
CHILD_TITLE=$(echo "$CHILD_DATA" | jq -r '.title')

# Create a mutation with variables
MUTATION='
mutation($parentId:ID!, $childId:ID!) {
  addSubIssue(input: {
    issueId: $parentId,
    subIssueId: $childId
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
else
  echo "❌ Failed to add sub-issue relationship"
  echo "Error: $RESULT"
  echo "The issue was created but couldn't be set as a sub-issue."
  exit 1
fi

# ----------- ADD TO PROJECT ----------- #
PROJECT_NUM=2  # Adjust to your project number
echo "📋 Adding issue to project #$PROJECT_NUM..."
gh project item-add $PROJECT_NUM --owner $OWNER --url "$ISSUE_URL" &>/dev/null

echo ""
echo "🎉 Issue #$CHILD_NUM created successfully as a sub-issue of #$PARENT_NUM"
echo "🔗 Issue URL: $ISSUE_URL"
echo "⏩ The parent-child relationship is visible in the GitHub UI"
echo "📋 The issue has been added to project #$PROJECT_NUM"
#!/bin/bash

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# ----------- INPUT ----------- #
PARENT_NUM="$1"
CHILD_NUM="$2"

if [[ -z "$PARENT_NUM" || -z "$CHILD_NUM" ]]; then
  echo "Usage: $0 <parent_issue_number> <child_issue_number>"
  echo "Example: $0 1 66"
  exit 1
fi

# ----------- GET NODE IDs ----------- #
echo "🔍 Getting issue IDs for parent #$PARENT_NUM and child #$CHILD_NUM..."

QUERY=$(cat <<EOF
{
  repository(owner: "$OWNER", name: "$REPO") {
    parent: issue(number: $PARENT_NUM) { id title }
    child: issue(number: $CHILD_NUM) { id title }
  }
}
EOF
)

JSON=$(gh api graphql -f query="$QUERY")
PARENT_ID=$(echo $JSON | jq -r '.data.repository.parent.id')
PARENT_TITLE=$(echo $JSON | jq -r '.data.repository.parent.title')
CHILD_ID=$(echo $JSON | jq -r '.data.repository.child.id')
CHILD_TITLE=$(echo $JSON | jq -r '.data.repository.child.title')

if [[ -z "$PARENT_ID" || "$PARENT_ID" == "null" ]]; then
  echo "❌ Parent issue #$PARENT_NUM not found"
  exit 2
fi

if [[ -z "$CHILD_ID" || "$CHILD_ID" == "null" ]]; then
  echo "❌ Child issue #$CHILD_NUM not found"
  exit 2
fi

echo "Found parent: #$PARENT_NUM '$PARENT_TITLE' (ID: $PARENT_ID)"
echo "Found child: #$CHILD_NUM '$CHILD_TITLE' (ID: $CHILD_ID)"

# ----------- CREATE RELATION ----------- #
echo "🔗 Creating TRACKS relationship..."
RESULT=$(gh api graphql -f query='
  mutation($parent: ID!, $child: ID!) {
    addIssueRelation(input: {
      sourceId: $parent,
      targetId: $child,
      relationshipType: TRACKS
    }) {
      clientMutationId
    }
  }
' -f parent="$PARENT_ID" -f child="$CHILD_ID")

if [[ "$RESULT" == *"clientMutationId"* ]]; then
  echo "✅ Successfully linked '$PARENT_TITLE' (parent) → '$CHILD_TITLE' (child)"
else
  echo "❌ Failed to create relationship: $RESULT"
  exit 3
fi
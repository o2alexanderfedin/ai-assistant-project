#!/bin/bash

# Part 2: Set parent-child relationships between epics and user stories

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# Known parent-child relationships - each line is parent_id:child_id1,child_id2,...
PARENT_RELATIONSHIPS=(
  "1:66,65,64,63,62,61,60,59"
  "2:17,18,19,20,21,22,23,24"
  "3:54,55,56,57,58"
  "4:25,26,27,28,29,30,31,32"
  "5:33,34,35,36,37,38,39,40"
  "6:41,42,43,44,45,46,47"
  "7:48,49,50,51,52,53"
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

# Process each parent-child relationship
echo "🔄 Setting parent relationships..."
for RELATION in "${PARENT_RELATIONSHIPS[@]}"; do
  # Split the relation into parent and children
  PARENT_ID=$(echo "$RELATION" | cut -d':' -f1)
  CHILDREN=$(echo "$RELATION" | cut -d':' -f2)
  
  echo "Processing parent #$PARENT_ID with children: $CHILDREN"
  
  # Process each child
  IFS=',' read -ra CHILD_ARRAY <<< "$CHILDREN"
  for CHILD_ID in "${CHILD_ARRAY[@]}"; do
    set_parent_relationship "$PARENT_ID" "$CHILD_ID"
  done
done

echo ""
echo "🏁 Finished setting parent-child relationships for all issues!"
echo ""
echo "All issues should now be in the project with correct types and parent relationships."
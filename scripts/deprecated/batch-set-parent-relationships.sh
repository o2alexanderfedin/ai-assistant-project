#!/bin/bash

# Batch set parent-child relationships with direct issue IDs
# This script processes groups of relationships one at a time

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# Define parent-child relationships by parent number and child numbers
# Format: "parent_num:child1,child2,child3,..."
RELATIONSHIPS=(
  "1:66,65,64,63,62,61,60,59"
  "2:17,18,19,20,21,22,23,24"
  "3:54,55,56,57,58"
  "4:25,26,27,28,29,30,31,32"
  "5:33,34,35,36,37,38,39,40"
  "6:41,42,43,44,45,46,47"
  "7:48,49,50,51,52,53"
)

# Process each parent-child relationship
for RELATION in "${RELATIONSHIPS[@]}"; do
  # Split the relation into parent and children
  PARENT_NUM=$(echo "$RELATION" | cut -d':' -f1)
  CHILDREN=$(echo "$RELATION" | cut -d':' -f2)
  
  echo "Processing parent #$PARENT_NUM"
  
  # Get the parent issue node ID
  PARENT_RESPONSE=$(gh issue view $PARENT_NUM --repo $OWNER/$REPO --json id,title)
  PARENT_ID=$(echo "$PARENT_RESPONSE" | jq -r '.id')
  PARENT_TITLE=$(echo "$PARENT_RESPONSE" | jq -r '.title')
  
  echo "Parent issue: #$PARENT_NUM - $PARENT_TITLE"
  echo "Parent ID: $PARENT_ID"
  
  # Process each child
  IFS=',' read -ra CHILD_ARRAY <<< "$CHILDREN"
  for CHILD_NUM in "${CHILD_ARRAY[@]}"; do
    echo "  Setting parent for child #$CHILD_NUM"
    
    # Get the child issue node ID
    CHILD_RESPONSE=$(gh issue view $CHILD_NUM --repo $OWNER/$REPO --json id,title)
    CHILD_ID=$(echo "$CHILD_RESPONSE" | jq -r '.id')
    CHILD_TITLE=$(echo "$CHILD_RESPONSE" | jq -r '.title')
    
    echo "  Child issue: #$CHILD_NUM - $CHILD_TITLE"
    echo "  Child ID: $CHILD_ID"
    
    # Set the parent-child relationship
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
      }' -f parentId="$PARENT_ID" -f childId="$CHILD_ID" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -z "$(echo "$RESULT" | grep "error")" ]; then
      echo "  ✅ Successfully set parent relationship"
    else
      if echo "$RESULT" | grep -q "duplicate sub-issues"; then
        echo "  ℹ️ Relationship already exists"
      else
        echo "  ❌ Failed to set parent relationship"
        echo "  $RESULT"
      fi
    fi
    
    # Add a small delay to avoid rate limiting
    sleep 1
  done
  
  echo ""
done

echo "🏁 Finished setting parent-child relationships for all issues!"
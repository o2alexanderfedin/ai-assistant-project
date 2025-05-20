#!/bin/bash

# This script sets the Type field manually for epics and user stories

# CONFIG
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"

# Get all epics
echo "🔍 Getting all epics..."
EPICS=$(gh issue list --repo "$OWNER/$REPO" --label epic --json number,title)
EPIC_COUNT=$(echo "$EPICS" | jq length)
echo "Found $EPIC_COUNT epics"

# Get all user stories
echo "🔍 Getting all user stories..."
USER_STORIES=$(gh issue list --repo "$OWNER/$REPO" --label user-story --json number,title)
USER_STORY_COUNT=$(echo "$USER_STORIES" | jq length)
echo "Found $USER_STORY_COUNT user stories"

# Get all project items
echo "📋 Getting all project items..."
PROJECT_ITEMS=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER")

# Process epics
echo "🔄 Setting epic types..."
for i in $(seq 0 $((EPIC_COUNT-1))); do
  ISSUE_NUM=$(echo "$EPICS" | jq -r ".[$i].number")
  ISSUE_TITLE=$(echo "$EPICS" | jq -r ".[$i].title")
  
  echo "Processing epic #$ISSUE_NUM: $ISSUE_TITLE"
  
  # Check if this epic is in the project
  if echo "$PROJECT_ITEMS" | grep -q "$ISSUE_TITLE"; then
    echo "  Found in project, setting type to Epic..."
    
    # Get the item ID
    ITEM_ID=$(echo "$PROJECT_ITEMS" | grep -A 1 "$ISSUE_TITLE" | tail -n 1 | awk '{print $1}')
    
    if [ -n "$ITEM_ID" ]; then
      # Set the type to Epic
      gh project item-edit "$ITEM_ID" --project-id "$PROJECT_NUM" --owner "$OWNER" --field "Type" --text "Epic"
      
      if [ $? -eq 0 ]; then
        echo "  ✅ Successfully set type to Epic"
      else
        echo "  ❌ Failed to set type"
      fi
    else
      echo "  ❌ Could not find item ID"
    fi
  else
    echo "  ⚠️ Not found in project, skipping"
  fi
done

# Process user stories
echo "🔄 Setting user story types..."
for i in $(seq 0 $((USER_STORY_COUNT-1))); do
  ISSUE_NUM=$(echo "$USER_STORIES" | jq -r ".[$i].number")
  ISSUE_TITLE=$(echo "$USER_STORIES" | jq -r ".[$i].title")
  
  echo "Processing user story #$ISSUE_NUM: $ISSUE_TITLE"
  
  # Check if this user story is in the project
  if echo "$PROJECT_ITEMS" | grep -q "$ISSUE_TITLE"; then
    echo "  Found in project, setting type to User Story..."
    
    # Get the item ID
    ITEM_ID=$(echo "$PROJECT_ITEMS" | grep -A 1 "$ISSUE_TITLE" | tail -n 1 | awk '{print $1}')
    
    if [ -n "$ITEM_ID" ]; then
      # Set the type to User Story
      gh project item-edit "$ITEM_ID" --project-id "$PROJECT_NUM" --owner "$OWNER" --field "Type" --text "User Story"
      
      if [ $? -eq 0 ]; then
        echo "  ✅ Successfully set type to User Story"
      else
        echo "  ❌ Failed to set type"
      fi
    else
      echo "  ❌ Could not find item ID"
    fi
  else
    echo "  ⚠️ Not found in project, skipping"
  fi
done

echo ""
echo "🏁 Finished setting types for all issues!"
echo ""
echo "All issues should now have appropriate types in the project."
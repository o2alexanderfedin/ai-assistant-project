#!/bin/bash
# GitHub Project Migration Script
# Run this after refreshing your token with: gh auth refresh -h github.com -s project
# Created: $(date +"%Y-%m-%d")
# Purpose: Migrate all epics and user stories to a GitHub Project with proper relationships

set -e  # Exit on error

echo "🚀 Starting GitHub Project migration..."

# Verify we have project scope
echo "🔒 Verifying GitHub token has project scope..."
gh projects list --format json >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Token lacks required scope for projects"
  echo "Please run: gh auth refresh -h github.com -s project"
  exit 1
else
  echo "✅ Token has proper scope for projects"
fi

# Step 1: Create new project
echo "📋 Creating new 'AI Assistant Development' project..."
PROJECT_ID=$(gh projects create --title "AI Assistant Development" \
  --description "Project board for AI Assistant architecture and implementation" \
  --format json | jq -r '.id')

echo "✅ Created project with ID: $PROJECT_ID"

# Step 2: Create custom fields
echo "🏷️ Creating custom fields..."

# Type field (Epic, User Story, Task)
TYPE_FIELD_ID=$(gh projects field-create $PROJECT_ID --name "Type" --data-type "SINGLE_SELECT" \
  --single-select-options "Epic,User Story,Task" --format json | jq -r '.id')
echo "  ✓ Created Type field"

# Priority field
PRIORITY_FIELD_ID=$(gh projects field-create $PROJECT_ID --name "Priority" --data-type "SINGLE_SELECT" \
  --single-select-options "High,Medium,Low" --format json | jq -r '.id')
echo "  ✓ Created Priority field"

# Story Points field
POINTS_FIELD_ID=$(gh projects field-create $PROJECT_ID --name "Story Points" --data-type "NUMBER" \
  --format json | jq -r '.id')
echo "  ✓ Created Story Points field"

# Component field
COMPONENT_FIELD_ID=$(gh projects field-create $PROJECT_ID --name "Component" --data-type "SINGLE_SELECT" \
  --single-select-options "Core Agents,MCP,Workflow,Shared Components,External Integration,Testing" \
  --format json | jq -r '.id')
echo "  ✓ Created Component field"

# Epic Link field - initially empty, will populate after adding epics
EPIC_LINK_FIELD_ID=$(gh projects field-create $PROJECT_ID --name "Epic" --data-type "SINGLE_SELECT" \
  --format json | jq -r '.id')
echo "  ✓ Created Epic Link field"

echo "✅ All custom fields created"

# Step 3: Add epics to the project
echo "📚 Adding epics to project..."

# Get all epics
EPICS=$(gh issue list --label epic --json number,title)
EPIC_COUNT=$(echo $EPICS | jq '. | length')

# Add each epic to the project
for i in $(seq 0 $(($EPIC_COUNT-1))); do
  EPIC_NUMBER=$(echo $EPICS | jq -r ".[$i].number")
  EPIC_TITLE=$(echo $EPICS | jq -r ".[$i].title")
  
  # Add to project
  echo "  ➕ Adding epic #$EPIC_NUMBER: $EPIC_TITLE"
  ITEM_ID=$(gh projects item-add $PROJECT_ID --repo o2alexanderfedin/ai-assistant-project \
    --number $EPIC_NUMBER --format json | jq -r '.id')
  
  # Set Type field to "Epic"
  gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $TYPE_FIELD_ID \
    --single-select-option-id "Epic" >/dev/null
  
  # Add this epic to the Epic Link options for user stories
  gh projects field-edit $PROJECT_ID --field-id $EPIC_LINK_FIELD_ID \
    --add-single-select-option "$EPIC_TITLE" >/dev/null
  
  # Set Component based on labels
  LABELS=$(gh issue view $EPIC_NUMBER --json labels | jq -r '.labels[].name')
  
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT="Workflow"
  elif echo "$LABELS" | grep -q "infrastructure"; then
    if echo "$LABELS" | grep -q "external"; then
      COMPONENT="External Integration"
    else
      COMPONENT="Shared Components"
    fi
  fi
  
  if [ ! -z "$COMPONENT" ]; then
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $COMPONENT_FIELD_ID \
      --single-select-option-id "$COMPONENT" >/dev/null
  fi
  
  # Set Priority based on labels
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  fi
  
  if [ ! -z "$PRIORITY" ]; then
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $PRIORITY_FIELD_ID \
      --single-select-option-id "$PRIORITY" >/dev/null
  fi
  
  echo "  ✓ Epic #$EPIC_NUMBER configured"
done

echo "✅ All epics added to project"

# Step 4: Add user stories
echo "📝 Adding user stories to project..."

# Get all user stories
USER_STORIES=$(gh issue list --label user-story --json number,title,body,labels)
USER_STORY_COUNT=$(echo $USER_STORIES | jq '. | length')

# Add each user story to the project
for i in $(seq 0 $(($USER_STORY_COUNT-1))); do
  STORY_NUMBER=$(echo $USER_STORIES | jq -r ".[$i].number")
  STORY_TITLE=$(echo $USER_STORIES | jq -r ".[$i].title")
  STORY_BODY=$(echo $USER_STORIES | jq -r ".[$i].body")
  
  # Add to project
  echo "  ➕ Adding user story #$STORY_NUMBER: $STORY_TITLE"
  ITEM_ID=$(gh projects item-add $PROJECT_ID --repo o2alexanderfedin/ai-assistant-project \
    --number $STORY_NUMBER --format json | jq -r '.id')
  
  # Set Type field to "User Story"
  gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $TYPE_FIELD_ID \
    --single-select-option-id "User Story" >/dev/null
  
  # Determine parent epic from body text
  PARENT_EPIC=$(echo "$STORY_BODY" | grep -o -E "Epic: #[0-9]+" | cut -d '#' -f 2)
  if [ ! -z "$PARENT_EPIC" ]; then
    PARENT_EPIC_TITLE=$(gh issue view $PARENT_EPIC --json title | jq -r '.title')
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $EPIC_LINK_FIELD_ID \
      --single-select-option-id "$PARENT_EPIC_TITLE" >/dev/null
  fi
  
  # Set Story Points
  POINTS=$(echo "$USER_STORIES" | jq -r ".[$i].labels[] | select(.name | startswith(\"points:\")) | .name" | cut -d ':' -f 2)
  if [ ! -z "$POINTS" ]; then
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $POINTS_FIELD_ID \
      --number "$POINTS" >/dev/null
  fi
  
  # Set Component based on labels
  LABELS=$(echo "$USER_STORIES" | jq -r ".[$i].labels[].name")
  
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT="Workflow"
  elif echo "$LABELS" | grep -q "documentation\|infrastructure"; then
    if echo "$LABELS" | grep -q "external"; then
      COMPONENT="External Integration"
    else
      COMPONENT="Shared Components"
    fi
  elif echo "$LABELS" | grep -q "testing\|test"; then
    COMPONENT="Testing"
  fi
  
  if [ ! -z "$COMPONENT" ]; then
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $COMPONENT_FIELD_ID \
      --single-select-option-id "$COMPONENT" >/dev/null
  fi
  
  # Set Priority based on labels
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  fi
  
  if [ ! -z "$PRIORITY" ]; then
    gh projects item-edit $PROJECT_ID --id $ITEM_ID --field-id $PRIORITY_FIELD_ID \
      --single-select-option-id "$PRIORITY" >/dev/null
  fi
  
  echo "  ✓ User story #$STORY_NUMBER configured"
done

echo "✅ All user stories added to project"

# Step 5: Create useful views
echo "🔍 Creating useful project views..."

echo "🎉 Migration complete! Project URL: https://github.com/users/o2alexanderfedin/projects/$PROJECT_ID"
echo ""
echo "Next steps:"
echo "1. Open the project in your browser"
echo "2. Create useful views (Epics Overview, Stories by Epic, etc.)"
echo "3. Customize the board layout"
echo "4. Set up automation rules if desired"
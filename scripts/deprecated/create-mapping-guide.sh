#!/bin/bash
# Create a comprehensive mapping guide for GitHub Project setup
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

REPO="o2alexanderfedin/ai-assistant-project"
MAPPING_FILE="/tmp/github_project_guide.md"

echo "🚀 Creating GitHub Project mapping guide..."

# Get all issues - epics and user stories
EPICS=$(gh issue list --label epic --json number,title,labels,body --repo "$REPO")
USER_STORIES=$(gh issue list --label user-story --json number,title,labels,body --repo "$REPO")

# Create mapping guide header
cat > "$MAPPING_FILE" << EOL
# GitHub Project Setup Guide

This document provides a comprehensive guide for setting up the GitHub Project for the AI Assistant Development project.

## 1. Project Setup

1. Create a new GitHub Project:
   - Go to: https://github.com/users/o2alexanderfedin?tab=projects
   - Click "New project"
   - Select "Team planning" as the template
   - Name it "AI Assistant Development"
   - Add description: "Project board for AI Assistant architecture and implementation"

2. Add custom fields:
   - **Type**: Single select field with options: Epic, User Story, Task
   - **Priority**: Single select field with options: High, Medium, Low
   - **Story Points**: Number field
   - **Component**: Single select field with options: Core Agents, MCP, Workflow, Shared Components, External Integration, Testing
   - **Epic**: Single select field with the following options:
EOL

# Add epic options
echo "$EPICS" | jq -c '.[]' | while read -r EPIC; do
  EPIC_NUM=$(echo "$EPIC" | jq -r '.number')
  EPIC_TITLE=$(echo "$EPIC" | jq -r '.title')
  echo "     - $EPIC_TITLE" >> "$MAPPING_FILE"
done

# Add epic mappings section
cat >> "$MAPPING_FILE" << EOL

## 2. Epic Mappings

The following epics should be added to the project and configured with these fields:

| Epic # | Title | Type | Priority | Component |
|--------|-------|------|----------|-----------|
EOL

# Process each epic
echo "$EPICS" | jq -c '.[]' | while read -r EPIC; do
  EPIC_NUM=$(echo "$EPIC" | jq -r '.number')
  EPIC_TITLE=$(echo "$EPIC" | jq -r '.title')
  LABELS=$(echo "$EPIC" | jq -r '.labels[].name' 2>/dev/null || echo "")
  
  # Determine priority
  PRIORITY=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  else
    PRIORITY="Medium"  # Default
  fi
  
  # Determine component
  COMPONENT=""
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT="Workflow"
  elif echo "$LABELS" | grep -q "infrastructure"; then
    if echo "$EPIC_TITLE" | grep -q "External Integration"; then
      COMPONENT="External Integration"
    else
      COMPONENT="Shared Components"
    fi
  elif echo "$EPIC_TITLE" | grep -q "Testing"; then
    COMPONENT="Testing"
  fi
  
  # Add to mapping
  echo "| #$EPIC_NUM | $EPIC_TITLE | Epic | $PRIORITY | $COMPONENT |" >> "$MAPPING_FILE"
done

# Add user story mappings section
cat >> "$MAPPING_FILE" << EOL

## 3. User Story Mappings

The following user stories should be added to the project and configured with these fields:

| User Story # | Title | Type | Priority | Story Points | Epic | Component |
|--------------|-------|------|----------|--------------|------|-----------|
EOL

# Process each user story
echo "$USER_STORIES" | jq -c '.[]' | while read -r STORY; do
  STORY_NUM=$(echo "$STORY" | jq -r '.number')
  STORY_TITLE=$(echo "$STORY" | jq -r '.title')
  LABELS=$(echo "$STORY" | jq -r '.labels[].name' 2>/dev/null || echo "")
  BODY=$(echo "$STORY" | jq -r '.body')
  
  # Determine priority
  PRIORITY=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  else
    PRIORITY="Medium"  # Default
  fi
  
  # Extract story points from labels
  POINTS=""
  for LABEL in $(echo "$LABELS"); do
    if [[ "$LABEL" == points:* ]]; then
      POINTS="${LABEL#points:}"
    fi
  done
  
  # Find epic link
  EPIC_NUM=$(echo "$BODY" | grep -o -E "Epic: #[0-9]+" | grep -o -E "[0-9]+" | head -1 || echo "")
  EPIC_TITLE=""
  if [ ! -z "$EPIC_NUM" ]; then
    EPIC_TITLE=$(gh issue view $EPIC_NUM --json title --repo "$REPO" | jq -r '.title')
  fi
  
  # Determine component
  COMPONENT=""
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
  elif [ ! -z "$EPIC_NUM" ]; then
    # Derive component from epic if available
    EPIC_LABELS=$(gh issue view $EPIC_NUM --json labels --repo "$REPO" | jq -r '.labels[].name' 2>/dev/null || echo "")
    
    if echo "$EPIC_LABELS" | grep -q "core-agents"; then
      COMPONENT="Core Agents"
    elif echo "$EPIC_LABELS" | grep -q "mcp\|communication"; then
      COMPONENT="MCP"
    elif echo "$EPIC_LABELS" | grep -q "workflow"; then
      COMPONENT="Workflow"
    elif echo "$EPIC_LABELS" | grep -q "infrastructure"; then
      if echo "$EPIC_TITLE" | grep -q "External Integration"; then
        COMPONENT="External Integration"
      else
        COMPONENT="Shared Components"
      fi
    elif echo "$EPIC_TITLE" | grep -q "Testing"; then
      COMPONENT="Testing"
    fi
  fi
  
  # Add to mapping
  echo "| #$STORY_NUM | $STORY_TITLE | User Story | $PRIORITY | $POINTS | $EPIC_TITLE | $COMPONENT |" >> "$MAPPING_FILE"
done

# Add steps for notes section
cat >> "$MAPPING_FILE" << EOL

## 4. Comment Notes Migration

The following issues have comments that should be added to the Notes field in the project:

| Issue # | Title | Type | Comments |
|---------|-------|------|----------|
EOL

# Find issues with comments
for ISSUE_NUM in $(seq 1 70); do
  COMMENTS_FILE="/tmp/issue_comments/issue_${ISSUE_NUM}_comments.md"
  
  if [ -f "$COMMENTS_FILE" ]; then
    ISSUE_TITLE=$(gh issue view $ISSUE_NUM --json title --repo "$REPO" | jq -r '.title')
    ISSUE_TYPE=""
    
    LABELS=$(gh issue view $ISSUE_NUM --json labels --repo "$REPO" | jq -r '.labels[].name' 2>/dev/null || echo "")
    if echo "$LABELS" | grep -q "epic"; then
      ISSUE_TYPE="Epic"
    elif echo "$LABELS" | grep -q "user-story"; then
      ISSUE_TYPE="User Story"
    else
      ISSUE_TYPE="Task"
    fi
    
    COMMENT_COUNT=$(grep -c "commented on" "$COMMENTS_FILE")
    
    echo "| #$ISSUE_NUM | $ISSUE_TITLE | $ISSUE_TYPE | $COMMENT_COUNT |" >> "$MAPPING_FILE"
  fi
done

# Add instructions for creating views
cat >> "$MAPPING_FILE" << EOL

## 5. Creating Project Views

Create the following views for better organization:

1. **Epics Overview**
   - Filter: Type = Epic
   - Group by: Component
   - Show fields: Title, Priority, Status

2. **Stories by Epic**
   - Filter: Type = User Story
   - Group by: Epic
   - Show fields: Title, Priority, Story Points, Status

3. **Stories by Component**
   - Filter: Type = User Story
   - Group by: Component
   - Show fields: Title, Priority, Story Points, Epic, Status

4. **By Priority**
   - No filter
   - Group by: Priority
   - Show fields: Title, Type, Story Points, Epic, Component, Status

## 6. Final Steps

1. Review all items to ensure they have the correct Type, Priority, and other field values
2. Add the Notes from comment files to each issue with comments
3. Arrange items in each view according to priority

EOL

echo "🎉 Mapping guide created: $MAPPING_FILE"
echo ""
echo "This comprehensive guide provides all the information you need to set up the GitHub Project"
echo "including all epics, user stories, field mappings, and comments."
echo ""
echo "You can use this as a reference to manually configure the project on the GitHub web interface."
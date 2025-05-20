#!/bin/bash
# Map GitHub issue labels to GitHub Project fields (Priority, Story Points, etc.)
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Mapping issue labels to GitHub Project fields..."

# Get all issues with labels
ISSUES=$(gh issue list --limit 100 --json number,title,labels,body --repo "$REPO")

# Create output summary file
SUMMARY_FILE="/tmp/github_project_field_mapping.md"
echo "# GitHub Project Field Mapping" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "## Issue Types, Priorities, and Points" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "| Issue # | Title | Type | Priority | Story Points | Epic Link |" >> "$SUMMARY_FILE"
echo "|---------|-------|------|----------|--------------|-----------|" >> "$SUMMARY_FILE"

# Process each issue
echo "$ISSUES" | jq -c '.[]' | while read -r ISSUE; do
  ISSUE_NUM=$(echo "$ISSUE" | jq -r '.number')
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r '.title')
  LABELS=$(echo "$ISSUE" | jq -r '.labels[].name' 2>/dev/null || echo "")
  BODY=$(echo "$ISSUE" | jq -r '.body')
  
  echo "  🔍 Processing issue #$ISSUE_NUM: $ISSUE_TITLE"
  
  # Determine item type based on labels
  TYPE=""
  if echo "$LABELS" | grep -q "epic"; then
    TYPE="Epic"
  elif echo "$LABELS" | grep -q "user-story"; then
    TYPE="User Story"
  else
    TYPE="Task"
  fi
  
  # Determine priority based on labels
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
  
  # Find epic link for user stories
  EPIC_LINK=""
  if [ "$TYPE" == "User Story" ]; then
    EPIC_NUM=$(echo "$BODY" | grep -o -E "Epic: #[0-9]+" | cut -d '#' -f 2)
    if [ ! -z "$EPIC_NUM" ]; then
      EPIC_TITLE=$(gh issue view "$EPIC_NUM" --json title --repo "$REPO" | jq -r '.title')
      EPIC_LINK="#$EPIC_NUM: $EPIC_TITLE"
    fi
  fi
  
  # Add to summary
  echo "| #$ISSUE_NUM | $ISSUE_TITLE | $TYPE | $PRIORITY | $POINTS | $EPIC_LINK |" >> "$SUMMARY_FILE"
  
  echo "    📝 Issue #$ISSUE_NUM mapping:"
  echo "       Type: $TYPE"
  echo "       Priority: $PRIORITY"
  echo "       Story Points: $POINTS"
  echo "       Epic Link: $EPIC_LINK"
  echo ""
done

echo "🎉 Mapping complete!"
echo ""
echo "To apply these mappings to your GitHub Project:"
echo "1. Open your project at https://github.com/users/o2alexanderfedin/projects/2"
echo "2. Make sure you have these custom fields set up:"
echo "   - Type (Single select): Epic, User Story, Task"
echo "   - Priority (Single select): High, Medium, Low"
echo "   - Story Points (Number)"
echo "   - Epic (Single select): [Epic titles]"
echo ""
echo "Mapping summary saved to: $SUMMARY_FILE"
echo "Review this file for a complete table of all issue field mappings."
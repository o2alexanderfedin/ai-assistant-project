#!/bin/bash
# set-parent-manual.sh
# Manual script to export and re-import project items with parent-child relationships

set -e  # Exit on error

# Configuration
PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"
ORG_OR_USER="o2alexanderfedin"

echo "⚠️ Important Manual Instructions for Setting Parent Issue Fields ⚠️"
echo ""
echo "Due to limitations in the GitHub Projects GraphQL API for setting the Parent issue field,"
echo "you'll need to set these relationships manually in the GitHub UI:"
echo ""
echo "1. Go to: https://github.com/users/$ORG_OR_USER/projects/$PROJECT_NUM"
echo "2. For each user story, set its Parent issue field to the corresponding epic:"
echo ""

# Get all issues with Epic references
EPIC_RELATIONS=$(mktemp)

# Get all issues
ISSUES=$(gh issue list --repo "$REPO" --json number,title,body --limit 100)

# Process each issue to find Epic references
echo "$ISSUES" | jq -c '.[]' | while read -r issue; do
  ISSUE_NUM=$(echo "$issue" | jq -r '.number')
  ISSUE_TITLE=$(echo "$issue" | jq -r '.title')
  BODY=$(echo "$issue" | jq -r '.body')
  
  # Skip epics (issues #1-7)
  if [[ $ISSUE_NUM -ge 1 && $ISSUE_NUM -le 7 ]]; then
    continue
  fi
  
  # Look for "Epic: #X" pattern
  if [[ "$BODY" =~ [Ee]pic:\ *#([0-9]+) ]]; then
    EPIC_NUM="${BASH_REMATCH[1]}"
    
    # Only process epics 1-7
    if [[ $EPIC_NUM -ge 1 && $EPIC_NUM -le 7 ]]; then
      # Get epic title
      EPIC_TITLE=$(gh issue view $EPIC_NUM --json title --repo "$REPO" | jq -r '.title')
      
      echo "• Issue #$ISSUE_NUM: '$ISSUE_TITLE' → Epic #$EPIC_NUM: '$EPIC_TITLE'"
    fi
  fi
done

echo ""
echo "📋 Steps to Set Parent Issues:"
echo "1. Click on an issue in the project board"
echo "2. In the side panel, find the 'Parent issue' field"
echo "3. Type '#' and select the appropriate parent epic from the dropdown"
echo "4. Save the change and proceed to the next issue"
echo ""
echo "This will establish the parent-child hierarchy in the GitHub Project."
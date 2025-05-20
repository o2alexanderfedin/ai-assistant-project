#!/bin/bash
# Migrate all issues to GitHub Project #2
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Starting GitHub Project migration for Project #$PROJECT_NUM..."

# Add all epics first
echo "📚 Adding epics to project..."
EPICS=$(gh issue list --label epic --json number,url)
EPIC_COUNT=$(echo $EPICS | jq '. | length')

for i in $(seq 0 $(($EPIC_COUNT-1))); do
  EPIC_URL=$(echo $EPICS | jq -r ".[$i].url")
  EPIC_NUMBER=$(echo $EPICS | jq -r ".[$i].number")
  
  echo "  ➕ Adding epic #$EPIC_NUMBER: $EPIC_URL"
  gh projects item-add $PROJECT_NUM --user '@me' --url "$EPIC_URL"
  echo "  ✓ Epic #$EPIC_NUMBER added"
done

echo "✅ All epics added to project"

# Add all user stories
echo "📝 Adding user stories to project..."
USER_STORIES=$(gh issue list --label user-story --json number,url)
USER_STORY_COUNT=$(echo $USER_STORIES | jq '. | length')

for i in $(seq 0 $(($USER_STORY_COUNT-1))); do
  STORY_URL=$(echo $USER_STORIES | jq -r ".[$i].url")
  STORY_NUMBER=$(echo $USER_STORIES | jq -r ".[$i].number")
  
  echo "  ➕ Adding user story #$STORY_NUMBER: $STORY_URL"
  gh projects item-add $PROJECT_NUM --user '@me' --url "$STORY_URL"
  echo "  ✓ User story #$STORY_NUMBER added"
done

echo "✅ All user stories added to project"

echo "🎉 Migration complete! Project URL: https://github.com/users/o2alexanderfedin/projects/$PROJECT_NUM"
echo ""
echo "Next steps:"
echo "1. Open the project in your browser"
echo "2. Configure custom fields manually using the GitHub UI:"
echo "   - Add 'Type' field (Epic, User Story)"
echo "   - Add 'Priority' field (High, Medium, Low)"
echo "   - Add 'Story Points' field (Number)"
echo "   - Add 'Component' field (Core Agents, MCP, Workflow, etc.)"
echo "   - Add 'Epic Link' field for connecting user stories to epics"
echo "3. Setup views for Epics and User Stories"
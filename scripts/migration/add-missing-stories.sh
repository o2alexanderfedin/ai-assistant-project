#!/bin/bash

# This script adds the missing user stories (37-43) to the project

# CONFIG
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"

# Add missing user stories
echo "🔄 Adding missing user stories to project..."
for ISSUE_NUM in 37 38 39 40 41 42 43; do
  ISSUE_URL="https://github.com/$OWNER/$REPO/issues/$ISSUE_NUM"
  echo "Adding issue #$ISSUE_NUM to project..."
  
  gh project item-add $PROJECT_NUM --owner $OWNER --url "$ISSUE_URL"
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Successfully added issue #$ISSUE_NUM to project"
  else
    echo "  ❌ Failed to add issue #$ISSUE_NUM to project"
  fi
done

echo ""
echo "🏁 Finished adding missing user stories to project!"
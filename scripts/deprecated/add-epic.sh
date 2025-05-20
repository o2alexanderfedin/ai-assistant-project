#!/bin/bash
# Add a single epic to the GitHub Project

set -e

PROJECT_NUM=2
EPIC_NUM=1

echo "Adding Epic #$EPIC_NUM to Project #$PROJECT_NUM..."

# Add to project
ITEM_ID=$(gh projects item-add $PROJECT_NUM --user '@me' --repo o2alexanderfedin/ai-assistant-project \
  --number $EPIC_NUM --format json | jq -r '.id')

echo "Added epic with item ID: $ITEM_ID"
echo "Done!"
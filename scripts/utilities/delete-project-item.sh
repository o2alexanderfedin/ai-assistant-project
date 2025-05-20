#!/bin/bash

# Title: Delete GitHub Project Item
# Description: Deletes an item from a GitHub Project using GraphQL API
# Usage: ./delete-project-item.sh <project_id> <item_id>
# Author: AI Assistant Team
# Date: 2025-05-19
# Last Updated: 2025-05-19

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

# ----------- FUNCTIONS ----------- #

print_usage() {
  echo "Usage: $0 <project_id> <item_id>"
  echo "Example: $0 PVT_kwHOBJ7Qkc4A5SDb PVTI_lAHOBJ7Qkc4A5SDbzgagkDM"
  echo ""
  echo "Parameters:"
  echo "  project_id   - The ID of the GitHub Project"
  echo "  item_id      - The ID of the item to delete from the project"
}

delete_project_item() {
  local project_id="$1"
  local item_id="$2"
  
  echo "Deleting item $item_id from project $project_id..."
  
  # GraphQL mutation for deleting a project item
  MUTATION='
  mutation($projectId:ID!, $itemId:ID!) {
    deleteProjectV2Item(input: {
      projectId: $projectId
      itemId: $itemId
    }) {
      deletedItemId
    }
  }
  '
  
  # Execute the GraphQL mutation
  RESULT=$(gh api graphql \
    -f query="$MUTATION" \
    -f projectId="$project_id" \
    -f itemId="$item_id" 2>&1)
  
  # Check if the command was successful
  if [ $? -eq 0 ]; then
    # Extract the deleted item ID
    DELETED_ID=$(echo "$RESULT" | jq -r '.data.deleteProjectV2Item.deletedItemId')
    if [ "$DELETED_ID" == "null" ]; then
      echo "❌ Failed to delete item: $RESULT"
      return 1
    else
      echo "✅ Successfully deleted item: $DELETED_ID"
      return 0
    fi
  else
    echo "❌ Error executing GraphQL mutation: $RESULT"
    return 1
  fi
}

# ----------- MAIN ----------- #

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  print_usage
  exit 1
fi

PROJECT_ID="$1"
ITEM_ID="$2"

# Delete the project item
delete_project_item "$PROJECT_ID" "$ITEM_ID"
EXIT_CODE=$?

exit $EXIT_CODE
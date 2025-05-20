#!/bin/bash

# Title: Get GitHub Project Items
# Description: Lists items in a GitHub Project
# Usage: ./get-project-items.sh <owner> <project_number>
# Author: AI Assistant Team
# Date: 2025-05-19
# Last Updated: 2025-05-19

# ----------- CONFIG ----------- #

# ----------- FUNCTIONS ----------- #

print_usage() {
  echo "Usage: $0 <owner> <project_number>"
  echo "Example: $0 o2alexanderfedin 2"
  echo ""
  echo "Parameters:"
  echo "  owner         - The owner of the GitHub Project"
  echo "  project_number - The number of the GitHub Project"
}

get_project_items() {
  local owner="$1"
  local project_number="$2"
  
  echo "Fetching items from GitHub Project $project_number owned by $owner..."
  
  # Use the GitHub CLI to list project items
  RESULT=$(gh project item-list "$project_number" --owner "$owner" --format json)
  
  if [ $? -eq 0 ]; then
    echo "$RESULT" | jq -r '.items[] | [.id, (.content // {title: "N/A", number: "N/A"} | .number, .title)] | join(" | ")'
    return 0
  else
    echo "❌ Error fetching project items: $RESULT"
    return 1
  fi
}

# ----------- MAIN ----------- #

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  print_usage
  exit 1
fi

OWNER="$1"
PROJECT_NUMBER="$2"

# Get project items
get_project_items "$OWNER" "$PROJECT_NUMBER"
EXIT_CODE=$?

exit $EXIT_CODE
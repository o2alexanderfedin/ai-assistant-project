#!/bin/bash

# Title: Identify and Merge Project Duplicates
# Description: Identifies duplicate items in GitHub Projects and allows merging them
# Usage: ./identify-project-duplicates.sh <owner> <project_number>
# Author: AI Assistant Team
# Date: 2025-05-19
# Last Updated: 2025-05-19

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
PROJECT_NUMBER=2

# ----------- FUNCTIONS ----------- #

print_usage() {
  echo "Usage: $0 <owner> <project_number>"
  echo "Example: $0 o2alexanderfedin 2"
  echo ""
  echo "Parameters:"
  echo "  owner          - The owner of the GitHub Project"
  echo "  project_number - The number of the GitHub Project"
}

identify_duplicates() {
  local owner="$1"
  local project_number="$2"
  
  echo "Fetching items from GitHub Project $project_number owned by $owner..."
  
  # Use the GitHub CLI to list all project items
  ITEMS=$(gh project item-list "$project_number" --owner "$owner" --limit 100)
  
  if [ $? -ne 0 ]; then
    echo "❌ Error fetching project items"
    return 1
  fi
  
  # Create a temporary file to store the items
  TEMP_FILE=$(mktemp)
  echo "$ITEMS" > "$TEMP_FILE"
  
  # Extract titles and count occurrences
  echo "Analyzing project items for duplicates..."
  TITLES=$(cat "$TEMP_FILE" | awk '{print $2}' | sort)
  DUPLICATE_TITLES=$(echo "$TITLES" | uniq -d)
  
  if [ -z "$DUPLICATE_TITLES" ]; then
    echo "No duplicates found!"
    rm "$TEMP_FILE"
    return 0
  fi
  
  echo "Found the following duplicate titles:"
  echo "------------------------------------"
  
  # Process each duplicate title
  echo "$DUPLICATE_TITLES" | while read -r title; do
    echo "Title: $title"
    echo "Duplicates:"
    grep -i "$title" "$TEMP_FILE" | awk '{print "  #" $3 " (Item ID: " $NF ")"}'
    echo ""
  done
  
  # Clean up
  rm "$TEMP_FILE"
  
  echo "To merge duplicates, use the following process:"
  echo "1. Identify the primary issue (usually the lower-numbered one)"
  echo "2. Copy any unique content from the duplicate to the primary issue"
  echo "3. Remove the duplicate from the project using:"
  echo "   gh project item-delete $project_number --owner \"$owner\" --id <item-id>"
  
  return 0
}

# ----------- MAIN ----------- #

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  print_usage
  exit 1
fi

OWNER="$1"
PROJECT_NUMBER="$2"

# Identify duplicates
identify_duplicates "$OWNER" "$PROJECT_NUMBER"
EXIT_CODE=$?

exit $EXIT_CODE
#!/bin/bash
# Create custom fields for GitHub Project

set -e

PROJECT_NUM=2

echo "Creating custom fields for Project #$PROJECT_NUM..."

# Type field (Epic, User Story, Task)
echo "Creating Type field..."
gh projects field-create $PROJECT_NUM --user '@me' --name "Type" --data-type "SINGLE_SELECT" \
  --single-select-options "Epic,User Story,Task" --format json

echo "Done!"
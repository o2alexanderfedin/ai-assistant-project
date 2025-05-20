#!/bin/bash

# This script adds an issue to a GitHub project and sets its parent issue in one operation

# Get parameters
ISSUE_NUMBER=$1
PROJECT_NUMBER=$2
PARENT_ISSUE_NUMBER=$3
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"

if [ -z "$ISSUE_NUMBER" ] || [ -z "$PROJECT_NUMBER" ] || [ -z "$PARENT_ISSUE_NUMBER" ]; then
  echo "Usage: $0 <issue_number> <project_number> <parent_issue_number>"
  exit 1
fi

# Get the project ID from the output of gh project list
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUMBER" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "Project $PROJECT_NUMBER not found"
  exit 1
fi

# Get the issue node ID
ISSUE_NODE_ID=$(gh issue view $ISSUE_NUMBER --repo $OWNER/$REPO --json id | jq -r '.id')
if [ -z "$ISSUE_NODE_ID" ]; then
  echo "Issue $ISSUE_NUMBER not found"
  exit 1
fi

# Get the parent issue node ID
PARENT_NODE_ID=$(gh issue view $PARENT_ISSUE_NUMBER --repo $OWNER/$REPO --json id | jq -r '.id')
if [ -z "$PARENT_NODE_ID" ]; then
  echo "Parent issue $PARENT_ISSUE_NUMBER not found"
  exit 1
fi

# Get the parent field ID
PARENT_FIELD_ID=$(gh project field-list $PROJECT_NUMBER --owner $OWNER | grep "Parent issue" | awk '{print $NF}')
if [ -z "$PARENT_FIELD_ID" ]; then
  echo "Parent issue field not found in project $PROJECT_NUMBER"
  exit 1
fi

echo "Adding issue #$ISSUE_NUMBER to project #$PROJECT_NUMBER..."

# First, add the issue to the project
ITEM_ID=$(gh api graphql -f query='
  mutation($projectId:ID!, $contentId:ID!) {
    addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
      item {
        id
      }
    }
  }' -f projectId=$PROJECT_ID -f contentId=$ISSUE_NODE_ID | jq -r '.data.addProjectV2ItemById.item.id')

if [ -z "$ITEM_ID" ]; then
  echo "Failed to add issue to project"
  exit 1
fi

echo "Issue added to project. Item ID: $ITEM_ID"
echo "Setting parent issue to #$PARENT_ISSUE_NUMBER..."

# Now set the parent issue field
gh api graphql -f query='
  mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $parentId:String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId, 
      itemId: $itemId, 
      fieldId: $fieldId, 
      value: { 
        parentId: $parentId
      }
    }) {
      projectV2Item {
        id
      }
    }
  }' -f projectId=$PROJECT_ID -f itemId=$ITEM_ID -f fieldId=$PARENT_FIELD_ID -f parentId=$PARENT_NODE_ID

echo "Done!"
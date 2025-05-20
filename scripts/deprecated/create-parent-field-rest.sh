#!/bin/bash

# Script to create a custom parent field and set values using REST API

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
PROJECT_NUM="1"  # Adjust to your project number

# ----------- CREATE CUSTOM PARENT FIELD ----------- #
echo "🔑 Validating GitHub authentication..."
gh auth status > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub authentication failed. Please run 'gh auth login' first."
  exit 1
fi

echo "🏷️ Creating custom parent field in Project #$PROJECT_NUM..."

# Get project information
echo "1️⃣ Getting project information..."
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Failed to get project ID"
  exit 1
fi

echo "Found project with ID: $PROJECT_ID"

# Get epic issues
echo "2️⃣ Getting epic issues to use as options..."
EPICS=$(gh issue list --repo "$OWNER/ai-assistant-project" --label epic --json number,title --limit 20)
NUM_EPICS=$(echo "$EPICS" | jq length)

echo "Found $NUM_EPICS epics to use as options"

# Create parent field
echo "3️⃣ Creating custom parent field..."
FIELD_CREATION=$(gh api --method POST -H "Accept: application/vnd.github+json" \
  /projects/v2/$PROJECT_ID/fields \
  -f name="Custom Parent Link" \
  -f data_type="single_select" \
  -f single_select_options="$(echo "$EPICS" | jq -c '[.[] | {name: .title}]')")

FIELD_ID=$(echo "$FIELD_CREATION" | jq -r '.id')

if [ -z "$FIELD_ID" ] || [ "$FIELD_ID" == "null" ]; then
  echo "❌ Failed to create field"
  echo "Error: $FIELD_CREATION"
  exit 1
fi

echo "✅ Successfully created custom parent field (ID: $FIELD_ID)"
echo ""
echo "🔄 Usage:"
echo "1. To set a custom parent relationship:"
echo "   gh api --method PATCH /projects/v2/items/ITEM_ID \\"
echo "       -H 'Accept: application/vnd.github+json' \\"
echo "       -f 'field_id=$FIELD_ID' \\"
echo "       -f 'value={\"single_select_option_id\": \"OPTION_ID\"}'"
echo ""
echo "2. To view available options:"
echo "   gh api /projects/v2/fields/$FIELD_ID/options | jq '.[] | {id, name}'"
echo ""
echo "This field can be used as a workaround for the built-in parent field."
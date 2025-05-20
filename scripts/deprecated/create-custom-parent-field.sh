#!/bin/bash

# Script to create a custom parent field in GitHub Project and set values programmatically

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
PROJECT_NUM="1"  # Adjust to your project number

# ----------- VALIDATE AUTHENTICATION ----------- #
echo "🔑 Validating GitHub authentication..."
gh auth status > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub authentication failed. Please run 'gh auth login' first."
  echo "🔑 Also ensure token has 'project' scope: gh auth refresh -h github.com -s project"
  exit 1
fi

# ----------- CREATE CUSTOM PARENT FIELD ----------- #
echo "🏷️ Creating custom parent field in Project #$PROJECT_NUM..."

# Get project ID
PROJECT_ID=$(gh project list --owner $OWNER | grep "^$PROJECT_NUM" | awk '{print $NF}')
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project #$PROJECT_NUM not found"
  exit 1
fi

echo "Found project ID: $PROJECT_ID"

# Get all issues to use as options
echo "📋 Fetching all issues to use as parent options..."
ISSUES_JSON=$(gh issue list --repo "$OWNER/ai-assistant-project" --json number,title --limit 100)
EPIC_OPTIONS=$(echo "$ISSUES_JSON" | jq -r '.[] | select(.title | startswith("🔄") or startswith("🧠") or startswith("⚙️") or startswith("🗄️") or startswith("🔗") or startswith("🔍")) | .title' | tr '\n' ',' | sed 's/,$//')

if [ -z "$EPIC_OPTIONS" ]; then
  echo "❌ No epic issues found"
  echo "Using all issues as options..."
  EPIC_OPTIONS=$(echo "$ISSUES_JSON" | jq -r '.[] | .title' | tr '\n' ',' | sed 's/,$//')
fi

echo "Creating field with options: $EPIC_OPTIONS"

# Create options array in the format needed for the API
EPIC_ARRAY=$(echo "$ISSUES_JSON" | jq -r '.[] | select(.title | startswith("🔄") or startswith("🧠") or startswith("⚙️") or startswith("🗄️") or startswith("🔗") or startswith("🔍")) | "{\"name\": \"\(.title)\"},"' | tr -d '\n' | sed 's/,$//')
OPTIONS_JSON="[$EPIC_ARRAY]"

echo "Options JSON: $OPTIONS_JSON"

# Create custom parent field
FIELD_RESULT=$(gh api graphql -f query='
  mutation($projectId:ID!, $name:String!, $options:[ProjectV2SingleSelectFieldOptionInput!]!) {
    createProjectV2Field(
      input: {
        projectId: $projectId
        dataType: SINGLE_SELECT
        name: $name
        singleSelectOptions: $options
      }
    ) {
      projectV2Field {
        ... on ProjectV2SingleSelectField {
          id
          name
        }
      }
    }
  }
' -f projectId="$PROJECT_ID" -f name="Custom Parent" -f options="$OPTIONS_JSON")

FIELD_ID=$(echo "$FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.id')

if [[ -z "$FIELD_ID" || "$FIELD_ID" == "null" ]]; then
  echo "❌ Failed to create custom parent field"
  echo "Error: $FIELD_RESULT"
  exit 1
fi

echo "✅ Successfully created custom parent field: $FIELD_ID"
echo ""
echo "🔄 Usage instructions:"
echo "1. To set a custom parent, use the script: ./scripts/set-custom-parent.sh"
echo "2. Format: ./scripts/set-custom-parent.sh <child_issue_number> <parent_title>"
echo "3. Example: ./scripts/set-custom-parent.sh 42 \"🔄 Core Agent System Implementation\""
echo ""
echo "This custom field can be used as a workaround for the built-in parent field."
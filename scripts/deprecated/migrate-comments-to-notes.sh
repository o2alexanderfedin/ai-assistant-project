#!/bin/bash
# Migrate issue comments to GitHub Project notes with proper formatting
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"
ISSUES_DIR="/tmp/issue_comments"

mkdir -p "$ISSUES_DIR"

echo "🚀 Starting comment migration for Project #$PROJECT_NUM..."

# Get a list of all issue numbers
ISSUES=$(gh issue list --json number --repo "$REPO" | jq -r '.[] | .number')

for ISSUE_NUM in $ISSUES; do
  echo "  🔍 Processing issue #$ISSUE_NUM"
  
  # Get comments for this issue
  gh issue view $ISSUE_NUM --json comments --repo "$REPO" > "$ISSUES_DIR/issue_${ISSUE_NUM}_data.json"
  COMMENT_COUNT=$(jq '.comments | length' "$ISSUES_DIR/issue_${ISSUE_NUM}_data.json")
  
  if [ "$COMMENT_COUNT" -eq 0 ]; then
    echo "    ℹ️ No comments found for issue #$ISSUE_NUM"
    continue
  fi
  
  echo "    📝 Found $COMMENT_COUNT comments"
  
  # Create a formatted note with comments
  NOTE_FILE="$ISSUES_DIR/issue_${ISSUE_NUM}_comments.md"
  
  {
    echo "### Comments from Issue #$ISSUE_NUM"
    echo ""
    
    # Process each comment
    for j in $(seq 0 $(($COMMENT_COUNT-1))); do
      AUTHOR=$(jq -r ".comments[$j].author.login" "$ISSUES_DIR/issue_${ISSUE_NUM}_data.json")
      CREATED_AT=$(jq -r ".comments[$j].createdAt" "$ISSUES_DIR/issue_${ISSUE_NUM}_data.json" | sed 's/T/ /g' | sed 's/Z//g')
      
      echo "**@$AUTHOR** commented on $CREATED_AT:"
      echo ""
      
      # Extract and write comment body with proper formatting
      jq -r ".comments[$j].body" "$ISSUES_DIR/issue_${ISSUE_NUM}_data.json"
      
      echo ""
      echo "---"
      echo ""
    done
  } > "$NOTE_FILE"
  
  # Find the node ID for this item in the project using GraphQL
  # Using direct gh api call to get items in project and find the one matching our issue
  
  # Add this note to the project item
  echo "    ✏️ Adding note to project item"
  
  # Since we can't directly get the project item ID, we'll use the web UI approach for now
  echo "    ⚠️ Please add this note manually to issue #$ISSUE_NUM in the project"
  echo "    📄 The formatted note is available at $NOTE_FILE"
  
  # Display the note path for manual addition
  echo "    🔗 Full path: $(realpath $NOTE_FILE)"
done

echo "🎉 Comment extraction complete!"
echo ""
echo "Since direct API access to project item notes is limited, please:"
echo "1. Open your project at https://github.com/users/o2alexanderfedin/projects/$PROJECT_NUM"
echo "2. For each issue with comments, add the exported note from:"
echo "   $ISSUES_DIR/issue_XX_comments.md (where XX is the issue number)"
echo ""
echo "Notes will remain in $ISSUES_DIR until you delete them"
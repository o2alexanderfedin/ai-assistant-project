#!/bin/bash
# Process comments for specific issues
# Run after refreshing auth token with "gh auth refresh -h github.com -s project"

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"
ISSUES_DIR="/tmp/issue_comments"

mkdir -p "$ISSUES_DIR"

echo "🚀 Processing comments for specific issues..."

# Specific issues that likely have comments
ISSUES="1 2 3 4 5 6 7 8"

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
  
  # Display the note path for manual addition
  echo "    ✅ Comments saved to: $(realpath $NOTE_FILE)"
  
  # Show a preview of the first 5 lines
  echo "    📄 Preview:"
  head -n 5 "$NOTE_FILE"
  echo "    ..."
done

echo "🎉 Comment extraction complete!"
echo ""
echo "To add these comments to your GitHub Project:"
echo "1. Open your project at https://github.com/users/o2alexanderfedin/projects/$PROJECT_NUM"
echo "2. Click on an issue in the project view"
echo "3. In the side panel, click on the Notes field"
echo "4. Copy and paste the content from the corresponding file:"
echo "   - Files are located at: $ISSUES_DIR/issue_X_comments.md"
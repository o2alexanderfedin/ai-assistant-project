#!/bin/bash
# Simple GitHub Project creation script
# Running with refresh token permissions

set -e  # Exit on error

echo "🚀 Creating GitHub Project for AI Assistant..."

# Create the project
echo "📋 Creating new project..."
PROJECT_JSON=$(gh projects create --user '@me' --title "AI Assistant Development" --format json)
echo "Project JSON: $PROJECT_JSON"
PROJECT_ID=$(echo $PROJECT_JSON | jq -r '.id')
PROJECT_NUM=$(echo $PROJECT_JSON | jq -r '.number')
echo "✅ Created project with ID: $PROJECT_ID, Number: $PROJECT_NUM"

echo "🎉 Project URL: https://github.com/users/o2alexanderfedin/projects/$PROJECT_NUM"
#!/bin/bash
# Test GitHub Project access

echo "Testing GitHub Project API access..."
echo ""
echo "1. Checking if gh projects command is available..."
gh projects --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub projects command not available"
  echo "Please run: gh auth refresh -h github.com -s project"
  exit 1
else
  echo "✅ GitHub projects command is available"
fi

echo ""
echo "2. Testing project list permission..."
gh projects list --format json >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Token lacks required scope for projects"
  echo "Please run: gh auth refresh -h github.com -s project"
  exit 1
else
  echo "✅ Token has proper scope for projects"
fi

echo ""
echo "✅ All checks passed. You can now run the migration script."
echo "Run: ./github-project-migration.sh"
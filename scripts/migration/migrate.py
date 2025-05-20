#!/usr/bin/env python3

"""
GitHub Issue Migration Script

This script ensures all GitHub issues are in the project with correct types and parent relationships.
Simple and straightforward with no batching - just processes all issues directly.
"""

import subprocess
import json
import time

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"

# Parent-child relationships
PARENT_RELATIONSHIPS = {
    "1": ["66", "65", "64", "63", "62", "61", "60", "59"],
    "2": ["17", "18", "19", "20", "21", "22", "23", "24"],
    "3": ["54", "55", "56", "57", "58"],
    "4": ["25", "26", "27", "28", "29", "30", "31", "32"],
    "5": ["33", "34", "35", "36", "37", "38", "39", "40"],
    "6": ["41", "42", "43", "44", "45", "46", "47"],
    "7": ["48", "49", "50", "51", "52", "53"]
}

def run_command(cmd):
    """Run a command and return the output"""
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def main():
    """Main function to handle the migration"""
    print("Starting GitHub issue migration...")
    
    # Get all issues from the repository
    print("🔍 Getting all issues from the repository...")
    success, output = run_command(["gh", "issue", "list", 
                                  "--repo", f"{OWNER}/{REPO}", 
                                  "--limit", "100", 
                                  "--json", "number,title,labels"])
    
    if not success:
        print(f"Failed to get issues: {output}")
        return
    
    all_issues = json.loads(output)
    print(f"Found {len(all_issues)} issues in the repository.")
    
    # Get all items from the project
    print("🔍 Getting all items from the project...")
    success, output = run_command(["gh", "project", "item-list", PROJECT_NUM, "--owner", OWNER])
    
    if not success:
        print(f"Failed to get project items: {output}")
        return
    
    # Parse project items
    project_items = []
    for line in output.strip().split("\n"):
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0] == "Issue":
            project_items.append({
                "title": parts[1],
                "number": parts[2]
            })
    
    print(f"Found {len(project_items)} items in the project.")
    
    # Process each issue
    for issue in all_issues:
        issue_number = str(issue.get("number"))
        issue_title = issue.get("title")
        
        print(f"Processing issue #{issue_number}: '{issue_title}'")
        
        # Check if issue is already in project
        in_project = any(item.get("number") == issue_number for item in project_items)
        
        # Add issue to project if not already there
        if in_project:
            print(f"  ✓ Issue already in project")
        else:
            print(f"  ➕ Adding issue to project...")
            success, output = run_command([
                "gh", "project", "item-add", PROJECT_NUM,
                "--owner", OWNER,
                "--url", f"https://github.com/{OWNER}/{REPO}/issues/{issue_number}"
            ])
            
            if success:
                print(f"  ✅ Successfully added to project")
            else:
                print(f"  ❌ Failed to add to project: {output}")
                continue
        
        # Set parent-child relationship if applicable
        for parent_num, children in PARENT_RELATIONSHIPS.items():
            if issue_number in children:
                print(f"  Setting parent relationship: #{parent_num} for child #{issue_number}")
                
                # Get parent and child issue IDs
                success, parent_output = run_command([
                    "gh", "issue", "view", parent_num,
                    "--repo", f"{OWNER}/{REPO}",
                    "--json", "id"
                ])
                
                if not success:
                    print(f"  ❌ Failed to get parent issue: {parent_output}")
                    continue
                
                parent_id = json.loads(parent_output).get("id")
                
                success, child_output = run_command([
                    "gh", "issue", "view", issue_number,
                    "--repo", f"{OWNER}/{REPO}",
                    "--json", "id"
                ])
                
                if not success:
                    print(f"  ❌ Failed to get child issue: {child_output}")
                    continue
                
                child_id = json.loads(child_output).get("id")
                
                # Set up GraphQL mutation to add sub-issue
                mutation = """
                mutation($parentId:ID!, $childId:ID!) {
                  addSubIssue(input: {
                    issueId: $parentId,
                    subIssueId: $childId,
                    replaceParent: true
                  }) {
                    issue { number }
                    subIssue { number }
                  }
                }
                """
                
                success, output = run_command([
                    "gh", "api", "graphql",
                    "-f", f"query={mutation}",
                    "-f", f"parentId={parent_id}",
                    "-f", f"childId={child_id}"
                ])
                
                if success:
                    if "duplicate sub-issues" in output:
                        print(f"  ℹ️ Parent relationship already exists")
                    elif "errors" not in output.lower():
                        print(f"  ✅ Successfully set parent relationship")
                    else:
                        print(f"  ❌ Failed to set parent relationship: {output}")
                else:
                    print(f"  ❌ Failed to set parent relationship: {output}")
                
                break  # Only one parent per issue
        
        print("")  # Add blank line for readability
    
    print("🏁 Migration completed!")
    print("All issues should now be in the project with correct parent relationships.")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3

"""
Batch GitHub Issue Migration Script

This script migrates issues from a GitHub repository to a GitHub Project in batches,
setting proper types and parent-child relationships.
"""

import subprocess
import json
import time
import sys

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

def run_gh_command(args):
    """Run a GitHub CLI command and return the output"""
    try:
        cmd = ["gh"] + args
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def get_issues_batch(start_num, end_num):
    """Get a batch of issues by number range"""
    print(f"🔍 Getting issues from #{start_num} to #{end_num}...")
    issues = []
    
    for num in range(start_num, end_num + 1):
        success, output = run_gh_command([
            "issue", "view", str(num),
            "--repo", f"{OWNER}/{REPO}",
            "--json", "number,title,labels"
        ])
        
        if success:
            issues.append(json.loads(output))
        else:
            print(f"  ⚠️ Issue #{num} not found or error occurred")
    
    return issues

def get_project_items():
    """Get all items from the project"""
    print("🔍 Getting all items from the project...")
    success, output = run_gh_command(["project", "item-list", PROJECT_NUM, "--owner", OWNER])
    
    if success:
        # Parse the output to extract items
        items = []
        for line in output.strip().split('\n'):
            parts = line.split('\t')
            if len(parts) >= 4 and parts[0] == "Issue":
                items.append({
                    "title": parts[1],
                    "number": parts[2]
                })
        return items
    return []

def add_issue_to_project(issue_number):
    """Add an issue to the project"""
    print(f"  ➕ Adding issue #{issue_number} to project...")
    success, output = run_gh_command([
        "project", "item-add", PROJECT_NUM,
        "--owner", OWNER,
        "--url", f"https://github.com/{OWNER}/{REPO}/issues/{issue_number}"
    ])
    
    if success:
        print(f"  ✅ Successfully added issue #{issue_number} to project")
        time.sleep(1)  # Brief pause to allow GitHub to process
        return True
    else:
        print(f"  ❌ Failed to add issue #{issue_number} to project")
        print(output)
        return False

def set_parent_relationship(parent_number, child_number):
    """Set parent-child relationship between issues"""
    print(f"  Setting parent: #{parent_number} for child: #{child_number}...")
    
    success, output = run_gh_command([
        "issue", "view", parent_number,
        "--repo", f"{OWNER}/{REPO}",
        "--json", "id,title"
    ])
    
    if not success:
        print(f"  ❌ Failed to get parent issue #{parent_number}")
        return False
    
    parent_data = json.loads(output)
    parent_id = parent_data.get("id")
    
    success, output = run_gh_command([
        "issue", "view", child_number,
        "--repo", f"{OWNER}/{REPO}",
        "--json", "id,title"
    ])
    
    if not success:
        print(f"  ❌ Failed to get child issue #{child_number}")
        return False
    
    child_data = json.loads(output)
    child_id = child_data.get("id")
    
    # GraphQL mutation to add sub-issue
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
    
    success, output = run_gh_command([
        "api", "graphql",
        "-f", f"query={mutation}",
        "-f", f"parentId={parent_id}",
        "-f", f"childId={child_id}"
    ])
    
    if success:
        if "duplicate sub-issues" in output:
            print(f"  ℹ️ Relationship already exists")
        elif "errors" not in output.lower():
            print(f"  ✅ Successfully set parent relationship")
        else:
            print(f"  ❌ Failed to set parent relationship")
            print(output)
            return False
    else:
        print(f"  ❌ Failed to set parent relationship")
        print(output)
        return False
    
    return True

def process_issue(issue, project_items):
    """Process a single issue, ensuring it's in the project with correct fields"""
    issue_number = str(issue.get("number"))
    issue_title = issue.get("title")
    
    print(f"Processing issue #{issue_number}: '{issue_title}'")
    
    # Check if issue is already in project
    in_project = any(item.get("number") == issue_number or item.get("title") == issue_title 
                    for item in project_items)
    
    # Add to project if not already there
    if in_project:
        print(f"  ✓ Issue already in project")
    else:
        if not add_issue_to_project(issue_number):
            return
    
    # Set parent relationship if applicable
    for parent_num, children in PARENT_RELATIONSHIPS.items():
        if issue_number in children:
            set_parent_relationship(parent_num, issue_number)
            break
    
    print("")  # Add a blank line for readability

def process_batch(start_num, end_num):
    """Process a batch of issues"""
    print(f"--- Processing issues #{start_num} to #{end_num} ---")
    
    # Get issues in this batch
    issues = get_issues_batch(start_num, end_num)
    if not issues:
        print(f"No issues found in range #{start_num} to #{end_num}.")
        return
    
    # Get project items once for the batch
    project_items = get_project_items()
    
    # Process each issue
    for issue in issues:
        process_issue(issue, project_items)
    
    print(f"--- Completed batch #{start_num} to #{end_num} ---\n")

def main():
    """Main function to migrate issues in batches"""
    # Check command line arguments
    if len(sys.argv) == 3:
        # Process a specific range
        try:
            start_num = int(sys.argv[1])
            end_num = int(sys.argv[2])
            process_batch(start_num, end_num)
        except ValueError:
            print("Error: Start and end numbers must be integers")
    else:
        # Process all issues in batches of 10
        batch_size = 10
        max_issue = 70  # Adjust based on the highest issue number
        
        for start in range(1, max_issue + 1, batch_size):
            end = min(start + batch_size - 1, max_issue)
            process_batch(start, end)
            time.sleep(2)  # Brief pause between batches
    
    print("🏁 Migration completed!")

if __name__ == "__main__":
    main()
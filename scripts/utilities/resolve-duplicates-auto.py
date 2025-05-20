#!/usr/bin/env python3

"""
This script automatically resolves duplicate issues in GitHub Projects by:
1. Adding lower-numbered issues to the project
2. Removing higher-numbered duplicates from the project
"""

import subprocess
import json
import sys
import time

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUMBER = 2

# Duplicates mapping - primary issue to duplicate issue
DUPLICATES = {
    "9": "59",   # GitHub Task Monitoring
    "10": "60",  # Agent Lifecycle Management
    "11": "61",  # Orchestrator MCP Communication
    "12": "62",  # Task Analysis and Agent Matching
    "13": "63",  # Task Classification and Prioritization
    "14": "64",  # Agent Instance Creation
    "15": "65",  # Agent Template Management
    "16": "66",  # Secure Agent Creation
}

def run_command(cmd):
    """Run a shell command and return the output"""
    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def get_issue_details(issue_number):
    """Get the details of a GitHub issue"""
    success, output = run_command([
        "gh", "issue", "view", 
        issue_number, 
        "--repo", f"{OWNER}/{REPO}", 
        "--json", "id,number,title,body,labels"
    ])
    
    if not success:
        print(f"❌ Error fetching issue {issue_number}: {output}")
        return {}
    
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        print(f"❌ Error parsing JSON from GitHub CLI output")
        return {}

def add_issue_to_project(issue_number):
    """Add an issue to the GitHub Project"""
    print(f"Adding issue #{issue_number} to project...")
    
    # Get the issue URL
    issue_url = f"https://github.com/{OWNER}/{REPO}/issues/{issue_number}"
    
    success, output = run_command([
        "gh", "project", "item-add", 
        str(PROJECT_NUMBER), 
        "--owner", OWNER, 
        "--url", issue_url
    ])
    
    if success:
        print(f"✅ Successfully added issue #{issue_number} to project")
        return True
    else:
        print(f"❌ Error adding issue #{issue_number} to project: {output}")
        return False

def get_project_item_for_issue(issue_number):
    """Get the project item ID for an issue"""
    success, output = run_command([
        "gh", "project", "item-list", 
        str(PROJECT_NUMBER), 
        "--owner", OWNER
    ])
    
    if not success:
        print(f"❌ Error listing project items: {output}")
        return None
    
    # Search for the issue in the output
    lines = output.strip().split('\n')
    for line in lines:
        columns = line.split('\t')
        if len(columns) >= 3 and columns[2] == issue_number:
            return columns[-1]  # Last column is the item ID
    
    return None

def delete_project_item(item_id):
    """Delete an item from the GitHub Project"""
    print(f"Deleting project item {item_id}...")
    
    success, output = run_command([
        "gh", "project", "item-delete", 
        str(PROJECT_NUMBER), 
        "--owner", OWNER, 
        "--id", item_id
    ])
    
    if success:
        print(f"✅ Successfully deleted project item {item_id}")
        return True
    else:
        print(f"❌ Error deleting project item {item_id}: {output}")
        return False

def resolve_duplicates():
    """Resolve duplicate issues by adding primaries and removing duplicates"""
    for primary, duplicate in DUPLICATES.items():
        print(f"\n=== Processing duplicate pair: #{primary} and #{duplicate} ===")
        
        # Get details of both issues
        primary_details = get_issue_details(primary)
        duplicate_details = get_issue_details(duplicate)
        
        if not primary_details or not duplicate_details:
            print(f"❌ Could not get issue details, skipping this pair")
            continue
        
        print(f"Primary issue: #{primary} - {primary_details.get('title', 'N/A')}")
        print(f"Duplicate issue: #{duplicate} - {duplicate_details.get('title', 'N/A')}")
        
        # Before removing the duplicate, get its project item ID
        duplicate_item_id = get_project_item_for_issue(duplicate)
        if not duplicate_item_id:
            print(f"⚠️ Could not find project item ID for issue #{duplicate}, might not be in the project")
        
        # Add the primary issue to the project
        success = add_issue_to_project(primary)
        if not success:
            print(f"❌ Failed to add primary issue #{primary} to project, skipping")
            continue
        
        # Wait a moment for the project to update
        time.sleep(2)
        
        # Remove the duplicate from the project if we found its item ID
        if duplicate_item_id:
            print(f"Removing duplicate issue #{duplicate} from project...")
            delete_project_item(duplicate_item_id)
        
        # Add a delay to avoid rate limiting
        time.sleep(1)

def main():
    print("GitHub Project Duplicate Resolution")
    print("==================================")
    
    print("This script will automatically add primary issues to the project and remove duplicates.")
    
    # Resolve duplicates
    resolve_duplicates()
    
    print("\n✅ Duplicate resolution process completed")
    print("Check the GitHub Project to verify the changes.")

if __name__ == "__main__":
    main()
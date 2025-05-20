#!/usr/bin/env python3

"""
This script identifies exact duplicate items in GitHub Projects by title,
allows for the comparison of their content, and merges them by removing
the higher-numbered duplicate after transferring any unique content.
"""

import subprocess
import json
import sys
import time
from collections import defaultdict

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUMBER = 2

# Known duplicates mapping (title to issue numbers)
KNOWN_DUPLICATES = {
    "GitHub Task Monitoring": ["9", "59"],
    "Agent Lifecycle Management": ["10", "60"],
    "Orchestrator MCP Communication": ["11", "61"],
    "Task Analysis and Agent Matching": ["12", "62"],
    "Task Classification and Prioritization": ["13", "63"],
    "Agent Instance Creation": ["14", "64"],
    "Agent Template Management": ["15", "65"],
    "Secure Agent Creation": ["16", "66"]
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

def get_project_items():
    """Get all items from the GitHub Project using GitHub CLI"""
    print(f"Fetching items from GitHub Project {PROJECT_NUMBER} owned by {OWNER}...")
    
    # Use the GitHub CLI to get project items
    success, output = run_command([
        "gh", "project", "item-list", 
        str(PROJECT_NUMBER), 
        "--owner", OWNER, 
        "--format", "json"
    ])
    
    if not success:
        print(f"❌ Error fetching project items: {output}")
        return []
    
    try:
        # Parse JSON output
        data = json.loads(output)
        return data.get("items", [])
    except json.JSONDecodeError:
        print(f"❌ Error parsing JSON from GitHub CLI output")
        return []

def get_issue_details(issue_number):
    """Get the details of a GitHub issue"""
    success, output = run_command([
        "gh", "issue", "view", 
        issue_number, 
        "--repo", f"{OWNER}/{REPO}", 
        "--json", "title,body,labels"
    ])
    
    if not success:
        print(f"❌ Error fetching issue {issue_number}: {output}")
        return {}
    
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        print(f"❌ Error parsing JSON from GitHub CLI output")
        return {}

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

def identify_duplicates(items):
    """Identify duplicate items by title"""
    print("Analyzing project items for exact duplicate titles...")
    
    # Group items by title
    items_by_title = defaultdict(list)
    
    for item in items:
        # Check if the item has content (might be a draft item)
        if "content" in item and item["content"] is not None:
            title = item["content"].get("title", "")
            if title:
                issue_number = str(item["content"].get("number", ""))
                items_by_title[title].append({
                    "id": item["id"],
                    "number": issue_number
                })
    
    # Find titles with multiple items
    duplicates = {title: items for title, items in items_by_title.items() if len(items) > 1}
    
    return duplicates

def compare_duplicates(duplicates):
    """Compare duplicate items and prepare for merging"""
    print("\n=== Duplicate Items Analysis ===\n")
    
    if not duplicates:
        print("No duplicates found!")
        return
    
    # Sort duplicate titles for consistent output
    for title, items in sorted(duplicates.items()):
        print(f"Title: \"{title}\"")
        print(f"Number of duplicates: {len(items)}")
        
        # Sort items by issue number to keep lower numbers first
        sorted_items = sorted(items, key=lambda x: int(x["number"]) if x["number"].isdigit() else float('inf'))
        
        for item in sorted_items:
            print(f"  Issue #{item['number']}")
            print(f"    Project Item ID: {item['id']}")
        
        print("-" * 40)
    
    return duplicates

def merge_duplicates(duplicates):
    """Merge duplicates by removing higher-numbered items from the project"""
    if not duplicates:
        return
    
    print("\n=== Merging Duplicates ===\n")
    
    for title, items in duplicates.items():
        print(f"Processing duplicates for: \"{title}\"")
        
        # Sort items by issue number (ascending)
        sorted_items = sorted(items, key=lambda x: int(x["number"]) if x["number"].isdigit() else float('inf'))
        
        if len(sorted_items) < 2:
            print("  Not enough items to merge, skipping")
            continue
        
        # Keep the lowest-numbered issue
        primary = sorted_items[0]
        duplicates_to_remove = sorted_items[1:]
        
        print(f"  Primary issue to keep: #{primary['number']} (ID: {primary['id']})")
        print(f"  Duplicate issues to remove: {', '.join([f'#{item['number']}' for item in duplicates_to_remove])}")
        
        # Get content of primary issue for reference
        primary_details = get_issue_details(primary["number"])
        if not primary_details:
            print(f"  ❌ Could not get details for primary issue #{primary['number']}, skipping")
            continue
        
        print(f"  Primary issue content:")
        print(f"    Title: {primary_details.get('title', 'N/A')}")
        print(f"    Labels: {', '.join([label.get('name', '') for label in primary_details.get('labels', [])])}")
        print(f"    Body length: {len(primary_details.get('body', '')) if primary_details.get('body') else 0} characters")
        
        # Process duplicates
        for duplicate in duplicates_to_remove:
            print(f"\n  Processing duplicate #{duplicate['number']} (ID: {duplicate['id']})")
            
            # Get content of duplicate issue for comparison
            duplicate_details = get_issue_details(duplicate["number"])
            if not duplicate_details:
                print(f"    ❌ Could not get details for duplicate issue #{duplicate['number']}, skipping")
                continue
            
            print(f"    Duplicate issue content:")
            print(f"      Title: {duplicate_details.get('title', 'N/A')}")
            print(f"      Labels: {', '.join([label.get('name', '') for label in duplicate_details.get('labels', [])])}")
            print(f"      Body length: {len(duplicate_details.get('body', '')) if duplicate_details.get('body') else 0} characters")
            
            # Here you would normally update the primary issue with any unique content from the duplicate
            # For this example, we'll just note what would be merged
            print(f"    ℹ️ Semantic analysis required: Compare issue #{primary['number']} with #{duplicate['number']}")
            print(f"    ℹ️ Manual step: Update issue #{primary['number']} with any unique content from #{duplicate['number']}")
            
            # Ask if we should remove this duplicate
            user_input = input(f"    Remove duplicate #{duplicate['number']} from project? (y/n): ")
            if user_input.lower() == "y":
                success = delete_project_item(duplicate["id"])
                if success:
                    print(f"    ✅ Removed duplicate #{duplicate['number']} from project")
                else:
                    print(f"    ❌ Failed to remove duplicate #{duplicate['number']} from project")
            else:
                print(f"    ⏭️ Skipping removal of duplicate #{duplicate['number']}")
            
            # Add a small delay to avoid API rate limiting
            time.sleep(1)
        
        print("-" * 40)

def main():
    print("GitHub Project Duplicate Item Merger")
    print("====================================")
    
    # Get project items
    items = get_project_items()
    if not items:
        print("No items found or error fetching items.")
        return
    
    print(f"Found {len(items)} items in the project")
    
    # Identify and display duplicates
    duplicates = identify_duplicates(items)
    duplicates = compare_duplicates(duplicates)
    
    # Ask if we should proceed with merging
    if duplicates:
        user_input = input("\nProceed with merging duplicates? (y/n): ")
        if user_input.lower() == "y":
            merge_duplicates(duplicates)
            print("\n✅ Duplicate merging process completed")
        else:
            print("\nMerging cancelled")
    
    print("\nRecommendation: Update primary issues with any unique content from duplicates before removing them.")

if __name__ == "__main__":
    main()
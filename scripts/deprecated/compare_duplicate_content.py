#!/usr/bin/env python3

"""
This script compares the content of duplicate issues to see if they differ 
despite having the same titles.
"""

import json
import subprocess
import sys
from pprint import pprint

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"

# The known duplicate pairs (title, [low_id, high_id])
DUPLICATE_PAIRS = [
    ("Task Classification and Prioritization", ["13", "63"]),
    ("Agent Instance Creation", ["14", "64"]),
    ("Agent Template Management", ["15", "65"]),
    ("GitHub Task Monitoring", ["9", "59"]),
    ("Task Analysis and Agent Matching", ["12", "62"]),
    ("Agent Lifecycle Management", ["10", "60"]),
    ("Orchestrator MCP Communication", ["11", "61"]),
    ("Secure Agent Creation", ["16", "66"])
]

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
    """Get details for a specific issue"""
    success, output = run_command([
        "gh", "issue", "view", issue_number,
        "--repo", f"{OWNER}/{REPO}",
        "--json", "title,body,labels,assignees,milestone,state,author,createdAt"
    ])
    
    if success:
        return json.loads(output)
    else:
        print(f"Error getting issue {issue_number}: {output}", file=sys.stderr)
        return None

def compare_issues():
    """Compare the content of duplicate issues"""
    results = []
    
    for title, ids in DUPLICATE_PAIRS:
        low_id, high_id = ids
        
        low_issue = get_issue_details(low_id)
        high_issue = get_issue_details(high_id)
        
        if not low_issue or not high_issue:
            continue
        
        # Compare relevant fields
        differences = {}
        
        # Check for body differences (the most important content)
        if low_issue["body"] != high_issue["body"]:
            differences["body"] = {
                "low_id": low_issue["body"][:100] + "..." if len(low_issue["body"]) > 100 else low_issue["body"],
                "high_id": high_issue["body"][:100] + "..." if len(high_issue["body"]) > 100 else high_issue["body"]
            }
        
        # Compare labels
        low_labels = sorted([label["name"] for label in low_issue["labels"]])
        high_labels = sorted([label["name"] for label in high_issue["labels"]])
        
        if low_labels != high_labels:
            differences["labels"] = {
                "low_id": low_labels,
                "high_id": high_labels
            }
        
        # Compare other metadata
        other_fields = ["assignees", "milestone", "state", "author"]
        for field in other_fields:
            if low_issue[field] != high_issue[field]:
                differences[field] = {
                    "low_id": low_issue[field],
                    "high_id": high_issue[field]
                }
        
        # Add created date differences
        if low_issue["createdAt"] != high_issue["createdAt"]:
            differences["createdAt"] = {
                "low_id": low_issue["createdAt"],
                "high_id": high_issue["createdAt"]
            }
        
        results.append({
            "title": title,
            "low_id": low_id,
            "high_id": high_id,
            "has_differences": len(differences) > 0,
            "differences": differences
        })
    
    return results

if __name__ == "__main__":
    print("Comparing content of duplicate issues...")
    comparison_results = compare_issues()
    
    for result in comparison_results:
        print(f"\nIssue Title: {result['title']}")
        print(f"IDs: #{result['low_id']} and #{result['high_id']}")
        
        if result["has_differences"]:
            print("Differences found:")
            for field, diff in result["differences"].items():
                print(f"  {field}:")
                print(f"    #{result['low_id']}: {diff['low_id']}")
                print(f"    #{result['high_id']}: {diff['high_id']}")
        else:
            print("No content differences found.")
    
    print("\nSummary:")
    different_count = sum(1 for r in comparison_results if r["has_differences"])
    same_count = len(comparison_results) - different_count
    print(f"Total duplicate pairs: {len(comparison_results)}")
    print(f"Pairs with different content: {different_count}")
    print(f"Pairs with identical content: {same_count}")
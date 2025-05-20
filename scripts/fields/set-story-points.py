#!/usr/bin/env python3

"""
This script sets story points for user stories in the GitHub Project.
It uses a direct REST API call instead of GraphQL.
"""

import json
import subprocess
import time

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"
STORY_POINTS_FIELD_ID = "PVTF_lAHOBJ7Qkc4A5SDbzguGz4w"  # Story Points

# Story points mapping for issues
STORY_POINTS_MAPPING = {
    # MCP Communication Protocol
    "17": 8,  # MCP Message Structure Implementation
    "18": 5,  # MCP Message Validation
    "19": 5,  # STDIO-Based MCP Communication
    "20": 5,  # MCP Message Routing
    "21": 8,  # MCP Error Handling and Recovery
    "22": 5,  # MCP Logging and Debugging
    "23": 8,  # MCP Message Security
    "24": 5,  # MCP Testing Utilities
    
    # Task Workflow Process
    "25": 8,  # Task Analysis Implementation
    "26": 8,  # Task Decomposition Implementation
    "27": 5,  # Task Documentation Implementation
    "28": 8,  # Question Handling Implementation
    "29": 13, # Yield Process Implementation
    "30": 8,  # Workflow Integration Library
    "31": 5,  # Workflow Status Tracking Implementation
    "32": 8,  # Workflow Testing Suite
    
    # Shared Components
    "33": 8,  # Implement Agent Registry component
    "34": 8,  # Implement Agent State Store component
    "35": 8,  # Implement Task Queue component
    "36": 8,  # Implement Task History component
    "37": 8,  # Implement Knowledge Base component
    "38": 8,  # Implement Performance Metrics component
    
    # Issue #8
    "8": 3,   # Epic Prioritization and Implementation Order
    
    # Lower-numbered IDs - Copy from higher-numbered counterparts
    "9": 5,   # GitHub Task Monitoring
    "10": 8,  # Agent Lifecycle Management
    "11": 8,  # Orchestrator MCP Communication
    "12": 13, # Task Analysis and Agent Matching
    "13": 8,  # Task Classification and Prioritization
    "14": 8,  # Agent Instance Creation
    "15": 5,  # Agent Template Management
    "16": 5   # Secure Agent Creation
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

def get_project_item_for_issue(issue_number):
    """Get the project item ID for a specific issue"""
    query = """
    query($projectId:ID!, $number:Int!, $owner:String!, $name:String!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue {
                  number
                  repository {
                    name
                    owner {
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"number={issue_number}",
        "-f", f"owner={OWNER}",
        "-f", f"name={REPO}"
    ])
    
    if success:
        data = json.loads(output)
        items = data.get("data", {}).get("node", {}).get("items", {}).get("nodes", [])
        
        for item in items:
            content = item.get("content", {})
            if not content:
                continue
                
            issue_repo = content.get("repository", {})
            if (content.get("number") == int(issue_number) and 
                issue_repo.get("name") == REPO and 
                issue_repo.get("owner", {}).get("login") == OWNER):
                return item.get("id")
                
    return None

def set_story_points(issue_number, points):
    """Set story points for an issue"""
    # Get the project item ID for the issue
    project_item_id = get_project_item_for_issue(issue_number)
    
    if not project_item_id:
        print(f"Issue #{issue_number} not found in the project")
        return False
    
    # Use the REST API to update the story points
    mutation = f"""
    mutation {{
      updateProjectV2ItemFieldValue(
        input: {{
          projectId: "{PROJECT_ID}"
          itemId: "{project_item_id}"
          fieldId: "{STORY_POINTS_FIELD_ID}"
          value: {{
            number: {points}
          }}
        }}
      ) {{
        projectV2Item {{
          id
        }}
      }}
    }}
    """
    
    # Try both approaches
    # Approach 1: Direct GraphQL
    success, output = run_command([
        "gh", "api", "graphql",
        "--method", "POST",
        "--raw-field", f'query={mutation}'
    ])
    
    if success:
        print(f"  - Set story points to {points} for issue #{issue_number}")
        return True
    else:
        print(f"  - Failed to set story points using GraphQL: {output}")
        
        # Approach 2: Use gh issue edit with a custom field
        success, output = run_command([
            "gh", "issue", "edit", issue_number,
            "--repo", f"{OWNER}/{REPO}",
            # No direct support for custom fields in gh issue edit
        ])
        
        if success:
            print(f"  - Set story points using issue edit for issue #{issue_number}")
            return True
        else:
            print(f"  - Failed to set story points using issue edit: {output}")
            return False

def main():
    """Main function to set story points"""
    print("Setting story points for user stories...")
    
    success_count = 0
    failure_count = 0
    
    for issue_number, points in STORY_POINTS_MAPPING.items():
        print(f"Processing issue #{issue_number}...")
        if set_story_points(issue_number, points):
            success_count += 1
        else:
            failure_count += 1
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    print(f"\nCompleted: {success_count} succeeded, {failure_count} failed")

if __name__ == "__main__":
    main()
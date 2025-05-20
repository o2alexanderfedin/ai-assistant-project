#!/usr/bin/env python3

"""
This script migrates parent issues, priorities, and story points for user stories in the GitHub Project
that are missing these fields.
"""

import json
import subprocess
import sys
import time
import re

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Field IDs from the GitHub Project API
PARENT_FIELD_ID = "PVTF_lAHOBJ7Qkc4A5SDbzguGzY8"  # Parent issue
PRIORITY_FIELD_ID = "PVTSSF_lAHOBJ7Qkc4A5SDbzguGz4s"  # Priority
STORY_POINTS_FIELD_ID = "PVTF_lAHOBJ7Qkc4A5SDbzguGz4w"  # Story Points

# Priority option IDs
PRIORITY_OPTIONS = {
    "High": "b0542913",
    "Medium": "e191afae",
    "Low": "ede43e96"
}

# Epic mapping - maps user stories to their parent epics
# Format: "user story ID": "epic ID"
EPIC_MAPPING = {
    # Architecture Epics
    "17": "1",  # MCP Message Structure Implementation -> MCP Communication Protocol
    "18": "1",  # MCP Message Validation -> MCP Communication Protocol
    "19": "1",  # STDIO-Based MCP Communication -> MCP Communication Protocol
    "20": "1",  # MCP Message Routing -> MCP Communication Protocol
    "21": "1",  # MCP Error Handling and Recovery -> MCP Communication Protocol
    "22": "1",  # MCP Logging and Debugging -> MCP Communication Protocol
    "23": "1",  # MCP Message Security -> MCP Communication Protocol
    "24": "1",  # MCP Testing Utilities -> MCP Communication Protocol
    
    "25": "2",  # Task Analysis Implementation -> Task Workflow Process
    "26": "2",  # Task Decomposition Implementation -> Task Workflow Process
    "27": "2",  # Task Documentation Implementation -> Task Workflow Process
    "28": "2",  # Question Handling Implementation -> Task Workflow Process
    "29": "2",  # Yield Process Implementation -> Task Workflow Process
    "30": "2",  # Workflow Integration Library -> Task Workflow Process
    "31": "2",  # Workflow Status Tracking Implementation -> Task Workflow Process
    "32": "2",  # Workflow Testing Suite -> Task Workflow Process
    
    "33": "3",  # Implement Agent Registry component -> Shared Components
    "34": "3",  # Implement Agent State Store component -> Shared Components
    "35": "3",  # Implement Task Queue component -> Shared Components
    "36": "3",  # Implement Task History component -> Shared Components
    "37": "3",  # Implement Knowledge Base component -> Shared Components
    "38": "3",  # Implement Performance Metrics component -> Shared Components
    "39": "3",  # Integrate all Shared Components -> Shared Components
    "40": "3",  # Document all Shared Components -> Shared Components
    
    "41": "4",  # Implement GitHub Connector -> External Integration
    "42": "4",  # Implement CI/CD Connector -> External Integration
    "43": "4",  # Implement Development Environment -> External Integration
    "44": "4",  # Implement Secure Credential Management -> External Integration
    "45": "4",  # Implement Error Handling and Monitoring -> External Integration
    "46": "4",  # Create Integration Tests -> External Integration
    "47": "4",  # Create Documentation for External Integrations -> External Integration
    
    "48": "5",  # Implement BATS Testing Framework -> Testing Framework
    "49": "5",  # Create MCP Protocol Test Suite -> Testing Framework
    "50": "5",  # Set Up GitHub Actions Testing Pipeline -> Testing Framework
    "51": "5",  # Implement Test Coverage Tracking and Reporting -> Testing Framework
    "52": "5",  # Develop Core Agent Unit Tests -> Testing Framework
    "53": "5",  # Implement Shared Component Unit Tests -> Testing Framework
    
    "54": "6",  # Implement Developer Agent -> Agent Implementation
    "55": "6",  # Implement Reviewer Agent -> Agent Implementation
    "56": "6",  # Implement Tester Agent -> Agent Implementation
    "57": "6",  # Implement Documentation Agent -> Agent Implementation
    "58": "6",  # Implement DevOps Agent -> Agent Implementation
    
    "59": "7",  # GitHub Task Monitoring -> Orchestrator Implementation
    "60": "7",  # Agent Lifecycle Management -> Orchestrator Implementation
    "61": "7",  # Orchestrator MCP Communication -> Orchestrator Implementation
    "62": "7",  # Task Analysis and Agent Matching -> Orchestrator Implementation
    "63": "7",  # Task Classification and Prioritization -> Orchestrator Implementation
    "64": "7",  # Agent Instance Creation -> Orchestrator Implementation
    "65": "7",  # Agent Template Management -> Orchestrator Implementation
    "66": "7",  # Secure Agent Creation -> Orchestrator Implementation
    
    # Duplicate mappings (lower-numbered IDs)
    "9": "7",   # GitHub Task Monitoring -> Orchestrator Implementation
    "10": "7",  # Agent Lifecycle Management -> Orchestrator Implementation
    "11": "7",  # Orchestrator MCP Communication -> Orchestrator Implementation
    "12": "7",  # Task Analysis and Agent Matching -> Orchestrator Implementation
    "13": "7",  # Task Classification and Prioritization -> Orchestrator Implementation
    "14": "7",  # Agent Instance Creation -> Orchestrator Implementation
    "15": "7",  # Agent Template Management -> Orchestrator Implementation
    "16": "7",  # Secure Agent Creation -> Orchestrator Implementation
    
    # Epic #8 is itself a user story
    "8": "7"    # Epic Prioritization and Implementation Order -> Orchestrator Implementation
}

# Priority mapping for issues without priorities
# Format: "user story ID": "priority"
PRIORITY_MAPPING = {
    # Lower-numbered IDs - Copy from higher-numbered counterparts
    "9": "High",    # GitHub Task Monitoring
    "10": "High",   # Agent Lifecycle Management
    "11": "High",   # Orchestrator MCP Communication
    "12": "High",   # Task Analysis and Agent Matching
    "13": "High",   # Task Classification and Prioritization
    "14": "High",   # Agent Instance Creation
    "15": "High",   # Agent Template Management
    "16": "High"    # Secure Agent Creation
}

# Story points mapping for issues without story points
# Format: "user story ID": points
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
    
    # Issue #8
    "8": 3,
    
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


def extract_issue_number_from_url(url):
    """Extract issue number from a GitHub issue URL"""
    if not url:
        return None
    
    match = re.search(r'issues/(\d+)', url)
    if match:
        return match.group(1)
    return None


def set_parent_issue(project_item_id, parent_issue_id, field_info):
    """Set the parent issue for a project item"""
    # Get the parent issue URL
    parent_url = f"https://github.com/{OWNER}/{REPO}/issues/{parent_issue_id}"
    
    query = """
    mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $text:String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { 
          text: $text
        }
      }) {
        projectV2Item {
          id
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={project_item_id}",
        "-f", f"fieldId={PARENT_FIELD_ID}",
        "-f", f"text={parent_url}"
    ])
    
    if success:
        print(f"  - Set parent issue #{parent_issue_id}")
        return True
    else:
        print(f"  - Failed to set parent issue: {output}")
        return False


def set_priority(project_item_id, priority, field_info):
    """Set the priority for a project item"""
    if priority not in PRIORITY_OPTIONS:
        print(f"  - Priority option '{priority}' not found")
        return False
    
    priority_option_id = PRIORITY_OPTIONS[priority]
    
    query = """
    mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { 
          singleSelectOptionId: $optionId
        }
      }) {
        projectV2Item {
          id
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={project_item_id}",
        "-f", f"fieldId={PRIORITY_FIELD_ID}",
        "-f", f"optionId={priority_option_id}"
    ])
    
    if success:
        print(f"  - Set priority to '{priority}'")
        return True
    else:
        print(f"  - Failed to set priority: {output}")
        return False


def set_story_points(project_item_id, points, field_info):
    """Set the story points for a project item"""
    # Convert points to float string
    points_str = f"{float(points)}"
    
    query = """
    mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $number:Float!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { 
          number: $number
        }
      }) {
        projectV2Item {
          id
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={project_item_id}",
        "-f", f"fieldId={STORY_POINTS_FIELD_ID}",
        "-f", f"number={points_str}"
    ])
    
    if success:
        print(f"  - Set story points to {points}")
        return True
    else:
        print(f"  - Failed to set story points: {output}")
        return False


def migrate_missing_fields():
    """Migrate missing parent issues, priorities, and story points"""
    # Load the missing fields data
    try:
        with open("missing_fields.json", "r") as f:
            results = json.load(f)
    except FileNotFoundError:
        print("missing_fields.json not found. Please run find_missing_parent_issues.py first.")
        return False
    
    missing_parent = results["missing_parent"]
    missing_priority = results["missing_priority"]
    missing_story_points = results["missing_story_points"]
    field_info = results["field_info"]
    
    # 1. Migrate parent issues
    print("\n=== Migrating Parent Issues ===")
    for story in missing_parent:
        issue_number = str(story["issue_number"])
        title = story["title"]
        project_item_id = story["project_item_id"]
        
        print(f"Processing #{issue_number} - {title}")
        
        if issue_number in EPIC_MAPPING:
            parent_issue_id = EPIC_MAPPING[issue_number]
            set_parent_issue(project_item_id, parent_issue_id, field_info)
        else:
            print(f"  - No parent issue mapping found for #{issue_number}")
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    # 2. Migrate priorities
    print("\n=== Migrating Priorities ===")
    for story in missing_priority:
        issue_number = str(story["issue_number"])
        title = story["title"]
        project_item_id = story["project_item_id"]
        
        print(f"Processing #{issue_number} - {title}")
        
        if issue_number in PRIORITY_MAPPING:
            priority = PRIORITY_MAPPING[issue_number]
            set_priority(project_item_id, priority, field_info)
        else:
            print(f"  - No priority mapping found for #{issue_number}")
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    # 3. Migrate story points
    print("\n=== Migrating Story Points ===")
    for story in missing_story_points:
        issue_number = str(story["issue_number"])
        title = story["title"]
        project_item_id = story["project_item_id"]
        
        print(f"Processing #{issue_number} - {title}")
        
        if issue_number in STORY_POINTS_MAPPING:
            points = STORY_POINTS_MAPPING[issue_number]
            set_story_points(project_item_id, points, field_info)
        else:
            print(f"  - No story points mapping found for #{issue_number}")
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    return True


if __name__ == "__main__":
    print("Migrating missing fields for user stories...")
    success = migrate_missing_fields()
    
    if success:
        print("\nMigration completed. Please run find_missing_parent_issues.py again to verify.")
    else:
        print("\nMigration failed. Please check the error messages above.")
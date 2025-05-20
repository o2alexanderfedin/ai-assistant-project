#!/usr/bin/env python3

"""
This script updates parent issues and story points for user stories
in the GitHub Project that are missing them, using the project_items.json mapping.
"""

import json
import subprocess
import time

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Epic mapping - maps user stories to their parent epics
# Format: "user story ID": "epic ID"
EPIC_MAPPING = {
    # Architecture Epics
    "17": "2",  # MCP Message Structure Implementation -> MCP Communication Protocol 
    "18": "2",  # MCP Message Validation -> MCP Communication Protocol
    "19": "2",  # STDIO-Based MCP Communication -> MCP Communication Protocol
    "20": "2",  # MCP Message Routing -> MCP Communication Protocol
    "21": "2",  # MCP Error Handling and Recovery -> MCP Communication Protocol
    "22": "2",  # MCP Logging and Debugging -> MCP Communication Protocol
    "23": "2",  # MCP Message Security -> MCP Communication Protocol
    "24": "2",  # MCP Testing Utilities -> MCP Communication Protocol
    
    "25": "4",  # Task Analysis Implementation -> Task Workflow Process
    "26": "4",  # Task Decomposition Implementation -> Task Workflow Process
    "27": "4",  # Task Documentation Implementation -> Task Workflow Process
    "28": "4",  # Question Handling Implementation -> Task Workflow Process
    "29": "4",  # Yield Process Implementation -> Task Workflow Process
    "30": "4",  # Workflow Integration Library -> Task Workflow Process
    "31": "4",  # Workflow Status Tracking Implementation -> Task Workflow Process
    "32": "4",  # Workflow Testing Suite -> Task Workflow Process
    
    "33": "5",  # Implement Agent Registry component -> Shared Component Implementation
    "34": "5",  # Implement Agent State Store component -> Shared Component Implementation
    "35": "5",  # Implement Task Queue component -> Shared Component Implementation
    "36": "5",  # Implement Task History component -> Shared Component Implementation
    "37": "5",  # Implement Knowledge Base component -> Shared Component Implementation
    "38": "5",  # Implement Performance Metrics component -> Shared Component Implementation
    "39": "5",  # Integrate all Shared Components -> Shared Component Implementation
    "40": "5",  # Document all Shared Components -> Shared Component Implementation
    
    "41": "6",  # Implement GitHub Connector -> External Integration
    "42": "6",  # Implement CI/CD Connector -> External Integration
    "43": "6",  # Implement Development Environment -> External Integration
    "44": "6",  # Implement Secure Credential Management -> External Integration
    "45": "6",  # Implement Error Handling and Monitoring -> External Integration
    "46": "6",  # Create Integration Tests -> External Integration
    "47": "6",  # Create Documentation for External Integrations -> External Integration
    
    "48": "7",  # Implement BATS Testing Framework -> Testing Framework
    "49": "7",  # Create MCP Protocol Test Suite -> Testing Framework
    "50": "7",  # Set Up GitHub Actions Testing Pipeline -> Testing Framework
    "51": "7",  # Implement Test Coverage Tracking and Reporting -> Testing Framework
    "52": "7",  # Develop Core Agent Unit Tests -> Testing Framework
    "53": "7",  # Implement Shared Component Unit Tests -> Testing Framework
    
    "54": "3",  # Implement Developer Agent -> Agent Implementation
    "55": "3",  # Implement Reviewer Agent -> Agent Implementation
    "56": "3",  # Implement Tester Agent -> Agent Implementation
    "57": "3",  # Implement Documentation Agent -> Agent Implementation
    "58": "3",  # Implement DevOps Agent -> Agent Implementation
    
    "8": "1",    # Epic Prioritization and Implementation Order -> Core Agent System Implementation
    
    # Lower-numbered IDs (if they're not already mapped)
    "9": "1",   # GitHub Task Monitoring -> Core Agent System Implementation
    "10": "1",  # Agent Lifecycle Management -> Core Agent System Implementation
    "11": "1",  # Orchestrator MCP Communication -> Core Agent System Implementation
    "12": "1",  # Task Analysis and Agent Matching -> Core Agent System Implementation
    "13": "1",  # Task Classification and Prioritization -> Core Agent System Implementation
    "14": "1",  # Agent Instance Creation -> Core Agent System Implementation
    "15": "1",  # Agent Template Management -> Core Agent System Implementation
    "16": "1"   # Secure Agent Creation -> Core Agent System Implementation
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

def set_epic_field(project_item_id, epic_id, epic_name, project_items):
    """Set the Epic field for a user story"""
    # Find the Epic field ID from any item that has it set
    epic_field_id = None
    epic_option_id = None
    
    for item_data in project_items.values():
        fields = item_data.get("fields", {})
        if "Epic" in fields:
            epic_name = fields["Epic"]
            # Look for an item that has item fields we can inspect for IDs
            item_id = item_data["item_id"]
            
            query = """
            query($itemId:ID!) {
              node(id: $itemId) {
                ... on ProjectV2Item {
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        field {
                          ... on ProjectV2SingleSelectField {
                            id
                            name
                          }
                        }
                        optionId
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
                "-f", f"itemId={item_id}"
            ])
            
            if success:
                data = json.loads(output)
                field_values = data.get("data", {}).get("node", {}).get("fieldValues", {}).get("nodes", [])
                
                for field_value in field_values:
                    field = field_value.get("field", {})
                    if field.get("name") == "Epic":
                        epic_field_id = field.get("id")
                        epic_option_id = field_value.get("optionId")
                        break
                
                if epic_field_id and epic_option_id:
                    break
    
    if not epic_field_id or not epic_option_id:
        print(f"  - Epic field ID or option ID not found")
        return False
    
    # Now set the Epic field
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
        "-f", f"fieldId={epic_field_id}",
        "-f", f"optionId={epic_option_id}"
    ])
    
    if success:
        print(f"  - Set Epic to '{epic_name}'")
        return True
    else:
        print(f"  - Failed to set Epic: {output}")
        return False

def set_story_points(project_item_id, points):
    """Set the story points for a user story"""
    # Convert points to float string
    points_str = str(float(points))
    
    # Get the Story Points field ID
    story_points_field_id = None
    
    # Get all field definitions for the project
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2FieldCommon {
                id
                name
                dataType
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
        "-f", f"projectId={PROJECT_ID}"
    ])
    
    if success:
        data = json.loads(output)
        fields = data.get("data", {}).get("node", {}).get("fields", {}).get("nodes", [])
        
        for field in fields:
            if field.get("name") == "Story Points" and field.get("dataType") == "NUMBER":
                story_points_field_id = field.get("id")
                break
    
    if not story_points_field_id:
        print(f"  - Story Points field ID not found")
        return False
    
    # Set the story points
    mutation = f"""
    mutation {{
      updateProjectV2ItemFieldValue(
        input: {{
          projectId: "{PROJECT_ID}"
          itemId: "{project_item_id}"
          fieldId: "{story_points_field_id}"
          value: {{
            number: {points_str}
          }}
        }}
      ) {{
        projectV2Item {{
          id
        }}
      }}
    }}
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "--method", "POST",
        "--raw-field", f'query={mutation}'
    ])
    
    if success:
        print(f"  - Set Story Points to {points}")
        return True
    else:
        print(f"  - Failed to set Story Points: {output}")
        return False

def update_fields():
    """Update parent issues and story points for user stories"""
    # Load the project items mapping
    try:
        with open("project_items.json", "r") as f:
            project_items = json.load(f)
    except FileNotFoundError:
        print("project_items.json not found. Please run list_project_items.py first.")
        return False
    
    print("\n=== Updating Epic field (Parent Issues) ===")
    for issue_number, epic_id in EPIC_MAPPING.items():
        if issue_number not in project_items:
            print(f"Issue #{issue_number} not found in project_items.json")
            continue
        
        item_data = project_items[issue_number]
        title = item_data["title"]
        project_item_id = item_data["item_id"]
        
        # Check if Epic field is already set
        if "Epic" in item_data.get("fields", {}):
            print(f"Issue #{issue_number} - {title}: Epic already set to {item_data['fields']['Epic']}")
            continue
        
        # Get the epic name
        epic_name = None
        if epic_id in project_items:
            epic_name = project_items[epic_id]["title"]
        
        print(f"Processing #{issue_number} - {title} -> Epic #{epic_id} ({epic_name})")
        set_epic_field(project_item_id, epic_id, epic_name, project_items)
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    print("\n=== Updating Story Points ===")
    for issue_number, points in STORY_POINTS_MAPPING.items():
        if issue_number not in project_items:
            print(f"Issue #{issue_number} not found in project_items.json")
            continue
        
        item_data = project_items[issue_number]
        title = item_data["title"]
        project_item_id = item_data["item_id"]
        
        # Check if Story Points are already set
        if "Story Points" in item_data.get("fields", {}):
            print(f"Issue #{issue_number} - {title}: Story Points already set to {item_data['fields']['Story Points']}")
            continue
        
        print(f"Processing #{issue_number} - {title} -> Story Points: {points}")
        set_story_points(project_item_id, points)
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    return True

if __name__ == "__main__":
    print("Updating parent issues and story points for user stories...")
    success = update_fields()
    
    if success:
        print("\nUpdate completed. Please run list_project_items.py again to verify.")
    else:
        print("\nUpdate failed. Please check the error messages above.")
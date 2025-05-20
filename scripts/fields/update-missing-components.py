#!/usr/bin/env python3

"""
This script updates the Component field for user stories in the GitHub Project that don't have it set.
"""

import json
import subprocess
import time

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Component mapping - maps issue numbers to components
# Format: "issue_number": "component"
COMPONENT_MAPPING = {
    # MCP Communication Protocol stories - MCP component
    "17": "MCP",  # MCP Message Structure Implementation
    "18": "MCP",  # MCP Message Validation
    "19": "MCP",  # STDIO-Based MCP Communication
    "20": "MCP",  # MCP Message Routing
    "21": "MCP",  # MCP Error Handling and Recovery
    "22": "MCP",  # MCP Logging and Debugging
    "23": "MCP",  # MCP Message Security
    "24": "MCP",  # MCP Testing Utilities
    
    # Task Workflow Process stories - Workflow component
    "25": "Workflow",  # Task Analysis Implementation
    "26": "Workflow",  # Task Decomposition Implementation
    "27": "Workflow",  # Task Documentation Implementation
    "28": "Workflow",  # Question Handling Implementation
    "29": "Workflow",  # Yield Process Implementation
    "30": "Workflow",  # Workflow Integration Library
    "31": "Workflow",  # Workflow Status Tracking Implementation
    "32": "Workflow",  # Workflow Testing Suite
    
    # Shared Component Implementation stories - Shared Components component
    "33": "Shared Components",  # Implement Agent Registry component
    "34": "Shared Components",  # Implement Agent State Store component
    "35": "Shared Components",  # Implement Task Queue component
    "36": "Shared Components",  # Implement Task History component
    
    # Lower-numbered IDs - Match their corresponding epics
    "8": "Core Agents",  # Epic Prioritization and Implementation Order
    "9": "Core Agents",  # GitHub Task Monitoring
    "10": "Core Agents",  # Agent Lifecycle Management
    "11": "Core Agents",  # Orchestrator MCP Communication
    "12": "Core Agents",  # Task Analysis and Agent Matching
    "13": "Core Agents",  # Task Classification and Prioritization
    "14": "Core Agents",  # Agent Instance Creation
    "15": "Core Agents",  # Agent Template Management
    "16": "Core Agents"   # Secure Agent Creation
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

def get_component_field_info():
    """Get Component field information"""
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
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
        "-f", f"projectId={PROJECT_ID}"
    ])
    
    if success:
        data = json.loads(output)
        fields = data.get("data", {}).get("node", {}).get("fields", {}).get("nodes", [])
        
        component_field_id = None
        component_options = {}
        
        for field in fields:
            if field.get("name") == "Component":
                component_field_id = field.get("id")
                for option in field.get("options", []):
                    component_options[option.get("name")] = option.get("id")
                break
        
        return component_field_id, component_options
    else:
        print(f"Failed to get Component field information: {output}")
        return None, {}

def set_component(project_item_id, component, component_field_id, component_options):
    """Set the Component field for a project item"""
    if component not in component_options:
        print(f"  - Component '{component}' not found in options")
        return False
    
    component_option_id = component_options[component]
    
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
        "-f", f"fieldId={component_field_id}",
        "-f", f"optionId={component_option_id}"
    ])
    
    if success:
        print(f"  - Set Component to '{component}'")
        return True
    else:
        print(f"  - Failed to set Component: {output}")
        return False

def update_missing_components():
    """Update the Component field for user stories that don't have it set"""
    # Load the project items mapping
    try:
        with open("project_items.json", "r") as f:
            project_items = json.load(f)
    except FileNotFoundError:
        print("project_items.json not found. Please run list_project_items.py first.")
        return False
    
    # Get Component field information
    component_field_id, component_options = get_component_field_info()
    if not component_field_id:
        print("Component field ID not found")
        return False
    
    print(f"Component options: {component_options}")
    
    print("\n=== Updating Component field ===")
    for issue_number, component in COMPONENT_MAPPING.items():
        if issue_number not in project_items:
            print(f"Issue #{issue_number} not found in project_items.json")
            continue
        
        item_data = project_items[issue_number]
        title = item_data["title"]
        project_item_id = item_data["item_id"]
        
        # Check if Component field is already set
        if "Component" in item_data.get("fields", {}):
            print(f"Issue #{issue_number} - {title}: Component already set to {item_data['fields']['Component']}")
            continue
        
        print(f"Processing #{issue_number} - {title} -> Component: {component}")
        set_component(project_item_id, component, component_field_id, component_options)
        
        # Add a small delay to avoid rate limiting
        time.sleep(0.2)
    
    return True

if __name__ == "__main__":
    print("Updating Component field for user stories...")
    success = update_missing_components()
    
    if success:
        print("\nUpdate completed. Please run list_project_items.py again to verify.")
    else:
        print("\nUpdate failed. Please check the error messages above.")
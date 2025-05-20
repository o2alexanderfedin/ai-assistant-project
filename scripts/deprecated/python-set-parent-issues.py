#!/usr/bin/env python3
"""
Python script to set Parent issue field values in GitHub Projects
This script handles the entire process:
1. Collect data from GitHub API
2. Map parent-child relationships
3. Execute updates
4. Verify results
"""

import json
import os
import re
import subprocess
import sys
from typing import Dict, List


# Configuration
PROJECT_NUM = 2
REPO = "o2alexanderfedin/ai-assistant-project"
ORG_OR_USER = "o2alexanderfedin"


def run_gh_command(command: str) -> str:
    """Run a GitHub CLI command and return the output"""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running command: {command}")
        print(f"Error: {result.stderr}")
        return ""
    return result.stdout


def run_graphql_query(query: str, variables: Dict = None) -> Dict:
    """Run a GraphQL query with the GitHub CLI"""
    if variables:
        # Create temp file for variables
        with open('variables.json', 'w') as f:
            json.dump(variables, f)
        command = f'gh api graphql -F query="{query}" -f variables=@variables.json'
        # Clean up temp file after use
        result = run_gh_command(command)
        os.remove('variables.json')
    else:
        # Replace newlines and double quotes for shell compatibility
        query = query.replace('\n', ' ').replace('"', '\\"')
        command = f'gh api graphql -f query="{query}"'
        result = run_gh_command(command)
    
    try:
        return json.loads(result)
    except json.JSONDecodeError:
        print(f"Error decoding JSON from: {result}")
        return {}


def run_graphql_mutation(mutation: str, variables: Dict) -> Dict:
    """Run a GraphQL mutation with the GitHub CLI"""
    # Create temp files for mutation and variables
    with open('mutation.graphql', 'w') as f:
        f.write(mutation)
    with open('variables.json', 'w') as f:
        json.dump(variables, f)
    
    command = f'gh api graphql -F query=@mutation.graphql -f variables=@variables.json'
    result = run_gh_command(command)
    
    # Clean up temp files
    os.remove('mutation.graphql')
    os.remove('variables.json')
    
    try:
        return json.loads(result)
    except json.JSONDecodeError:
        print(f"Error decoding JSON from: {result}")
        return {}


def get_project_details() -> Dict:
    """Get project ID and other details"""
    print("Getting project information...")
    query = """
    {
      user(login: "%s") {
        projectV2(number: %d) {
          id
          title
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                id
                name
              }
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
    """ % (ORG_OR_USER, PROJECT_NUM)
    
    result = run_graphql_query(query)
    if not result or 'data' not in result or 'user' not in result['data'] or 'projectV2' not in result['data']['user']:
        print(f"❌ Could not find project #{PROJECT_NUM}")
        sys.exit(1)
    
    project_data = result['data']['user']['projectV2']
    print(f"Found project: {project_data['title']} (ID: {project_data['id']})")
    
    # Extract Parent issue field ID
    parent_field_id = None
    for field in project_data['fields']['nodes']:
        if field.get('name') == 'Parent issue':
            parent_field_id = field.get('id')
            break
    
    project_data['parent_field_id'] = parent_field_id
    return project_data


def get_epics() -> List[Dict]:
    """Get all epic issues (#1-7)"""
    print("Getting all epic issues (#1-7)...")
    epics = []
    
    for i in range(1, 8):
        command = f'gh issue view {i} --json id,number,title,body --repo "{REPO}"'
        result = run_gh_command(command)
        if not result:
            print(f"❌ Could not find epic #{i}")
            continue
        
        epic = json.loads(result)
        epics.append(epic)
        print(f"  Epic #{epic['number']}: {epic['title']} (ID: {epic['id']})")
    
    return epics


def get_project_items() -> List[Dict]:
    """Get all items in the project"""
    print("Retrieving all items in the project...")
    query = """
    {
      user(login: "%s") {
        projectV2(number: %d) {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue {
                  id
                  number
                  title
                  body
                  repository {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
    """ % (ORG_OR_USER, PROJECT_NUM)
    
    result = run_graphql_query(query)
    if not result or 'data' not in result:
        print("❌ Could not retrieve project items")
        return []
    
    items = result['data']['user']['projectV2']['items']['nodes']
    valid_items = [item for item in items if item.get('content')]
    print(f"Found {len(valid_items)} items in the project")
    return valid_items


def find_parent_child_relationships(epics: List[Dict], items: List[Dict]) -> List[Dict]:
    """Find parent-child relationships based on 'Epic: #X' references"""
    print("Analyzing issues to find Epic links...")
    relationships = []
    
    # Create a lookup dict for epics
    epic_lookup = {epic['number']: epic for epic in epics}
    
    for item in items:
        if not item.get('content'):
            continue
        
        issue_num = item['content']['number']
        issue_title = item['content']['title']
        body = item['content']['body']
        
        # Skip epics (issues #1-7)
        if 1 <= issue_num <= 7:
            continue
        
        # Look for "Epic: #X" pattern
        match = re.search(r'[Ee]pic:\s*#(\d+)', body)
        if match:
            parent_num = int(match.group(1))
            
            # Only process epics 1-7
            if 1 <= parent_num <= 7 and parent_num in epic_lookup:
                rel = {
                    'child_num': issue_num,
                    'child_title': issue_title,
                    'child_item_id': item['id'],
                    'child_issue_id': item['content']['id'],
                    'parent_num': parent_num,
                    'parent_title': epic_lookup[parent_num]['title'],
                    'parent_issue_id': epic_lookup[parent_num]['id']
                }
                relationships.append(rel)
                print(f"  ✓ Found: #{issue_num} → Epic #{parent_num}")
    
    print(f"Found {len(relationships)} parent-child relationships")
    return relationships


def set_parent_issue_field(project_id: str, parent_field_id: str, 
                          relationships: List[Dict]) -> Dict:
    """Set Parent issue field values for all relationships"""
    print("Setting Parent issue field values...")
    results = {
        'total': len(relationships),
        'success': 0,
        'failure': 0,
        'failures': []
    }
    
    if not parent_field_id:
        print("❌ No Parent issue field ID found")
        return results
    
    # First approach: Use ProjectV2FieldParentValue format
    mutation = """
    mutation SetParentValue($projectId: ID!, $itemId: ID!, $fieldId: ID!, 
                           $parentId: ID!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: { 
            parentId: $parentId
          }
        }
      ) {
        projectV2Item {
          id
        }
      }
    }
    """

    for rel in relationships:
        child_num = rel['child_num']
        parent_num = rel['parent_num']
        print(f"Processing: Child #{child_num} → Parent Epic #{parent_num}")
        
        # Attempt to set the parent issue field
        variables = {
            'projectId': project_id,
            'itemId': rel['child_item_id'],
            'fieldId': parent_field_id,
            'parentId': rel['parent_issue_id']
        }
        
        result = run_graphql_mutation(mutation, variables)
        
        # Check if successful
        if (result and 'data' in result and 
                'updateProjectV2ItemFieldValue' in result['data']):
            print(f"  ✅ Successfully linked child #{child_num} to parent #{parent_num}")
            results['success'] += 1
        else:
            # Second approach: Try with hardcoded "PARENT" field ID
            print(f"  ⚠️ First approach failed, trying with hardcoded PARENT field ID...")
            variables['fieldId'] = "PARENT"
            result = run_graphql_mutation(mutation, variables)
            
            if (result and 'data' in result and 
                    'updateProjectV2ItemFieldValue' in result['data']):
                msg = f"  ✅ Successfully linked (with hardcoded ID)"
                print(msg)
                results['success'] += 1
            else:
                print(f"  ❌ Failed to link child #{child_num} to parent #{parent_num}")
                results['failure'] += 1
                results['failures'].append({
                    'child_num': child_num,
                    'parent_num': parent_num,
                    'error': result.get('errors', [])
                })
    
    return results


def generate_manual_guide(relationships: List[Dict]) -> None:
    """Generate a manual guide for setting parent issue fields"""
    print("\nGenerating manual guide for setting parent issue fields...")
    
    guide = [
        "⚠️ Important Manual Instructions for Setting Parent Issue Fields ⚠️",
        "",
        "Due to limitations in the GitHub Projects GraphQL API for setting the Parent issue field,",
        "you may need to set these relationships manually in the GitHub UI:",
        "",
        f"1. Go to: https://github.com/users/{ORG_OR_USER}/projects/{PROJECT_NUM}",
        "2. For each user story, set its Parent issue field to the corresponding epic:",
        ""
    ]
    
    for rel in relationships:
        guide.append(
            f"• Issue #{rel['child_num']}: '{rel['child_title']}' → "
            f"Epic #{rel['parent_num']}: '{rel['parent_title']}'"
        )
    
    guide.extend([
        "",
        "📋 Steps to Set Parent Issues:",
        "1. Click on an issue in the project board",
        "2. In the side panel, find the 'Parent issue' field",
        "3. Type '#' and select the appropriate parent epic from the dropdown",
        "4. Save the change and proceed to the next issue",
        "",
        "This will establish the parent-child hierarchy in the GitHub Project."
    ])
    
    # Write the guide to a file
    guide_path = "parent-issue-guide.md"
    with open(guide_path, 'w') as f:
        f.write('\n'.join(guide))
    
    print(f"Manual guide written to: {guide_path}")


def main():
    """Main function"""
    print("🔍 Setting Parent issue field values for GitHub Project...")
    
    # 1. Collect Data
    project_data = get_project_details()
    epics = get_epics()
    items = get_project_items()
    
    # 2. Map Relationships
    relationships = find_parent_child_relationships(epics, items)
    
    if not relationships:
        print("No parent-child relationships found. Exiting.")
        return
    
    # 3. Execute Updates
    results = set_parent_issue_field(
        project_data['id'], 
        project_data.get('parent_field_id', 'PARENT'),
        relationships
    )
    
    # 4. Generate Manual Guide (as a fallback)
    generate_manual_guide(relationships)
    
    # 5. Summary
    print("\n📊 Summary:")
    print(f"Total relationships found: {results['total']}")
    print(f"Successfully set: {results['success']}")
    print(f"Failed to set: {results['failure']}")
    
    if results['failure'] > 0:
        print("\n⚠️ Some parent-child relationships couldn't be set through the API.")
        print("Please use the generated guide to finish setting these relationships.")
    else:
        print("\n✅ All parent-child relationships have been set successfully!")
        print("Please verify in the GitHub UI that all relationships are correct.")


if __name__ == "__main__":
    main()
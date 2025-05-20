#!/usr/bin/env python3

import subprocess
import json
import time
import sys
from typing import Dict, List, Optional, Tuple, Any

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Parent relationship mapping (epic issue number -> list of child issue numbers)
PARENT_RELATIONSHIPS = {
    "1": ["66", "65", "64", "63", "62", "61", "60", "59"],
    "2": ["17", "18", "19", "20", "21", "22", "23", "24"],
    "3": ["54", "55", "56", "57", "58"],
    "4": ["25", "26", "27", "28", "29", "30", "31", "32"],
    "5": ["33", "34", "35", "36", "37", "38", "39", "40"],
    "6": ["41", "42", "43", "44", "45", "46", "47"],
    "7": ["48", "49", "50", "51", "52", "53"]
}

class GithubMigrator:
    def __init__(self):
        self.project_fields = None
        self.project_items = None
        self.issues_cache = {}  # Cache for issue details
        self.item_id_cache = {}  # Cache for project item IDs
    
    def run_command(self, cmd: List[str], retry_count=3) -> Tuple[bool, str]:
        """Run a command and return if it succeeded and the output"""
        for attempt in range(retry_count):
            try:
                result = subprocess.run(cmd, check=True, capture_output=True, text=True)
                return True, result.stdout
            except subprocess.CalledProcessError as e:
                if attempt < retry_count - 1:
                    print(f"Command failed, retrying ({attempt+1}/{retry_count})...")
                    time.sleep(2)  # Wait before retrying
                    continue
                return False, f"Error: {e.stderr}"
    
    def get_all_github_issues(self) -> List[Dict[str, Any]]:
        """Get all GitHub issues with their fields"""
        print("🔍 Getting all GitHub issues...")
        success, output = self.run_command([
            "gh", "issue", "list", 
            "--repo", f"{OWNER}/{REPO}", 
            "--limit", "100", 
            "--json", "number,title,labels"
        ])
        
        if success:
            return json.loads(output)
        else:
            print(f"Failed to get issues: {output}")
            return []
    
    def get_issue_details(self, issue_number: str) -> Dict[str, Any]:
        """Get details for a specific GitHub issue (with caching)"""
        if issue_number in self.issues_cache:
            return self.issues_cache[issue_number]
        
        success, output = self.run_command([
            "gh", "issue", "view", issue_number,
            "--repo", f"{OWNER}/{REPO}",
            "--json", "number,title,body,labels,comments,assignees,milestone,id"
        ])
        
        if success:
            issue_data = json.loads(output)
            self.issues_cache[issue_number] = issue_data
            return issue_data
        else:
            print(f"Failed to get details for issue #{issue_number}")
            return {}
    
    def get_project_fields(self) -> Dict[str, Any]:
        """Get project fields including Type field and its options"""
        print("🔍 Getting project fields...")
        if self.project_fields:
            return self.project_fields
            
        query = """
        query($projectId:ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
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
        """
        success, output = self.run_command([
            "gh", "api", "graphql",
            "-f", f"query={query}",
            "-f", f"projectId={PROJECT_ID}"
        ])
        
        if success:
            data = json.loads(output)
            fields = {}
            
            # Extract all fields
            nodes = data.get("data", {}).get("node", {}).get("fields", {}).get("nodes", [])
            for node in nodes:
                name = node.get("name")
                fields[name] = {
                    "id": node.get("id"),
                    "options": node.get("options", [])
                }
            
            self.project_fields = fields
            return fields
        else:
            print(f"Failed to get project fields: {output}")
            return {}
    
    def get_all_project_items(self) -> List[Dict[str, Any]]:
        """Get all items in the GitHub project"""
        print("🔍 Getting all project items...")
        if self.project_items:
            return self.project_items
            
        success, output = self.run_command(["gh", "project", "item-list", PROJECT_NUM, "--owner", OWNER])
        
        if success:
            # Parse the output to extract item information
            items = []
            lines = output.strip().split('\n')
            for line in lines:
                # Extract issue number and title from the line
                parts = line.split('\t')
                if len(parts) >= 4 and parts[0] == "Issue":
                    items.append({
                        "type": parts[0],
                        "title": parts[1],
                        "number": parts[2],
                        "repo": parts[3],
                        "id": parts[4] if len(parts) > 4 else None
                    })
            self.project_items = items
            return items
        else:
            print(f"Failed to get project items: {output}")
            return []
    
    def add_issue_to_project(self, issue_number: str) -> bool:
        """Add an issue to the GitHub project"""
        print(f"  ➕ Adding issue #{issue_number} to project...")
        success, output = self.run_command([
            "gh", "project", "item-add", PROJECT_NUM,
            "--owner", OWNER,
            "--url", f"https://github.com/{OWNER}/{REPO}/issues/{issue_number}"
        ])
        
        if success:
            print(f"  ✅ Successfully added issue #{issue_number} to project")
            # Invalidate the project items cache
            self.project_items = None
            # Wait for the item to be added
            time.sleep(2)
            return True
        else:
            print(f"  ❌ Failed to add issue #{issue_number} to project: {output}")
            return False
    
    def get_project_item_id(self, issue_number: str) -> Optional[str]:
        """Get the project item ID for an issue (with caching)"""
        if issue_number in self.item_id_cache:
            return self.item_id_cache[issue_number]
            
        query = """
        query($projectId:ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              items(first: 100) {
                nodes {
                  id
                  content {
                    ... on Issue {
                      number
                      title
                    }
                  }
                }
              }
            }
          }
        }
        """
        success, output = self.run_command([
            "gh", "api", "graphql",
            "-f", f"query={query}",
            "-f", f"projectId={PROJECT_ID}"
        ])
        
        if success:
            data = json.loads(output)
            nodes = data.get("data", {}).get("node", {}).get("items", {}).get("nodes", [])
            
            # Cache all item IDs at once
            for node in nodes:
                content = node.get("content", {})
                if content and "number" in content:
                    num = str(content.get("number"))
                    self.item_id_cache[num] = node.get("id")
            
            # Return the requested item ID
            return self.item_id_cache.get(issue_number)
        else:
            print(f"Failed to get item ID: {output}")
            return None
    
    def set_issue_type(self, item_id: str, field_id: str, option_id: str, type_name: str) -> bool:
        """Set the type field for an issue in the project"""
        print(f"  Setting type to {type_name}...")
        
        mutation = """
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
        
        success, output = self.run_command([
            "gh", "api", "graphql",
            "-f", f"query={mutation}",
            "-f", f"projectId={PROJECT_ID}",
            "-f", f"itemId={item_id}",
            "-f", f"fieldId={field_id}",
            "-f", f"optionId={option_id}"
        ])
        
        if success and "errors" not in output.lower():
            print(f"  ✅ Successfully set type to {type_name}")
            return True
        else:
            print(f"  ❌ Failed to set type to {type_name}: {output}")
            return False
    
    def set_parent_relationship(self, parent_num: str, child_num: str) -> bool:
        """Set parent-child relationship between issues"""
        print(f"  Setting parent relationship: Parent #{parent_num} for Child #{child_num}")
        
        # Get the parent and child issue IDs
        parent_issue = self.get_issue_details(parent_num)
        parent_id = parent_issue.get("id")
        
        child_issue = self.get_issue_details(child_num)
        child_id = child_issue.get("id")
        
        if not parent_id or not child_id:
            print(f"  ❌ Could not get IDs for parent #{parent_num} or child #{child_num}")
            return False
        
        # Set the parent-child relationship
        mutation = """
        mutation($parentId:ID!, $childId:ID!) {
          addSubIssue(input: {
            issueId: $parentId,
            subIssueId: $childId,
            replaceParent: true
          }) {
            issue { number, title }
            subIssue { number, title }
          }
        }
        """
        
        success, output = self.run_command([
            "gh", "api", "graphql",
            "-f", f"query={mutation}",
            "-f", f"parentId={parent_id}",
            "-f", f"childId={child_id}"
        ])
        
        if success:
            if "duplicate sub-issues" in output:
                print(f"  ℹ️ Relationship already exists")
                return True
            elif "errors" not in output.lower():
                print(f"  ✅ Successfully set parent relationship")
                return True
            else:
                print(f"  ❌ Failed to set parent relationship: {output}")
                return False
        else:
            print(f"  ❌ Failed to set parent relationship: {output}")
            return False
    
    def migrate_issue_comments(self, issue_number: str, comments: List[Dict[str, Any]]) -> bool:
        """Migrate comments from GitHub issue to project notes (if applicable)"""
        if not comments:
            return True  # No comments to migrate
        
        print(f"  ℹ️ Issue has {len(comments)} comments (these would need to be manually added as project notes)")
        return True
    
    def process_issue(self, issue: Dict[str, Any]) -> None:
        """Process a single GitHub issue, ensuring it's in the project with all fields"""
        issue_number = str(issue.get("number"))
        issue_title = issue.get("title")
        
        print(f"Processing issue #{issue_number}: '{issue_title}'")
        
        # Get more detailed issue information
        issue_details = self.get_issue_details(issue_number)
        
        # Get project items if not already loaded
        if not self.project_items:
            self.project_items = self.get_all_project_items()
        
        # Get project fields if not already loaded
        if not self.project_fields:
            self.project_fields = self.get_project_fields()
        
        # Get Type field and its options
        type_field = self.project_fields.get("Type", {})
        type_field_id = type_field.get("id")
        type_options = {opt.get("name"): opt.get("id") for opt in type_field.get("options", [])}
        
        # Determine if issue is epic or user story
        is_epic = any(label.get("name") == "epic" for label in issue.get("labels", []))
        type_name = "Epic" if is_epic else "User Story"
        type_option_id = type_options.get(type_name)
        
        # Check if issue is already in project
        in_project = False
        for item in self.project_items:
            if item.get("number") == issue_number or item.get("title") == issue_title:
                in_project = True
                break
        
        # Add issue to project if not already present
        if in_project:
            print(f"  ✓ Issue already in project")
        else:
            if not self.add_issue_to_project(issue_number):
                print(f"  ⚠️ Skipping further processing for issue #{issue_number}")
                return
        
        # Get the item ID
        item_id = self.get_project_item_id(issue_number)
        if not item_id:
            print(f"  ⚠️ Could not find item ID for issue #{issue_number}")
            return
        
        # Set the type
        if type_field_id and type_option_id:
            self.set_issue_type(item_id, type_field_id, type_option_id, type_name)
        
        # Set parent relationship if this is a child issue
        for parent_num, children in PARENT_RELATIONSHIPS.items():
            if issue_number in children:
                self.set_parent_relationship(parent_num, issue_number)
                break
        
        # Migrate comments
        self.migrate_issue_comments(issue_number, issue_details.get("comments", []))
    
    def migrate_all_issues(self) -> None:
        """Migrate all GitHub issues to the project"""
        # Get all GitHub issues
        issues = self.get_all_github_issues()
        if not issues:
            print("No GitHub issues found or error occurred.")
            return
        
        print(f"Found {len(issues)} issues in GitHub repository.")
        
        # Process each issue
        for issue in issues:
            self.process_issue(issue)
            print("")  # Add a blank line for readability
        
        print("🏁 Finished comprehensive migration of all issues!")
        print("All issues should now be in the project with correct types and parent relationships.")


if __name__ == "__main__":
    migrator = GithubMigrator()
    migrator.migrate_all_issues()
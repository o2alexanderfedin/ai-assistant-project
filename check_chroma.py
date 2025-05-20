#!/usr/bin/env python3
import requests
import json

def check_chroma_connection():
    """Test connection to Chroma database."""
    url = "http://localhost:8100/api/v2"
    
    try:
        response = requests.get(url, timeout=5)
        print(f"✅ Connected to Chroma API v2")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:200]}...")
        return True
    except requests.RequestException as e:
        print(f"❌ Failed to connect to Chroma API")
        print(f"Error: {e}")
        return False

def test_list_collections():
    """Test listing collections in Chroma."""
    url = "http://localhost:8100/api/v2/collections"
    
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            collections = data.get("results", [])
            print(f"✅ Successfully listed collections")
            print(f"Found {len(collections)} collections")
            for coll in collections:
                print(f"  - {coll.get('name')}")
        else:
            print(f"❌ Failed to list collections, status code: {response.status_code}")
            print(f"Response: {response.text}")
        return response.status_code == 200
    except requests.RequestException as e:
        print(f"❌ Failed to list collections")
        print(f"Error: {e}")
        return False

def create_test_collection():
    """Create a test collection in Chroma."""
    url = "http://localhost:8100/api/v2/collections"
    test_collection = {
        "name": "test_docker_collection"
    }
    
    try:
        response = requests.post(url, json=test_collection, timeout=5)
        if response.status_code in [200, 201]:
            print(f"✅ Successfully created test collection")
            print(f"Response: {response.text[:200]}...")
        else:
            print(f"❌ Failed to create test collection, status code: {response.status_code}")
            print(f"Response: {response.text}")
        return response.status_code in [200, 201]
    except requests.RequestException as e:
        print(f"❌ Failed to create test collection")
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Chroma Database Connection...")
    if check_chroma_connection():
        test_list_collections()
        create_test_collection()
    else:
        print("Skipping collection tests due to connection failure")
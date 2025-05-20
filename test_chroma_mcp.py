import json
import requests

def test_chroma():
    """Test that Chroma API is accessible"""
    try:
        response = requests.get("http://localhost:8100/api/v2")
        if response.status_code == 200:
            print("✅ Chroma Vector DB is running successfully!")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Error: Chroma API returned status code {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error connecting to Chroma: {str(e)}")

def test_chroma_mcp():
    """Test that Chroma MCP server is accessible"""
    endpoints = [
        "http://localhost:8080/health",
        "http://localhost:8080/",
        "http://localhost:8080/api/v1/health",
        "http://localhost:8080/v1/health",
        "http://localhost:8080/mcp",
        "http://localhost:8080/sse"
    ]
    
    for endpoint in endpoints:
        try:
            print(f"Trying endpoint: {endpoint}")
            response = requests.get(endpoint, timeout=5)
            if response.status_code == 200:
                print(f"✅ Chroma MCP server is running successfully at {endpoint}!")
                print(f"Response: {response.text[:500]}...")  # Limit response length
                return
            else:
                print(f"❌ Error: Chroma MCP server returned status code {response.status_code} for {endpoint}")
                print(f"Response: {response.text[:500]}...")  # Limit response length
        except Exception as e:
            print(f"❌ Error connecting to Chroma MCP server at {endpoint}: {str(e)}")
    
    print("❌ Failed to connect to Chroma MCP server on any of the attempted endpoints")

def test_mcp_endpoints():
    """Test MCP-specific endpoints"""
    endpoints = [
        "http://localhost:8080/mcp",  # Streamable HTTP endpoint
        "http://localhost:8080/sse"    # Server-Sent Events endpoint
    ]
    
    for endpoint in endpoints:
        try:
            print(f"Testing MCP endpoint: {endpoint}")
            # Send HTTP OPTIONS request which should work for MCP endpoints
            response = requests.options(endpoint, timeout=5)
            print(f"Status: {response.status_code}")
            print(f"Headers: {dict(response.headers)}")
            if response.status_code == 200:
                print(f"✅ MCP endpoint {endpoint} is accessible!")
            else:
                print(f"❌ MCP endpoint {endpoint} returned status {response.status_code}")
        except Exception as e:
            print(f"❌ Error accessing MCP endpoint {endpoint}: {str(e)}")

if __name__ == "__main__":
    print("Testing Chroma and Chroma MCP servers...\n")
    test_chroma()
    print("\n" + "-"*50 + "\n")
    print("Testing standard HTTP endpoints:")
    test_chroma_mcp()
    print("\n" + "-"*50 + "\n")
    print("Testing MCP protocol endpoints:")
    test_mcp_endpoints()
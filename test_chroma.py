import requests

# Test that Chroma API is accessible (v2)
response = requests.get("http://localhost:8100/api/v2")
if response.status_code == 200:
    print("✅ Chroma is running successfully!")
    print(f"Response: {response.json()}")
else:
    print(f"❌ Error: Chroma API returned status code {response.status_code}")
    print(f"Response: {response.text}")
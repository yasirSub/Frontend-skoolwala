#!/usr/bin/env python3
"""
Postman Collection Auto-Update Script
Scans backend routes.php and Api.php controller to automatically update Postman collection
"""

import json
import re
import os
from pathlib import Path

# Paths
BACKEND_ROOT = Path("D:/git/skoolwala/backend/backend- skoolwala")
ROUTES_FILE = BACKEND_ROOT / "application/config/routes.php"
API_CONTROLLER = BACKEND_ROOT / "application/controllers/Api.php"
POSTMAN_COLLECTION = Path(__file__).parent / "SkoolWala_Complete_API_Collection.postman_collection.json"
BASE_URL = "http://192.168.31.129:8080"

def extract_api_routes(routes_file):
    """Extract all API routes from routes.php"""
    api_routes = []
    
    if not routes_file.exists():
        print(f"Warning: Routes file not found: {routes_file}")
        return api_routes
    
    with open(routes_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Match: $route['api/...'] = 'controller/method';
    pattern = r"\$route\['api/([^']+)'\]\s*=\s*'([^']+)'"
    matches = re.findall(pattern, content)
    
    for route_path, controller_method in matches:
        api_routes.append({
            'path': route_path,
            'controller': controller_method.split('/')[0],
            'method': controller_method.split('/')[1] if '/' in controller_method else controller_method
        })
    
    return api_routes

def extract_api_methods(api_controller):
    """Extract public API methods from Api.php"""
    api_methods = []
    
    if not api_controller.exists():
        print(f"Warning: API controller not found: {api_controller}")
        return api_methods
    
    with open(api_controller, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Match: public function methodName()
    pattern = r"public\s+function\s+(\w+)\s*\("
    matches = re.findall(pattern, content)
    
    # Filter out constructor and common methods
    exclude = ['__construct', 'index']
    api_methods = [m for m in matches if m not in exclude]
    
    return api_methods

def load_postman_collection():
    """Load existing Postman collection"""
    if not POSTMAN_COLLECTION.exists():
        print(f"Warning: Postman collection not found: {POSTMAN_COLLECTION}")
        return None
    
    with open(POSTMAN_COLLECTION, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_existing_endpoints(collection):
    """Get list of existing API endpoints from collection"""
    endpoints = []
    
    def extract_from_item(item):
        if 'request' in item and 'url' in item['request']:
            url = item['request']['url']
            if isinstance(url, dict) and 'path' in url:
                path = '/'.join(url['path'])
                if path.startswith('api/'):
                    endpoints.append(path)
        
        if 'item' in item:
            for sub_item in item['item']:
                extract_from_item(sub_item)
    
    if 'item' in collection:
        for item in collection['item']:
            extract_from_item(item)
    
    return endpoints

def create_api_request(route_path, method='POST'):
    """Create a Postman request object for an API endpoint"""
    # Determine HTTP method based on route name
    if any(keyword in route_path.lower() for keyword in ['get', 'list', 'check']):
        method = 'GET'
    elif any(keyword in route_path.lower() for keyword in ['delete', 'remove']):
        method = 'DELETE'
    elif any(keyword in route_path.lower() for keyword in ['update', 'edit', 'set']):
        method = 'PUT'
    
    # Parse path segments
    path_segments = route_path.split('/')
    
    # Create request body template
    body_template = {}
    if 'staff_id' in route_path or 'teacher_id' in route_path:
        body_template['staff_id'] = '{{staffId}}'
    if 'username' in route_path or 'login' in route_path:
        body_template['username'] = 'teacher1'
        body_template['password'] = 'password123'
    
    request = {
        "method": method,
        "header": [
            {
                "key": "Content-Type",
                "value": "application/json"
            }
        ],
        "body": {
            "mode": "raw",
            "raw": json.dumps(body_template, indent=2) if body_template else "{}"
        },
        "url": {
            "raw": f"{{{{baseUrl}}}}/api/{route_path}",
            "host": ["{{baseUrl}}"],
            "path": ["api"] + path_segments
        },
        "description": f"API endpoint: {route_path}"
    }
    
    return request

def update_postman_collection():
    """Main function to update Postman collection"""
    print("🔄 Starting Postman Collection Update...")
    
    # Extract routes and methods
    print("📋 Extracting API routes from routes.php...")
    api_routes = extract_api_routes(ROUTES_FILE)
    print(f"   Found {len(api_routes)} API routes")
    
    print("📋 Extracting API methods from Api.php...")
    api_methods = extract_api_methods(API_CONTROLLER)
    print(f"   Found {len(api_methods)} API methods")
    
    # Load existing collection
    print("📦 Loading existing Postman collection...")
    collection = load_postman_collection()
    if not collection:
        print("❌ Cannot proceed without existing collection")
        return
    
    # Get existing endpoints
    existing_endpoints = get_existing_endpoints(collection)
    print(f"   Found {len(existing_endpoints)} existing endpoints in collection")
    
    # Find missing endpoints
    route_paths = {route['path'] for route in api_routes}
    missing_routes = route_paths - set(existing_endpoints)
    
    if missing_routes:
        print(f"\n✨ Found {len(missing_routes)} new API routes to add:")
        for route in sorted(missing_routes):
            print(f"   - api/{route}")
        
        # Add to Testing & Development folder
        print("\n➕ Adding missing routes to collection...")
        for item in collection['item']:
            if item['name'] == 'Testing & Development':
                for route_path in sorted(missing_routes):
                    new_request = {
                        "name": route_path.replace('/', ' ').title(),
                        "request": create_api_request(route_path),
                        "response": []
                    }
                    item['item'].append(new_request)
                break
        
        # Save updated collection
        print("💾 Saving updated collection...")
        with open(POSTMAN_COLLECTION, 'w', encoding='utf-8') as f:
            json.dump(collection, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Successfully added {len(missing_routes)} new endpoints!")
    else:
        print("\n✅ All API routes are already in the collection!")
    
    print("\n📊 Summary:")
    print(f"   Total routes in backend: {len(route_paths)}")
    print(f"   Total endpoints in collection: {len(existing_endpoints)}")
    print(f"   Missing endpoints: {len(missing_routes)}")

if __name__ == "__main__":
    update_postman_collection()


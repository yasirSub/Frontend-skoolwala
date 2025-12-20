# SkoolWala Postman API Collection

Complete collection of all SkoolWala APIs for backend and frontend testing.

## 📋 Collection Overview

- **Total APIs**: 100+ endpoints
- **Base URL**: `http://192.168.31.129:8080`
- **Last Updated**: Auto-synced with backend

## 🚀 Quick Start

1. **Import Collection**:
   - Open Postman
   - Click **Import**
   - Select `SkoolWala_Complete_API_Collection.postman_collection.json`

2. **Set Variables**:
   - `baseUrl`: `http://192.168.31.129:8080` (pre-configured)
   - `authToken`: Set after login
   - `teacherId`: Set after teacher login
   - `staffId`: Set after login

3. **Test APIs**:
   - Start with **Authentication → Teacher Login**
   - Use returned credentials for other requests

## 🔄 Auto-Update Collection

### Option 1: Manual Update Script

Run the Python script to automatically sync new APIs:

```bash
cd postman
python update_postman_collection.py
```

This script will:
- ✅ Scan `routes.php` for all API routes
- ✅ Scan `Api.php` controller for methods
- ✅ Compare with existing collection
- ✅ Add any missing endpoints automatically

### Option 2: Manual Update Process

When you add a new API:

1. **Add route in `routes.php`**:
   ```php
   $route['api/yourNewEndpoint'] = 'controller/method';
   ```

2. **Update Postman Collection**:
   - Open `SkoolWala_Complete_API_Collection.postman_collection.json`
   - Add new request to appropriate folder
   - Follow existing format

3. **Or run the update script**:
   ```bash
   python update_postman_collection.py
   ```

## 📁 Collection Structure

- **Authentication** - Login, Logout
- **Navigation & Menu** - Side menu API
- **Teacher Profile** - Profile management
- **Attendance** - All attendance APIs
- **Face Recognition** - Face enrollment, verification
- **F2F Face Recognition** - Alternative face recognition
- **Location Management** - School location APIs
- **School Management** - School, roles, classes, students
- **Teacher Schedule** - Schedule and timetable
- **Analytics** - Location analytics
- **Testing & Development** - Test endpoints

## 🔑 Important APIs

### Side Menu API (`getUserMenu`)

**Endpoint**: `POST /api/getUserMenu`

**How it works**:
- ✅ Automatically detects user role from login credentials
- ✅ Filters menu items based on role permissions
- ✅ Returns same menu structure as web version

**Authentication Options**:
1. **Stateless** (recommended for mobile):
   ```json
   {
     "username": "teacher1",
     "password": "password123"
   }
   ```

2. **Session-based** (if already logged in):
   - No body needed, uses session cookies

**Response includes**:
- Menu items filtered by role (Admin, Teacher, Accountant, etc.)
- Permission-based filtering
- Hierarchical structure with children
- Icons, routes, and permissions

**Role Detection**:
- The API automatically gets `role_id` from:
  - Session (if logged in)
  - Login credentials (username/password)
- Uses `loggedin_role_id()` and `get_permission()` to filter menu items
- Returns menu matching web version's sidebar

## 📝 Notes

- All APIs use base URL variable: `{{baseUrl}}`
- Most POST requests require JSON body
- Authentication tokens stored in collection variables
- Collection is organized by feature/functionality

## 🐛 Troubleshooting

### Side Menu Not Showing Correct Items?

1. **Check Authentication**:
   - Ensure username/password are correct
   - Or ensure session is active

2. **Verify Role**:
   - Check response includes `debug.role_id`
   - Ensure role matches expected permissions

3. **Check Permissions**:
   - Response includes `debug` object with permission checks
   - Verify permissions match web version

### Missing APIs?

Run the update script:
```bash
python update_postman_collection.py
```

## 📞 Support

For API issues, check:
- Backend routes: `backend/application/config/routes.php`
- API Controller: `backend/application/controllers/Api.php`


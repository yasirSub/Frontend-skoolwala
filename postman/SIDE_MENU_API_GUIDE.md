# Side Menu API (getUserMenu) - Role & Permission Guide

## 🔍 How Role Detection Works

The `getUserMenu` API **automatically detects user role** from authentication. Here's how:

### Authentication Flow

1. **Stateless Authentication** (with username/password):
   ```json
   POST /api/getUserMenu
   {
     "username": "teacher1",
     "password": "password123"
   }
   ```
   - API authenticates user
   - Gets `role_id` from login_credential table
   - Sets session data: `loggedin_role_id`, `loggedin_user_id`, `loggedin_branch`
   - Uses these to filter menu items

2. **Session-Based Authentication**:
   - If already logged in, uses existing session
   - Gets `role_id` from `loggedin_role_id()` helper
   - No need to send credentials

### Role-Based Menu Filtering

The API filters menu items based on:

1. **Role ID**:
   - Admin: 1, 2
   - Teacher: 3
   - Accountant: 4
   - Librarian: 5
   - Parent: 6
   - Student: 7

2. **Permissions** (via `get_permission()`):
   - Checks role permissions from database
   - Example: `get_permission('student', 'is_view')`
   - Example: `get_permission('attendance', 'is_add')`

3. **Branch Access**:
   - Filters by `branch_id` if multi-branch system

### Response Structure

```json
{
  "status": "success",
  "data": [
    {
      "id": "dashboard",
      "title": "Dashboard",
      "icon": "dashboard",
      "route": "/dashboard",
      "type": "item"
    },
    {
      "id": "student_info",
      "title": "Student Information",
      "icon": "people",
      "type": "parent",
      "children": [
        {
          "id": "student_list",
          "title": "Student List",
          "icon": "list",
          "route": "/student/list",
          "type": "item"
        }
      ]
    }
  ],
  "message": "Menu items retrieved successfully",
  "debug": {
    "role_id": 3,
    "branch_id": 1,
    "student_view": true,
    "student_add": false,
    "attendance_view": true,
    "attendance_for_teacher": true
  }
}
```

## ✅ Verification Checklist

If menu items don't match web version, check:

1. **Role Detection**:
   - Check `debug.role_id` in response
   - Should match user's actual role

2. **Permissions**:
   - Check `debug` object for permission values
   - Compare with web version's permissions

3. **Authentication**:
   - Ensure username/password are correct
   - Or session is active and valid

4. **Branch Access**:
   - Check `debug.branch_id`
   - Ensure user has access to correct branch

## 🔧 Troubleshooting

### Issue: Menu shows wrong items

**Solution**: Check the `debug` object in response:
```json
"debug": {
  "role_id": 3,  // Should be correct role
  "branch_id": 1,
  "student_view": true,  // Check permissions
  ...
}
```

### Issue: Menu missing items that web version shows

**Possible Causes**:
1. Role permissions not set correctly in database
2. Branch access issue
3. Permission check failing

**Solution**: 
- Verify role permissions in admin panel
- Check `role_permission` table in database
- Compare `debug` output with web version

### Issue: API returns empty menu

**Possible Causes**:
1. User not authenticated
2. Role not recognized
3. No permissions set for role

**Solution**:
- Check authentication response
- Verify role exists in `login_credential` table
- Ensure role has at least basic permissions

## 📝 Testing in Postman

1. **Test with Teacher Role**:
   ```json
   {
     "username": "teacher_username",
     "password": "teacher_password"
   }
   ```
   Expected: Menu items for Teacher role (Dashboard, Students, Attendance, etc.)

2. **Test with Admin Role**:
   ```json
   {
     "username": "admin_username",
     "password": "admin_password"
   }
   ```
   Expected: Full menu with all admin options

3. **Check Response Debug**:
   - Look at `debug.role_id` - should match user's role
   - Check permission values match expected access

## 🎯 Key Points

✅ **Role is automatically detected** - No need to pass `role_id` manually
✅ **Permissions are checked** - Uses `get_permission()` helper
✅ **Matches web version** - Same logic as web sidebar
✅ **Debug info included** - Response includes role and permission checks

The API is working correctly - it automatically gets role from authentication and filters menu accordingly!


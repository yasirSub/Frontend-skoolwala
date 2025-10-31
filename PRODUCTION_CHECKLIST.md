# 🚀 Production Deployment Checklist

## 📋 Things to Change Before Going Live

### 1. **Change Environment in `api_config.dart`** ✅ CRITICAL
**File:** `lib/shared/config/api_config.dart`
**Line:** 17

```dart
// CHANGE THIS:
static const String environment = 'development';

// TO THIS:
static const String environment = 'production';
```

---

### 2. **Update API URLs in `api_config.dart`** ✅ CRITICAL
**File:** `lib/shared/config/api_config.dart`
**Line:** 27-28

```dart
// UPDATE YOUR PRODUCTION URL:
static const String productionBaseUrl = 'https://school.firmbeginners.com/api';

// Make sure this is correct for your production server!
```

---

### 3. **Update `main.dart`** ✅ CRITICAL
**File:** `lib/main.dart`
**Line:** 47

```dart
// REMOVE THIS LINE:
ApiService.setOverrideBaseUrl('http://192.168.31.129:8080/api');

// REPLACE WITH:
ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);

// OR use the dynamic method:
ApiService.setOverrideBaseUrl(ApiConfig.getBaseUrl()); // Automatically picks based on environment
```

**Also uncomment the import:**
```dart
// Line 5:
import 'shared/config/api_config.dart';  // Remove the // comment
```

---

### 4. **Update `simple_teacher_attendance.dart`** ✅ CRITICAL
**File:** `lib/features/teacher_attendance/simple_teacher_attendance.dart`
**Line:** 54

```dart
// CHANGE THIS:
final String baseUrl = 'http://192.168.31.129:8080';

// TO THIS:
final String baseUrl = 'https://school.firmbeginners.com';
// (Remove the /api part if it's added in the endpoint)
```

---

### 5. **Disable Debug Logging** ✅ RECOMMENDED
**File:** `lib/shared/config/api_config.dart`
**Line:** 20

```dart
// CHANGE THIS:
static const bool enableDebugLogging = true;

// TO THIS:
static const bool enableDebugLogging = false;
```

---

### 6. **Remove `debugShowCheckedModeBanner`** ✅ ALREADY DONE
**File:** `lib/main.dart`
**Line:** 66

```dart
debugShowCheckedModeBanner: false,  // ✅ Already disabled
```

---

### 7. **Build Configuration**

#### For Android:
- Check `android/app/build.gradle`
- Ensure `minSdkVersion` is appropriate
- Verify `versionCode` and `versionName`
- Ensure `signingConfig` is set for release builds

#### For iOS:
- Check `ios/Runner/Info.plist`
- Ensure `CFBundleVersion` is updated
- Configure signing certificates
- Update deployment target if needed

---

## 🔍 Summary of Changes Needed

### ✅ **MUST CHANGE (Critical):**
1. `api_config.dart` - Line 17: `environment = 'production'`
2. `api_config.dart` - Line 27-28: Update production URL
3. `main.dart` - Line 47: Use production URL
4. `simple_teacher_attendance.dart` - Line 54: Use production URL

### ⚠️ **SHOULD CHANGE (Recommended):**
1. `api_config.dart` - Line 20: Disable debug logging
2. Verify all hardcoded URLs are updated

### 📦 **ALREADY DONE:**
1. ✅ Debug banner is hidden
2. ✅ API configuration file created
3. ✅ All endpoints centralized

---

## 🎯 Quick Steps to Go Live

1. **Open** `lib/shared/config/api_config.dart`
2. **Change** `environment` to `'production'`
3. **Update** `productionBaseUrl` with your server URL
4. **Open** `lib/main.dart`
5. **Change** line 47 to: `ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);`
6. **Open** `lib/features/teacher_attendance/simple_teacher_attendance.dart`
7. **Change** line 54 to your production URL
8. **Build** the app for release

---

## 🛡️ Security Notes

- ✅ All API calls should use HTTPS in production
- ✅ Never hardcode sensitive data
- ✅ Use environment variables for sensitive configs
- ✅ Test all endpoints before deploying

---

## 📝 Testing Checklist

After making changes, test:
- [ ] Login flow
- [ ] Face enrollment
- [ ] Face verification
- [ ] Attendance marking
- [ ] Location detection
- [ ] API connectivity

---

## 🔄 Rollback Plan

If something goes wrong:
1. Revert `environment` back to `'development'`
2. Revert `baseUrl` to development server
3. Rebuild and redeploy

---

## 🚨 **IMPORTANT: Face Verification Not Working?**

If face verification/check-in is not working on production, you need to **upload the backend files**:

### **Files to Upload to Production Server:**

1. **Upload this controller:**
   - `application/controllers/FaceApi.php`

2. **Make sure these database tables exist on production:**
   - `staff_face` table
   - `staff_face_3d` table (optional)

3. **Check backend routing:**
   - The endpoint `api/face/identify` must be accessible
   - Test with: `https://school.firmbeginners.com/api/face/identify`

### **Quick Test Command:**

```bash
# Test if face endpoint exists (run this on your computer):
curl -X POST https://school.firmbeginners.com/api/face/identify -H "Content-Type: application/json"
```

**Expected response:** Should return an authentication error (401), not a 404 error.

- ✅ **401 Error** = Endpoint exists but needs authentication  
- ❌ **404 Error** = Endpoint NOT FOUND (backend file missing)


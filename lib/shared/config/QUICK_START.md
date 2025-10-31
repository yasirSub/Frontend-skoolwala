# 🚀 Quick Start - Using the API Config

## ✅ What's Already in the File

**All Base URLs are already added:**
- ✅ `productionBaseUrl` - Production server
- ✅ `developmentBaseUrl` - Your current server (192.168.31.129:8080)
- ✅ `localhostBaseUrl` - Local development
- ✅ `androidEmulatorUrl` - For Android emulator
- ✅ `iosSimulatorUrl` - For iOS simulator

**All API endpoints are already listed:**
- ✅ Authentication endpoints (login, logout, profile)
- ✅ School endpoints (info, classes, students)
- ✅ Attendance endpoints
- ✅ Face recognition endpoints
- ✅ Dashboard endpoints

## 🎯 How to Use It

### 1. Change Your Base URL (in one place!)

**Option A: In main.dart (recommended)**
```dart
import 'shared/config/api_config.dart';

void main() {
  // Use development server
  ApiService.setOverrideBaseUrl(ApiConfig.developmentBaseUrl);
  
  // OR use production
  // ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);
  
  // OR use localhost
  // ApiService.setOverrideBaseUrl(ApiConfig.localhostBaseUrl);
  
  runApp(const MainApp());
}
```

**Option B: Change the IP in api_config.dart**
```dart
// Line 31 in api_config.dart
static const String developmentBaseUrl = 'http://YOUR_NEW_IP:8080/api';
```

### 2. Use Endpoints in Your Code

```dart
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/api_service.dart';

// Make API calls using the constants
final response = await ApiService.post(
  ApiConfig.teacherLogin,  // ← Just use the constant!
  body: {
    'username': 'teacher@example.com',
    'password': 'password123',
  },
);
```

### 3. See All Available Endpoints

```dart
// Print all endpoints
ConfigHelper.printConfig();

// Get all endpoints as a map
final endpoints = ConfigHelper.getAllEndpoints();
endpoints.forEach((name, url) {
  print('$name: $url');
});
```

## 📍 Where Everything Is

| What | Where |
|------|-------|
| **Base URLs** | Lines 27-40 in `api_config.dart` |
| **Auth endpoints** | Lines 58-60 |
| **School endpoints** | Lines 65-69 |
| **Attendance endpoints** | Lines 74-78 |
| **Face endpoints** | Lines 83-88 |
| **Dashboard endpoints** | Lines 93-96 |

## 🔄 Switch Between Environments

**Currently:**
- Line 17: `static const String environment = 'development';`
- Line 31: Base URL is set to `http://192.168.31.129:8080/api`

**To switch to production:**
```dart
// In api_config.dart, line 17
static const String environment = 'production';
```

**Or use it directly in main.dart:**
```dart
ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);
```

## 💡 Examples

### Example 1: Login
```dart
final response = await ApiService.post(
  ApiConfig.teacherLogin,
  body: {'username': username, 'password': password},
);
```

### Example 2: Get School Info
```dart
final response = await ApiService.post(
  ApiConfig.getSchoolInfo,
  body: {'action': 'mark', 'status': 'P'},
  requireAuth: true,
);
```

### Example 3: Get Class List
```dart
final response = await ApiService.post(
  ApiConfig.getClassList,
  body: {'action': 'mark', 'status': 'P'},
  requireAuth: true,
);
```

## 🎉 Summary

**Yes, you can now handle ALL API calls from this file!**

1. ✅ All base URLs are there
2. ✅ All endpoints are there
3. ✅ Just update ONE place (line 31) to change your server IP
4. ✅ Use `ApiConfig.ENDPOINT_NAME` in your code
5. ✅ Switch environments easily

**No need to search through multiple files anymore! Everything is in:**
```
lib/shared/config/api_config.dart
```


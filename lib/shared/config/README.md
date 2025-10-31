# API Configuration

This directory contains centralized configuration for all API endpoints and settings.

## 📁 Files

- `api_config.dart` - Main configuration file with all endpoints and settings

## 🚀 How to Use

### 1. Set Your Environment

Open `lib/main.dart` and update the environment configuration:

```dart
import 'package:skoolwala/shared/config/api_config.dart';

void main() {
  // Use production API
  ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);
  
  // Or use development API
  ApiService.setOverrideBaseUrl(ApiConfig.developmentBaseUrl);
  
  // Or use a custom URL
  ApiService.setOverrideBaseUrl('http://your-custom-url.com/api');
  
  runApp(const MainApp());
}
```

### 2. Use API Endpoints in Your Code

#### Option A: Use Constants Directly
```dart
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/api_service.dart';

// Make an API call
final response = await ApiService.post(
  ApiConfig.teacherLogin,
  body: {'username': 'user', 'password': 'pass'},
);
```

#### Option B: Use Pre-defined Endpoints
```dart
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/api_service.dart';

// Use typed endpoints
final response = await ApiService.post(
  ApiEndpoints.login.toString(),
  body: {'username': 'user', 'password': 'pass'},
);
```

### 3. Switch Between Environments

#### Development Mode
```dart
// In main.dart
ApiService.setOverrideBaseUrl(ApiConfig.developmentBaseUrl);
```

#### Production Mode
```dart
// In main.dart
ApiService.setOverrideBaseUrl(ApiConfig.productionBaseUrl);
```

#### Custom URL
```dart
// In main.dart
ApiService.setOverrideBaseUrl('http://192.168.1.100:8080/api');
```

## 📝 Adding New Endpoints

To add a new API endpoint:

1. Open `api_config.dart`
2. Add the endpoint to the appropriate section:

```dart
// In the ATTENDANCE ENDPOINTS section
static const String markAttendance = 'markAttendance';
static const String yourNewEndpoint = 'yourNewEndpoint'; // Add here
```

3. Add it to the pre-defined endpoints if needed:

```dart
class ApiEndpoints {
  static const Attendance markAttendance = Attendance('markAttendance');
  static const Attendance yourEndpoint = Attendance('yourNewEndpoint');
}
```

## 🔧 Configuration Options

### Available Base URLs

- `ApiConfig.productionBaseUrl` - Production server
- `ApiConfig.developmentBaseUrl` - Development server
- `ApiConfig.localhostBaseUrl` - Local development
- `ApiConfig.androidEmulatorUrl` - Android emulator
- `ApiConfig.iosSimulatorUrl` - iOS simulator

### Current Configuration

```dart
// Check current environment
print('Environment: ${ApiConfig.environment}');
print('Base URL: ${ApiConfig.getBaseUrl()}');

// Print all endpoints
ConfigHelper.printConfig();
```

## 📊 Available Endpoints

### Authentication
- `teacherLogin` - Login teacher
- `teacherLogout` - Logout teacher
- `teacherProfile` - Get teacher profile

### School
- `getSchoolInfo` - Get school information
- `getClassList` - Get list of classes
- `getSectionListByClass` - Get sections for a class
- `getStudentList` - Get list of students

### Attendance
- `markAttendance` - Mark attendance
- `getAttendanceHistory` - Get attendance history
- `getAttendanceStatus` - Get attendance status

### Face Recognition
- `enrollFace` - Enroll a face
- `verifyFace` - Verify face
- `getEnrolledFaces` - Get enrolled faces

### Dashboard
- `getDashboardData` - Get dashboard data
- `getTeacherStatistics` - Get teacher statistics

## 🐛 Debugging

Enable debug logging in `api_config.dart`:

```dart
static const bool enableDebugLogging = true;
```

This will print all API calls and responses to the console.

## ⚙️ Example Usage

```dart
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/api_service.dart';

// Example: Login
Future<void> login(String username, String password) async {
  try {
    final response = await ApiService.post(
      ApiConfig.teacherLogin,
      body: {
        'username': username,
        'password': password,
      },
    );
    
    print('Login successful: $response');
  } catch (e) {
    print('Login failed: $e');
  }
}

// Example: Get School Info
Future<Map<String, dynamic>> getSchoolInfo() async {
  final response = await ApiService.post(
    ApiConfig.getSchoolInfo,
    body: {'action': 'mark', 'status': 'P'},
    requireAuth: true,
  );
  
  return response;
}

// Example: Print current configuration
void showConfig() {
  ConfigHelper.printConfig();
  
  // Get all endpoints
  final endpoints = ConfigHelper.getAllEndpoints();
  endpoints.forEach((key, value) {
    print('$key: $value');
  });
}
```

## 💡 Tips

1. **Always use constants from ApiConfig** - Don't hardcode endpoint URLs
2. **Check the environment** - Use `Environment.isDevelopment()` to conditionally run code
3. **Use typed endpoints** - Use `ApiEndpoints` classes for better IDE autocomplete
4. **Enable debug logging** - Turn on `enableDebugLogging` during development

## 📞 Need Help?

If you need to:
- Change the base URL → Update `lib/main.dart`
- Add a new endpoint → Add to appropriate section in `api_config.dart`
- Debug API calls → Enable `enableDebugLogging`


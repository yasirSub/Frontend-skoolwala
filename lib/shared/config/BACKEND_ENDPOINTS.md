# 📋 Complete Backend API Endpoints List

This document contains all the API endpoints from your backend that are now available in `api_config.dart`.

## 🌐 Base URLs

```dart
// Current development server
ApiConfig.developmentBaseUrl = 'http://192.168.31.129:8080/api'

// Production server  
ApiConfig.productionBaseUrl = 'https://school.firmbeginners.com/api'

// Other options
ApiConfig.localhostBaseUrl = 'http://localhost/skoolwala/api'
ApiConfig.androidEmulatorUrl = 'http://10.0.2.2:8080/api'
ApiConfig.iosSimulatorUrl = 'http://127.0.0.1:8080/api'
```

---

## 🔐 Authentication Endpoints (6 endpoints)

| Endpoint | Constant | Usage |
|----------|----------|-------|
| `api/auth/login` | `ApiConfig.authLogin` | Generic login |
| `api/teacherLogin` | `ApiConfig.teacherLogin` | Teacher login |
| `api/teacherProfile` | `ApiConfig.teacherProfile` | Get teacher profile |
| `api/updateTeacherProfile` | `ApiConfig.updateTeacherProfile` | Update teacher profile |
| `api/getStaffList` | `ApiConfig.getStaffList` | Get staff list |

---

## 🏫 School Endpoints (5 endpoints)

| Endpoint | Constant | Usage |
|----------|----------|-------|
| `api/getSchoolInfo` | `ApiConfig.getSchoolInfo` | Get school information |
| `api/getSchoolLocation` | `ApiConfig.getSchoolLocation` | Get school location |
| `api/getClassList` | `ApiConfig.getClassList` | Get class list |
| `api/getSectionListByClass` | `ApiConfig.getSectionListByClass` | Get sections by class |
| `api/getStudentList` | `ApiConfig.getStudentList` | Get student list |

---

## ✅ Attendance Endpoints (9 endpoints)

| Endpoint | Constant | Usage |
|----------|----------|-------|
| `api/quickAttendance` | `ApiConfig.quickAttendance` | Quick attendance with face |
| `api/attendance/mark` | `ApiConfig.markAttendance` | Mark attendance |
| `api/attendance/today/{id}` | `ApiConfig.todayAttendance` | Get today's attendance |
| `api/teacherAttendance` | `ApiConfig.teacherAttendance` | Teacher attendance |
| `api/teacherSelfAttendance` | `ApiConfig.teacherSelfAttendance` | Self attendance |
| `api/attendanceForTeacher` | `ApiConfig.attendanceForTeacher` | Attendance for teacher |
| `api/getTeacherSelfAttendanceStats` | `ApiConfig.getTeacherSelfAttendanceStats` | Attendance stats |
| `api/teacherPresentDaysCount` | `ApiConfig.teacherPresentDaysCount` | Present days count |
| `api/teacherAbsentDaysCount` | `ApiConfig.teacherAbsentDaysCount` | Absent days count |
| `api/deleteAttendance` | `ApiConfig.deleteAttendance` | Delete attendance |

---

## 👤 Face Recognition Endpoints (16 endpoints)

### Enrollment
- `api/enrollFace` → `ApiConfig.enrollFace`
- `api/enrollFaceImage` → `ApiConfig.enrollFaceImage`  
- `api/face/enroll3D` → `ApiConfig.enrollFace3D`

### Verification
- `api/verifyFace` → `ApiConfig.verifyFace`
- `api/verifyFaceImage` → `ApiConfig.verifyFaceImage`
- `api/face/identify` → `ApiConfig.identifyFace`
- `api/face/identify3D` → `ApiConfig.identifyFace3D`

### Management
- `api/listEnrolledFaces` → `ApiConfig.listEnrolledFaces`
- `api/face/list3D` → `ApiConfig.list3DFaces`
- `api/face/delete/{id}` → `ApiConfig.deleteFaceEnrollment`
- `api/face/enrollment/check/{id}` → `ApiConfig.checkFaceEnrollment`
- `api/checkFaceDuplicate` → `ApiConfig.checkFaceDuplicate`

### Analysis
- `api/face/analyze` → `ApiConfig.faceAnalyze`
- `api/face/testAnalyzer` → `ApiConfig.faceTestAnalyzer`
- `api/debugFaceRecognition` → `ApiConfig.debugFaceRecognition`
- `api/face/check-duplicate` → `ApiConfig.checkFaceDuplicateAPI`

---

## 🤝 Face-to-Face (F2F) Endpoints (11 endpoints)

- `api/f2f/test` → `ApiConfig.f2fTest`
- `api/f2f/testController` → `ApiConfig.f2fTestController`
- `api/f2f/testDelete` → `ApiConfig.f2fTestDelete`
- `api/f2f/register` → `ApiConfig.f2fRegister`
- `api/f2f/analyze` → `ApiConfig.f2fAnalyze`
- `api/f2f/list` → `ApiConfig.f2fList`
- `api/f2f/checkFace` → `ApiConfig.f2fCheckFace`
- `api/f2f/delete` → `ApiConfig.f2fDelete`
- `api/f2f/deleteAll` → `ApiConfig.f2fDeleteAll`
- `api/f2f/create` → `ApiConfig.f2fCreate`
- `api/f2f/attach` → `ApiConfig.f2fAttach`
- `api/f2f/attachImage` → `ApiConfig.f2fAttachImage`

---

## 📍 Location Endpoints (6 endpoints)

| Endpoint | Constant | Usage |
|----------|----------|-------|
| `api/school-location/set` | `ApiConfig.schoolLocationSet` | Set school location |
| `api/school-location/list` | `ApiConfig.schoolLocationList` | List locations |
| `api/school-location/check` | `ApiConfig.schoolLocationCheck` | Check location |
| `api/school-location/delete/{id}` | `ApiConfig.schoolLocationDelete` | Delete location |
| `api/locationAnalytics` | `ApiConfig.locationAnalytics` | Get analytics |
| `api/exportLocationAnalytics` | `ApiConfig.exportLocationAnalytics` | Export analytics |

---

## 📊 Statistics & Analytics Endpoints (3 endpoints)

- `api/getTeacherStatistics` → `ApiConfig.getTeacherStatistics`
- `api/getDashboardData` → `ApiConfig.getDashboardData`
- `api/getStudentStatistics` → `ApiConfig.getStudentStatistics`

---

## 🧪 Test & Debug Endpoints (9 endpoints)

- `api/test` → `ApiConfig.apiTest`
- `api/testDatabase` → `ApiConfig.testDatabase`
- `api/testCodeVersion` → `ApiConfig.testCodeVersion`
- `api/fixDatabaseSchema` → `ApiConfig.fixDatabaseSchema`
- `api/attendanceForTeacherTest` → `ApiConfig.attendanceForTeacherTest`
- `api/generateDummyData` → `ApiConfig.generateDummyData`
- `api/generateDummyDataAlt` → `ApiConfig.generateDummyDataAlt`
- `api/testGenerateDummyData` → `ApiConfig.testGenerateDummyData`
- `api/testGenerateDummyDataSimple` → `ApiConfig.testGenerateDummyDataSimple`
- `api/create3DFaceTable` → `ApiConfig.create3DFaceTable`

---

## 📊 Summary

**Total Endpoints: 59**

- 🔐 Authentication: 6
- 🏫 School: 5
- ✅ Attendance: 10
- 👤 Face Recognition: 16
- 🤝 Face-to-Face: 11
- 📍 Location: 6
- 📊 Statistics: 3
- 🧪 Test & Debug: 9

---

## 💡 How to Use

```dart
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/api_service.dart';

// Example 1: Teacher Login
final response = await ApiService.post(
  ApiConfig.teacherLogin,
  body: {
    'username': 'teacher@example.com',
    'password': 'password123',
  },
);

// Example 2: Get School Info
final schoolInfo = await ApiService.post(
  ApiConfig.getSchoolInfo,
  body: {'action': 'mark', 'status': 'P'},
  requireAuth: true,
);

// Example 3: Quick Attendance
final attendance = await ApiService.post(
  ApiConfig.quickAttendance,
  body: {
    'face_data': faceEmbedding,
    'user_id': userId,
    'attendance_type': 'check_in',
  },
  requireAuth: true,
);

// Example 4: List Enrolled Faces
final faces = await ApiService.post(
  ApiConfig.listEnrolledFaces,
  body: {},
  requireAuth: true,
);
```

---

## 🎯 All constants are now available in `api_config.dart`!

Just use: `ApiConfig.ENDPOINT_NAME`


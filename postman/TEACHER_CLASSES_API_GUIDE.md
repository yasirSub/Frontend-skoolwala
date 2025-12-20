# Teacher Classes & Schedule API Guide

## 📋 Overview

This guide covers the APIs created for teachers to view their assigned classes and schedule in the mobile app.

---

## 🎯 APIs Created

### 1. **Get Teacher Classes** (`/api/getTeacherClasses`)
Returns all classes assigned to a teacher.

**Endpoint:** `POST /api/getTeacherClasses`

**Request Body:**
```json
{
  "username": "teacher1",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "class_id": 5,
      "class_name": "Grade 1",
      "section_id": 2,
      "section_name": "A",
      "class_section": "Grade 1 - A"
    },
    {
      "id": 2,
      "class_id": 6,
      "class_name": "Grade 2",
      "section_id": 3,
      "section_name": "B",
      "class_section": "Grade 2 - B"
    }
  ],
  "message": "Teacher classes retrieved successfully",
  "total_classes": 2
}
```

---

### 2. **Get Today's Classes** (`/api/getTeacherTodayClasses`)
Returns today's classes for a teacher based on the current day's timetable.

**Endpoint:** `POST /api/getTeacherTodayClasses`

**Request Body:**
```json
{
  "username": "teacher1",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "class_id": 5,
      "class_name": "Grade 1",
      "section_id": 2,
      "section_name": "A",
      "subject_name": "Mathematics",
      "start_time": "09:00:00",
      "end_time": "10:00:00",
      "room_number": "Room 101",
      "day": "Monday",
      "class_section": "Grade 1 - A",
      "time_slot": "09:00 AM - 10:00 AM"
    }
  ],
  "message": "Today's classes retrieved successfully",
  "total_classes": 1,
  "date": "2024-01-15",
  "day": "Monday"
}
```

---

### 3. **Get Teacher Schedule** (`/api/getTeacherSchedule`) ⭐ **NEW**
Returns complete teacher schedule for all days of the week (similar to `/timetable/teacherview` web page).

**Endpoint:** `POST /api/getTeacherSchedule`

**Request Body:**
```json
{
  "username": "teacher1",
  "password": "password123"
}
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "day": "Sunday",
      "day_key": "sunday",
      "classes": [],
      "total_classes": 0
    },
    {
      "day": "Monday",
      "day_key": "monday",
      "classes": [
        {
          "id": 1,
          "class_id": 5,
          "class_name": "Grade 1",
          "section_id": 2,
          "section_name": "A",
          "subject_id": 10,
          "subject_name": "Mathematics",
          "subject_code": "MATH",
          "start_time": "09:00:00",
          "end_time": "10:00:00",
          "time_display": "9:00 AM - 10:00 AM",
          "room_number": "Room 101",
          "is_break": false,
          "day": "monday",
          "class_section": "Grade 1 (A)"
        },
        {
          "id": 2,
          "class_id": 6,
          "class_name": "Grade 2",
          "section_id": 3,
          "section_name": "B",
          "subject_id": 11,
          "subject_name": "English",
          "subject_code": "ENG",
          "start_time": "11:00:00",
          "end_time": "12:00:00",
          "time_display": "11:00 AM - 12:00 PM",
          "room_number": "Room 102",
          "is_break": false,
          "day": "monday",
          "class_section": "Grade 2 (B)"
        }
      ],
      "total_classes": 2
    },
    {
      "day": "Tuesday",
      "day_key": "tuesday",
      "classes": [...],
      "total_classes": 3
    }
    // ... other days
  ],
  "message": "Teacher schedule retrieved successfully",
  "total_days": 7,
  "teacher_id": 123
}
```

---

## 📱 Mobile App Integration

### **Menu Structure**

The `getUserMenu` API now includes a "My Classes" menu for teachers with three options:

```json
{
  "id": "my_classes",
  "title": "My Classes",
  "icon": "class",
  "type": "parent",
  "children": [
    {
      "id": "view_all_classes",
      "title": "View All Classes",
      "icon": "list",
      "route": "/teacher/classes",
      "api_endpoint": "/api/getTeacherClasses"
    },
    {
      "id": "today_classes",
      "title": "Today's Classes",
      "icon": "today",
      "route": "/teacher/today-classes",
      "api_endpoint": "/api/getTeacherTodayClasses"
    },
    {
      "id": "teacher_schedule",
      "title": "Teacher Schedule",
      "icon": "schedule",
      "route": "/teacher/schedule",
      "api_endpoint": "/api/getTeacherSchedule"
    }
  ]
}
```

---

## 🔧 Usage Examples

### **cURL Examples**

#### Get All Teacher Classes:
```bash
curl -X POST "http://192.168.31.129:8080/api/getTeacherClasses" \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher1","password":"password123"}'
```

#### Get Today's Classes:
```bash
curl -X POST "http://192.168.31.129:8080/api/getTeacherTodayClasses" \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher1","password":"password123"}'
```

#### Get Full Teacher Schedule:
```bash
curl -X POST "http://192.168.31.129:8080/api/getTeacherSchedule" \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher1","password":"password123"}'
```

---

## 📊 Data Flow

1. **Teacher logs in** → Gets menu via `getUserMenu` API
2. **Clicks "My Classes"** → Sees three options:
   - View All Classes
   - Today's Classes
   - Teacher Schedule
3. **Clicks "Teacher Schedule"** → Calls `getTeacherSchedule` API
4. **App displays** → Weekly schedule organized by days

---

## ✅ Features

- ✅ **Authentication**: Supports both session-based and stateless (username/password)
- ✅ **Role Check**: Only teachers (role_id = 3) can access these APIs
- ✅ **Branch Support**: Automatically filters by teacher's branch
- ✅ **Session Support**: Uses current session ID for timetable filtering
- ✅ **Structured Data**: Returns well-formatted JSON for easy mobile app integration
- ✅ **Time Formatting**: Includes human-readable time displays
- ✅ **Break Handling**: Identifies break periods in schedule

---

## 🎯 Key Points

1. **All APIs require teacher authentication** (role_id = 3)
2. **Schedule matches web version** (`/timetable/teacherview`)
3. **Data is organized by days** for easy display in mobile app
4. **Includes all necessary details**: class, section, subject, time, room
5. **Ready for mobile app integration** with clear API endpoints

---

## 📝 Notes

- The schedule API returns data for all 7 days of the week
- Empty days will have `total_classes: 0` and empty `classes` array
- Break periods are marked with `is_break: true`
- Time is returned in both 24-hour format (`start_time`, `end_time`) and human-readable format (`time_display`)


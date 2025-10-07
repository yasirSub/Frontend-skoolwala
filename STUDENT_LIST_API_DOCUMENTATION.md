# Student List API Documentation

This document describes the new API endpoints for retrieving student lists based on class, section, and date.

## Authentication

All endpoints require teacher authentication. Teachers must be logged in with role ID 3.

## Endpoints

### 1. Get Class List

**Endpoint:** `POST /api/getClassList`

**Description:** Retrieves list of classes for the current branch.

**Parameters:** None

**Response Format:**
```json
{
  "status": "success|error",
  "data": [
    {
      "class_id": "ID of the class",
      "class_name": "Name of the class"
    }
  ],
  "message": "Description of the response"
}
```

**Example Response:**
```json
{
  "status": "success",
  "data": [
    {
      "class_id": "1",
      "class_name": "Class 1"
    },
    {
      "class_id": "2",
      "class_name": "Class 2"
    }
  ],
  "message": "Class list retrieved successfully"
}
```

---

### 2. Get Section List by Class

**Endpoint:** `POST /api/getSectionListByClass`

**Description:** Retrieves list of sections for a given class.

**Parameters:**
- `class_id` (required): The ID of the class

**Response Format:**
```json
{
  "status": "success|error",
  "data": [
    {
      "section_id": "ID of the section",
      "section_name": "Name of the section"
    }
  ],
  "message": "Description of the response"
}
```

**Example Request:**
```bash
curl -X POST http://yoursite.com/api/getSectionListByClass \
  -d "class_id=1"
```

**Example Response:**
```json
{
  "status": "success",
  "data": [
    {
      "section_id": "1",
      "section_name": "Section A"
    },
    {
      "section_id": "2",
      "section_name": "Section B"
    }
  ],
  "message": "Section list retrieved successfully"
}
```

---

### 3. Get Student List

**Endpoint:** `POST /api/getStudentList`

**Description:** Retrieves list of students for a given class, section, and date, including attendance information.

**Parameters:**
- `class_id` (required): The ID of the class
- `section_id` (required): The ID of the section
- `date` (optional): The date for which to retrieve attendance information (format: YYYY-MM-DD). If not provided, today's date is used.

**Response Format:**
```json
{
  "status": "success|error",
  "data": [
    {
      "enroll_id": "Enrollment ID",
      "student_id": "Student ID",
      "name": "Full name of the student",
      "register_no": "Registration number",
      "roll": "Roll number",
      "photo": "Photo filename",
      "gender": "Gender of the student",
      "attendance_status": "Attendance status (P/A) or empty if no record",
      "attendance_remark": "Attendance remark or empty if no record"
    }
  ],
  "message": "Description of the response"
}
```

**Example Request:**
```bash
curl -X POST http://yoursite.com/api/getStudentList \
  -d "class_id=1&section_id=1&date=2025-10-05"
```

**Example Response:**
```json
{
  "status": "success",
  "data": [
    {
      "enroll_id": "101",
      "student_id": "201",
      "name": "John Doe",
      "register_no": "REG001",
      "roll": "1",
      "photo": "student1.jpg",
      "gender": "male",
      "attendance_status": "P",
      "attendance_remark": "On time"
    },
    {
      "enroll_id": "102",
      "student_id": "202",
      "name": "Jane Smith",
      "register_no": "REG002",
      "roll": "2",
      "photo": "student2.jpg",
      "gender": "female",
      "attendance_status": "A",
      "attendance_remark": "Sick leave"
    }
  ],
  "message": "Student list retrieved successfully"
}
```

---

### 4. Mark Student Attendance

**Endpoint:** `POST /api/markStudentAttendance`

**Description:** Marks attendance (Present/Absent) for specific students.

**Parameters:**
- `class_id` (required): The ID of the class
- `section_id` (required): The ID of the section
- `date` (required): The date for which to mark attendance (format: YYYY-MM-DD)
- `attendance_data` (required): An object containing attendance information for each student

**Attendance Data Format:**
```json
{
  "ENROLL_ID": {
    "status": "P|A",  // P for Present, A for Absent
    "remark": "Optional remark"
  }
}
```

**Response Format:**
```json
{
  "status": "success|partial_success|error",
  "data": {
    "saved_records": "Number of records saved",
    "errors": ["Array of error messages (if any)"]
  },
  "message": "Description of the response"
}
```

**Example Request:**
```bash
curl -X POST http://yoursite.com/api/markStudentAttendance \
  -d "class_id=1" \
  -d "section_id=1" \
  -d "date=2025-10-05" \
  -d "attendance_data[101][status]=P" \
  -d "attendance_data[101][remark]=On time" \
  -d "attendance_data[102][status]=A" \
  -d "attendance_data[102][remark]=Sick leave"
```

**Example Response:**
```json
{
  "status": "success",
  "data": {
    "saved_records": 2
  },
  "message": "Attendance data saved successfully"
}
```

---

### 5. Mark All Students Attendance

**Endpoint:** `POST /api/markAllStudentsAttendance`

**Description:** Marks all students in a class/section as Present or Absent for a given date.

**Parameters:**
- `class_id` (required): The ID of the class
- `section_id` (required): The ID of the section
- `date` (required): The date for which to mark attendance (format: YYYY-MM-DD)
- `status` (required): The attendance status to apply to all students ('P' for Present, 'A' for Absent)
- `remark` (optional): An optional remark to apply to all students

**Response Format:**
```json
{
  "status": "success|error",
  "data": {
    "saved_records": "Number of records saved",
    "status_applied": "The status that was applied (P/A)",
    "remark": "The remark that was applied"
  },
  "message": "Description of the response"
}
```

**Example Request:**
```bash
curl -X POST http://yoursite.com/api/markAllStudentsAttendance \
  -d "class_id=1" \
  -d "section_id=1" \
  -d "date=2025-10-05" \
  -d "status=P" \
  -d "remark=All present"
```

**Example Response:**
```json
{
  "status": "success",
  "data": {
    "saved_records": 25,
    "status_applied": "P",
    "remark": "All present"
  },
  "message": "Attendance marked as Present for all 25 students"
}
```

## Error Responses

All endpoints may return the following HTTP status codes:
- 400: Bad request (missing required parameters or invalid data)
- 401: Unauthorized (teacher not logged in)
- 404: Not found (no students found for the given class/section)
- 500: Server error

## Usage Workflow

1. First, call `getClassList` to get available classes
2. Then, call `getSectionListByClass` with a selected class ID to get sections for that class
3. Call `getStudentList` with class ID, section ID, and optional date to get the student list with current attendance information
4. Finally, call either:
   - `markStudentAttendance` to save attendance records for specific students
   - `markAllStudentsAttendance` to mark all students as Present or Absent

## Testing

You can test these endpoints using the provided test files in the root directory of the application:
- `test_student_list_api.html` for testing student list endpoints
- `test_mark_attendance_api.html` for testing the individual student attendance endpoint
- `test_mark_all_attendance_api.html` for testing the mark all students attendance endpoint
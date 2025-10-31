# Face Recognition API Specification for Skoolwala

## Overview
This document outlines the API endpoints required for implementing face recognition-based attendance marking in the Skoolwala application.

## Database Schema Changes

### Add to `teachers` table:
```sql
ALTER TABLE teachers ADD COLUMN face_template VARCHAR(64) NULL;
ALTER TABLE teachers ADD COLUMN face_template_created_at TIMESTAMP NULL;
ALTER TABLE teachers ADD COLUMN face_template_updated_at TIMESTAMP NULL;
ALTER TABLE teachers ADD COLUMN face_verification_enabled BOOLEAN DEFAULT FALSE;

-- Add index for faster face template lookups
CREATE INDEX idx_teachers_face_template ON teachers(face_template);
```

## API Endpoints

### 1. Mark Teacher Attendance with Face Recognition

**Endpoint:** `POST /api/teacherAttendanceWithFace`

**Description:** Mark teacher attendance using face verification data

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token} (if using token auth)
```

**Request Body:**
```json
{
  "action": "mark",
  "status": "P",
  "face_data": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "face_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "timestamp": "2025-01-08T10:30:00.000Z",
  "verification_method": "face_recognition"
}
```

**Field Descriptions:**
- `action`: String - "mark" for marking attendance
- `status`: String - "P" for Present, "A" for Absent
- `face_data`: String - 64-character hex string representing face hash
- `face_hash`: String - Same as face_data (for compatibility)
- `timestamp`: String - ISO 8601 timestamp of verification
- `verification_method`: String - Always "face_recognition"

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "teacher_id": "10",
    "branch_id": "1",
    "date": "2025-01-08",
    "status": "P",
    "in_time": "10:30:00",
    "out_time": null,
    "remark": "",
    "verification_method": "face_recognition",
    "face_confidence": 0.95,
    "attendance_id": "12345"
  },
  "message": "Attendance marked successfully with face verification"
}
```

**Error Response (400):**
```json
{
  "status": "error",
  "message": "Face verification failed: No matching face template found",
  "error_code": "FACE_VERIFICATION_FAILED"
}
```

**Error Response (401):**
```json
{
  "status": "error",
  "message": "Unauthorized: Invalid credentials",
  "error_code": "UNAUTHORIZED"
}
```

### 2. Register Teacher Face Template

**Endpoint:** `POST /api/registerTeacherFace`

**Description:** Register/update teacher's face template for future verification

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "teacher_id": "10",
  "face_template": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "face_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "registered_at": "2025-01-08T10:30:00.000Z"
}
```

**Field Descriptions:**
- `teacher_id`: String - Teacher's unique identifier
- `face_template`: String - 64-character hex string representing face template
- `face_hash`: String - Same as face_template (for compatibility)
- `registered_at`: String - ISO 8601 timestamp of registration

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "teacher_id": "10",
    "face_template_registered": true,
    "registered_at": "2025-01-08T10:30:00.000Z",
    "face_verification_enabled": true
  },
  "message": "Face template registered successfully"
}
```

### 3. Verify Teacher Face Template

**Endpoint:** `POST /api/verifyTeacherFace`

**Description:** Verify teacher's face against stored template

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "teacher_id": "10",
  "face_data": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "face_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "verification_time": "2025-01-08T10:30:00.000Z"
}
```

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "teacher_id": "10",
    "verification_successful": true,
    "confidence_score": 0.95,
    "similarity_threshold": 0.8,
    "verification_time": "2025-01-08T10:30:00.000Z"
  },
  "message": "Face verification successful"
}
```

**Error Response (400):**
```json
{
  "status": "error",
  "data": {
    "teacher_id": "10",
    "verification_successful": false,
    "confidence_score": 0.65,
    "similarity_threshold": 0.8
  },
  "message": "Face verification failed: Low confidence score"
}
```

### 4. Get Teacher Face Status

**Endpoint:** `GET /api/teacherFaceStatus`

**Description:** Check if teacher has face template registered

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `teacher_id`: String (required) - Teacher's unique identifier

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "teacher_id": "10",
    "has_face_template": true,
    "face_verification_enabled": true,
    "template_created_at": "2025-01-08T09:15:00.000Z",
    "template_updated_at": "2025-01-08T09:15:00.000Z"
  },
  "message": "Face template status retrieved successfully"
}
```

### 5. Delete Teacher Face Template

**Endpoint:** `DELETE /api/teacherFaceTemplate`

**Description:** Remove teacher's face template

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "teacher_id": "10"
}
```

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "teacher_id": "10",
    "face_template_deleted": true,
    "face_verification_enabled": false
  },
  "message": "Face template deleted successfully"
}
```

## Face Hash Specifications

### Format Requirements:
- **Length:** 64 characters
- **Format:** Hexadecimal (0-9, a-f)
- **Example:** `a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456`

### Validation Rules:
```php
// PHP validation example
function validateFaceHash($faceHash) {
    return strlen($faceHash) === 64 && 
           preg_match('/^[a-f0-9]+$/', $faceHash);
}
```

## Face Comparison Algorithm

### Similarity Calculation:
```php
// PHP implementation example
function calculateFaceSimilarity($hash1, $hash2) {
    if (strlen($hash1) !== strlen($hash2)) {
        return 0.0;
    }
    
    $matches = 0;
    for ($i = 0; $i < strlen($hash1); $i++) {
        if ($hash1[$i] === $hash2[$i]) {
            $matches++;
        }
    }
    
    return $matches / strlen($hash1);
}

function isFaceMatch($storedHash, $inputHash, $threshold = 0.8) {
    $similarity = calculateFaceSimilarity($storedHash, $inputHash);
    return $similarity >= $threshold;
}
```

### Recommended Thresholds:
- **High Security:** 0.9 (90% similarity required)
- **Standard:** 0.8 (80% similarity required)
- **Low Security:** 0.7 (70% similarity required)

## Error Codes

| Code | Description |
|------|-------------|
| `FACE_VERIFICATION_FAILED` | Face verification unsuccessful |
| `FACE_TEMPLATE_NOT_FOUND` | No face template registered for teacher |
| `FACE_TEMPLATE_EXISTS` | Face template already exists |
| `INVALID_FACE_HASH` | Face hash format is invalid |
| `FACE_VERIFICATION_DISABLED` | Face verification not enabled for teacher |
| `UNAUTHORIZED` | Invalid authentication credentials |
| `TEACHER_NOT_FOUND` | Teacher ID not found |
| `DATABASE_ERROR` | Database operation failed |

## Security Considerations

### Data Protection:
1. **Encrypt face templates** in database
2. **Use HTTPS** for all API communications
3. **Implement rate limiting** to prevent brute force attacks
4. **Log all face verification attempts** for audit purposes
5. **Store verification timestamps** for compliance

### Privacy Compliance:
1. **Allow teachers to delete** their face templates
2. **Implement data retention policies**
3. **Provide clear consent mechanisms**
4. **Follow GDPR/local privacy laws**

## Testing Data

### Sample Face Hashes for Testing:
```json
{
  "teacher_1_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456",
  "teacher_2_hash": "b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567a",
  "similar_hash": "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123457"
}
```

## Implementation Priority

### Phase 1 (Essential):
1. `teacherAttendanceWithFace` - Mark attendance with face data
2. `registerTeacherFace` - Register face templates
3. Basic face comparison algorithm

### Phase 2 (Enhancement):
1. `verifyTeacherFace` - Standalone verification
2. `teacherFaceStatus` - Check template status
3. Advanced similarity algorithms

### Phase 3 (Management):
1. `DELETE /api/teacherFaceTemplate` - Remove templates
2. Bulk face template operations
3. Advanced security features

## Contact Information

**Frontend Implementation:** Flutter app ready with face verification screen
**API Testing:** Use provided sample data for initial testing
**Questions:** Contact development team for clarifications

---

*This specification is based on the current Flutter implementation and can be extended as needed.*

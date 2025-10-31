# Developer Dummy Data Generator

## Overview
This feature allows developers to generate dummy attendance data for testing purposes. It's only available in development mode and provides options to generate attendance records for today, current month, or current year.

## Features

### 🎯 **Time Period Options**
- **Today Only**: Generate attendance for today's date
- **Current Month**: Generate attendance for all working days in the current month
- **Current Year**: Generate attendance for all working days in the current year

### 📊 **Attendance Patterns**
- **Mixed Pattern**: 85% Present, 10% Absent, 5% Late (realistic distribution)
- **Always Present**: Generate only present records
- **Always Absent**: Generate only absent records

### 🛠️ **Developer Tools**
- **Generate Data**: Create dummy attendance records
- **Delete Data**: Remove existing attendance records
- **Real-time Feedback**: Shows success/error messages
- **Confirmation Dialogs**: Prevents accidental data deletion

## API Endpoints

### 1. Generate Dummy Data
```
POST /api/generateDummyData
```

**Request Body:**
```json
{
  "staff_id": 123,
  "type": "today|month|year",
  "pattern": "mixed|present|absent"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Generated 20 attendance records",
  "generated_count": 20,
  "type": "month",
  "pattern": "mixed",
  "staff_name": "John Doe",
  "dates_generated": ["2024-01-01", "2024-01-02", ...]
}
```

### 2. Delete Attendance Data
```
POST /api/deleteAttendance
```

**Request Body:**
```json
{
  "staff_id": 123,
  "type": "today|month|range",
  "date": "2024-01-15", // for today type
  "start_date": "2024-01-01", // for range type
  "end_date": "2024-01-31" // for range type
}
```

### 3. Get Staff List
```
GET /api/getStaffList
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 123,
      "name": "John Doe",
      "email": "john@example.com",
      "designation": "Teacher",
      "branch_id": 1
    }
  ],
  "count": 1
}
```

## Database Structure

### staff_attendance Table
```sql
CREATE TABLE staff_attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  staff_id INT NOT NULL,
  status ENUM('P', 'A', 'L', 'H', 'HD') NOT NULL,
  remark TEXT,
  date DATE NOT NULL,
  branch_id INT NOT NULL,
  location_id INT DEFAULT NULL,
  user_latitude DECIMAL(10,8) DEFAULT NULL,
  user_longitude DECIMAL(11,8) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Status Codes
- **P**: Present
- **A**: Absent  
- **L**: Late
- **H**: Holiday
- **HD**: Half Day

## Usage Examples

### Generate Today's Data
```dart
final result = await DummyDataService.generateDummyData(
  staffId: 123,
  type: 'today',
  pattern: 'mixed',
);
```

### Generate Month Data
```dart
final result = await DummyDataService.generateDummyData(
  staffId: 123,
  type: 'month',
  pattern: 'present',
);
```

### Delete Month Data
```dart
final result = await DummyDataService.deleteAttendanceData(
  staffId: 123,
  type: 'month',
);
```

## Security Features

### 🔒 **Development Mode Only**
- All endpoints check `ENVIRONMENT !== 'development'`
- Returns error if not in development mode
- Prevents accidental use in production

### 🛡️ **Data Validation**
- Validates staff_id exists
- Checks for duplicate records before insertion
- Skips weekends automatically
- Handles edge cases gracefully

### ⚠️ **Safety Measures**
- Confirmation dialogs for deletion
- Clear error messages
- Rollback on failures
- No data corruption

## Flutter Integration

### Widget Usage
```dart
DummyDataGenerator(
  staffId: teacher.id,
  staffName: teacher.name,
)
```

### Service Usage
```dart
import 'package:skoolwala/features/profile/services/dummy_data_service.dart';

// Generate data
await DummyDataService.generateDummyData(
  staffId: 123,
  type: 'month',
  pattern: 'mixed',
);

// Delete data
await DummyDataService.deleteAttendanceData(
  staffId: 123,
  type: 'month',
);
```

## Configuration

### Environment Setup
1. Set `ENVIRONMENT = 'development'` in your PHP configuration
2. Ensure database connection is working
3. Verify staff table has data

### Flutter Setup
1. Import the service and widget
2. Add to profile screen (only in debug mode)
3. Test with different patterns and time periods

## Troubleshooting

### Common Issues

**1. "This endpoint is only available in development mode"**
- Check PHP environment configuration
- Ensure `ENVIRONMENT` is set to `'development'`

**2. "Staff not found"**
- Verify staff_id exists in database
- Check staff table has valid records

**3. "Network error"**
- Check API base URL configuration
- Verify backend server is running
- Test API connectivity

**4. "Failed to generate dummy data"**
- Check database permissions
- Verify staff_attendance table exists
- Check for constraint violations

### Debug Tips
- Enable debug logging in PHP
- Check Flutter console for network errors
- Verify API responses in browser dev tools
- Test with small data sets first

## Best Practices

### ✅ **Do's**
- Use in development/testing environments only
- Test with small datasets first
- Clean up test data regularly
- Use realistic attendance patterns
- Document your test scenarios

### ❌ **Don'ts**
- Never use in production
- Don't generate excessive amounts of data
- Don't forget to clean up test data
- Don't ignore error messages
- Don't use real staff data for testing

## Future Enhancements

### Planned Features
- [ ] Bulk staff data generation
- [ ] Custom date range selection
- [ ] Attendance pattern templates
- [ ] Data export/import functionality
- [ ] Advanced filtering options
- [ ] Performance metrics dashboard

### API Improvements
- [ ] Pagination for staff list
- [ ] Batch operations support
- [ ] Real-time progress updates
- [ ] Data validation improvements
- [ ] Enhanced error handling

---

**Note**: This feature is designed exclusively for development and testing purposes. Always ensure you're working in a development environment and never use this feature in production.

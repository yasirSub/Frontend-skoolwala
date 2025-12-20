# Mobile App Schedule Implementation Guide

## 📱 Screen Flow

### **Tab 1: "Today's Schedule" (Default View)**
- Shows today's classes using `/api/getTeacherTodayClasses`
- Displays classes scheduled for the current day only
- Shows "No Classes Today" if empty

### **Tab 2: "View" (Swipe Right)**
- Shows full week schedule using `/api/getTeacherSchedule`
- Displays all classes organized by days (Sunday through Saturday)
- Weekly timetable view

---

## 🔌 API Endpoints

### **1. Today's Classes API**

**Endpoint:** `POST /api/getTeacherTodayClasses`

**Request:**
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

**Use Case:** Load when screen opens (default tab)

---

### **2. Full Week Schedule API**

**Endpoint:** `POST /api/getTeacherSchedule`

**Request:**
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
          "subject_name": "Mathematics",
          "subject_code": "MATH",
          "start_time": "09:00:00",
          "end_time": "10:00:00",
          "time_display": "9:00 AM - 10:00 AM",
          "room_number": "Room 101",
          "is_break": false,
          "day": "monday",
          "class_section": "Grade 1 (A)"
        }
      ],
      "total_classes": 1
    },
    {
      "day": "Tuesday",
      "day_key": "tuesday",
      "classes": [...],
      "total_classes": 2
    }
    // ... other days
  ],
  "message": "Teacher schedule retrieved successfully",
  "total_days": 7,
  "teacher_id": 123
}
```

**Use Case:** Load when user swipes to "View" tab

---

## 🎨 UI Implementation

### **Flutter/Dart Implementation Example**

```dart
class TeacherScheduleScreen extends StatefulWidget {
  @override
  _TeacherScheduleScreenState createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> 
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  List<TodayClass> todayClasses = [];
  List<DaySchedule> weekSchedule = [];
  bool isLoadingToday = true;
  bool isLoadingWeek = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadTodayClasses(); // Load today's classes on screen open
  }

  // Load Today's Classes (Tab 1)
  Future<void> loadTodayClasses() async {
    setState(() => isLoadingToday = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/api/getTeacherTodayClasses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'teacher1',
          'password': 'password123',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          todayClasses = (data['data'] as List)
              .map((item) => TodayClass.fromJson(item))
              .toList();
          isLoadingToday = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingToday = false);
      print('Error loading today classes: $e');
    }
  }

  // Load Full Week Schedule (Tab 2)
  Future<void> loadWeekSchedule() async {
    if (weekSchedule.isNotEmpty) return; // Already loaded
    
    setState(() => isLoadingWeek = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.129:8080/api/getTeacherSchedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': 'teacher1',
          'password': 'password123',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          weekSchedule = (data['data'] as List)
              .map((item) => DaySchedule.fromJson(item))
              .toList();
          isLoadingWeek = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingWeek = false);
      print('Error loading week schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Schedule'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 1 && weekSchedule.isEmpty) {
              loadWeekSchedule(); // Load week schedule when switching to View tab
            }
          },
          tabs: [
            Tab(text: 'Classes'),
            Tab(text: 'View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Today's Classes
          _buildTodayView(),
          // Tab 2: Full Week Schedule
          _buildWeekView(),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    if (isLoadingToday) {
      return Center(child: CircularProgressIndicator());
    }

    if (todayClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'No Classes Today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You have no scheduled classes for today.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: loadTodayClasses,
              icon: Icon(Icons.refresh),
              label: Text('Refresh Today'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: todayClasses.length,
      itemBuilder: (context, index) {
        final classItem = todayClasses[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.class_),
            title: Text(classItem.classSection),
            subtitle: Text(classItem.subjectName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(classItem.timeSlot),
                Text(classItem.roomNumber),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekView() {
    if (isLoadingWeek) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: weekSchedule.length,
      itemBuilder: (context, index) {
        final daySchedule = weekSchedule[index];
        return ExpansionTile(
          title: Text(
            '${daySchedule.day} (${daySchedule.totalClasses} classes)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: daySchedule.classes.isEmpty
              ? [ListTile(title: Text('No classes scheduled'))]
              : daySchedule.classes.map((classItem) {
                  return ListTile(
                    leading: Icon(Icons.class_),
                    title: Text(classItem.classSection),
                    subtitle: Text(classItem.subjectName),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(classItem.timeDisplay),
                        Text(classItem.roomNumber),
                      ],
                    ),
                  );
                }).toList(),
        );
      },
    );
  }
}

// Data Models
class TodayClass {
  final String classSection;
  final String subjectName;
  final String timeSlot;
  final String roomNumber;

  TodayClass({
    required this.classSection,
    required this.subjectName,
    required this.timeSlot,
    required this.roomNumber,
  });

  factory TodayClass.fromJson(Map<String, dynamic> json) {
    return TodayClass(
      classSection: json['class_section'] ?? '',
      subjectName: json['subject_name'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      roomNumber: json['room_number'] ?? '',
    );
  }
}

class DaySchedule {
  final String day;
  final String dayKey;
  final List<ClassItem> classes;
  final int totalClasses;

  DaySchedule({
    required this.day,
    required this.dayKey,
    required this.classes,
    required this.totalClasses,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] ?? '',
      dayKey: json['day_key'] ?? '',
      classes: (json['classes'] as List?)
              ?.map((item) => ClassItem.fromJson(item))
              .toList() ??
          [],
      totalClasses: json['total_classes'] ?? 0,
    );
  }
}

class ClassItem {
  final String classSection;
  final String subjectName;
  final String timeDisplay;
  final String roomNumber;

  ClassItem({
    required this.classSection,
    required this.subjectName,
    required this.timeDisplay,
    required this.roomNumber,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      classSection: json['class_section'] ?? '',
      subjectName: json['subject_name'] ?? '',
      timeDisplay: json['time_display'] ?? '',
      roomNumber: json['room_number'] ?? '',
    );
  }
}
```

---

## 🔄 Swipe Functionality

### **Implementation Options:**

1. **TabBar with TabBarView** (Recommended)
   - Built-in swipe gesture support
   - Easy to implement
   - Native feel

2. **PageView Widget**
   - More control over swipe behavior
   - Custom animations possible

3. **GestureDetector**
   - Full control over gestures
   - More complex implementation

---

## 📋 Checklist

- [x] API for Today's Classes (`/api/getTeacherTodayClasses`)
- [x] API for Full Week Schedule (`/api/getTeacherSchedule`)
- [ ] Load today's classes on screen open
- [ ] Load week schedule when swiping to "View" tab
- [ ] Display "No Classes Today" when empty
- [ ] Show loading indicators
- [ ] Handle errors gracefully
- [ ] Refresh functionality for today's view

---

## 🎯 Key Points

1. **Default View**: Load today's classes when screen opens
2. **Lazy Loading**: Load week schedule only when user swipes to "View" tab
3. **Empty State**: Show friendly message when no classes
4. **Refresh**: Allow manual refresh for today's classes
5. **Data Format**: APIs return structured JSON ready for mobile display

---

## 🚀 Quick Test

### Test Today's Classes:
```bash
curl -X POST "http://192.168.31.129:8080/api/getTeacherTodayClasses" \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher1","password":"password123"}'
```

### Test Full Week Schedule:
```bash
curl -X POST "http://192.168.31.129:8080/api/getTeacherSchedule" \
  -H "Content-Type: application/json" \
  -d '{"username":"teacher1","password":"password123"}'
```


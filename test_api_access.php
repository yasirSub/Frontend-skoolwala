<?php
// Test script to demonstrate correct API access with session management

echo "=== Correct API Access Test ===\n\n";

// Initialize session file to store cookies
$cookieFile = tempnam(sys_get_temp_dir(), 'cookie');

// Teacher credentials
$teacherUsername = 'teacher+1@skoolwala.com';
$teacherPassword = 'password123';  // Replace with actual password

echo "1. Logging in...\n";

// Login endpoint (CORRECT URL with index.php)
$loginUrl = 'http://localhost:8080/index.php/api/teacherLogin';
$loginData = [
    'username' => $teacherUsername,
    'password' => $teacherPassword
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $loginUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);  // Save cookies

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Login Status Code: " . $httpCode . "\n";

if ($httpCode == 200) {
    echo "Login successful!\n\n";
    
    // Access teacher profile (CORRECT URL with index.php)
    echo "2. Accessing teacher profile...\n";
    
    $profileUrl = 'http://localhost:8080/index.php/api/teacherProfile';
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $profileUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);  // Use saved cookies
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Profile Status Code: " . $httpCode . "\n";
    echo "Profile Response:\n" . $response . "\n\n";
    
    // Test teacher attendance endpoint
    echo "3. Testing teacher attendance endpoint...\n";
    
    $attendanceUrl = 'http://localhost:8080/index.php/api/teacherAttendance';
    $attendanceData = [
        'action' => 'get',
        'date' => date('Y-m-d'),
        'class_id' => '1',
        'section_id' => '1'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $attendanceUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($attendanceData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);  // Use saved cookies
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Attendance Status Code: " . $httpCode . "\n";
    echo "Attendance Response:\n" . $response . "\n\n";
    
} else {
    echo "Login failed. Please check credentials.\n";
    echo "Response: " . $response . "\n";
}

// Clean up
unlink($cookieFile);
?>
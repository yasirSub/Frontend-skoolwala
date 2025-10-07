<?php
// Test script for teacherLogin API endpoint

// Set the URL for the API endpoint
$url = 'http://localhost:8080/api/teacherLogin';

// Sample data (you'll need to replace with valid credentials from your database)
$postData = [
    'username' => 'teacher_test',
    'password' => 'password123'
];

// Initialize cURL session
$ch = curl_init($url);

// Set cURL options
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded',
    'Accept: application/json'
]);

// Execute the request
$response = curl_exec($ch);

// Get HTTP status code
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

// Close cURL session
curl_close($ch);

// Display results
echo "HTTP Status Code: " . $httpCode . "\n";
echo "Response:\n" . $response . "\n";

// Also test with JSON data
echo "\n--- Testing with JSON data ---\n";

$jsonData = json_encode($postData);

$ch2 = curl_init($url);
curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch2, CURLOPT_POST, true);
curl_setopt($ch2, CURLOPT_POSTFIELDS, $jsonData);
curl_setopt($ch2, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response2 = curl_exec($ch2);
$httpCode2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
curl_close($ch2);

echo "HTTP Status Code (JSON): " . $httpCode2 . "\n";
echo "Response (JSON):\n" . $response2 . "\n";
?>
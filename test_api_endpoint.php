<?php
// Test script to check if the API endpoint is accessible

// Set the URL for the API endpoint
$url = 'http://localhost:8080/api/teacherLogin';

// Initialize cURL session
$ch = curl_init($url);

// Set cURL options
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => 'test',
    'password' => 'test'
]));
curl_setopt($ch, CURLOPT_HEADER, true);

// Execute the request
$response = curl_exec($ch);

// Get HTTP status code
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

// Get header size
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);

// Close cURL session
curl_close($ch);

// Separate headers and body
$headers = substr($response, 0, $headerSize);
$body = substr($response, $headerSize);

// Display results
echo "HTTP Status Code: " . $httpCode . "\n";
echo "Headers:\n" . $headers . "\n";
echo "Body:\n" . $body . "\n";
?>
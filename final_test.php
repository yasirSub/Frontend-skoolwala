<?php
// Final test of the API endpoint

$ch = curl_init();

// Set the URL
curl_setopt($ch, CURLOPT_URL, "http://localhost:8080/api/teacherLogin");

// Set method and data
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'username' => 'test',
    'password' => 'test'
]));

// Return the response instead of printing it
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

// Execute the request
$response = curl_exec($ch);

// Get HTTP status code
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

// Close cURL session
curl_close($ch);

// Print results
echo "HTTP Status Code: " . $httpCode . "\n";
echo "Response: " . $response . "\n";

// Also test the direct controller access
echo "\n--- Testing direct controller access ---\n";

$ch2 = curl_init();
curl_setopt($ch2, CURLOPT_URL, "http://localhost:8080/index.php/api/teacherLogin");
curl_setopt($ch2, CURLOPT_POST, true);
curl_setopt($ch2, CURLOPT_POSTFIELDS, http_build_query([
    'username' => 'test',
    'password' => 'test'
]));
curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);

$response2 = curl_exec($ch2);
$httpCode2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
curl_close($ch2);

echo "HTTP Status Code (direct): " . $httpCode2 . "\n";
echo "Response (direct): " . $response2 . "\n";
?>
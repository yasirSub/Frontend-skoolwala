<?php
// Simple script to verify our fixes

echo "Checking if API routes are properly configured...\n";

// Include the routes file to check if our API routes are defined
include 'application/config/routes.php';

// Check if API routes are defined
if (isset($route['api/teacherLogin']) && $route['api/teacherLogin'] === 'api/teacherLogin') {
    echo "✓ API routes are properly configured\n";
} else {
    echo "✗ API routes are NOT properly configured\n";
}

echo "\nChecking if CSRF protection is disabled in API controller...\n";

// Read the API controller file
$apiController = file_get_contents('application/controllers/Api.php');

if (strpos($apiController, 'csrf_protection') !== false && strpos($apiController, 'false') !== false) {
    echo "✓ CSRF protection is disabled in API controller\n";
} else {
    echo "✗ CSRF protection may still be enabled in API controller\n";
}

echo "\nTo fully test the API, please:\n";
echo "1. Restart your Apache server\n";
echo "2. Try accessing: POST http://localhost:8080/api/teacherLogin\n";
echo "3. With JSON data: {\"username\": \"test\", \"password\": \"test\"}\n";
?>
<?php
// Simple test script to verify API endpoint

$url = 'http://localhost:8080/api/teacherLogin';

// Sample data (you'll need to replace with valid credentials)
$data = array(
    'username' => 'teacher_username',
    'password' => 'teacher_password'
);

$options = array(
    'http' => array(
        'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
        'method'  => 'POST',
        'content' => http_build_query($data)
    )
);

$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);

if ($result === FALSE) {
    echo "Error: Could not connect to API endpoint\n";
} else {
    echo "Response:\n";
    echo $result;
}
?>
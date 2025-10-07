<?php
// Direct test of the API controller method

// Set up the CodeIgniter environment
define('ENVIRONMENT', 'development');
define('BASEPATH', 'C:/xampp/htdocs/skoolwala/system/');
define('APPPATH', 'C:/xampp/htdocs/skoolwala/application/');
define('VIEWPATH', 'C:/xampp/htdocs/skoolwala/application/views/');

// Include the CodeIgniter framework
require_once 'C:/xampp/htdocs/skoolwala/system/core/CodeIgniter.php';

// Simulate a request to the teacherLogin method
$_SERVER['REQUEST_METHOD'] = 'POST';
$_POST['username'] = 'test';
$_POST['password'] = 'test';

// Create an instance of the Api controller and call the teacherLogin method
require_once 'C:/xampp/htdocs/skoolwala/application/controllers/Api.php';
$api = new Api();
$api->teacherLogin();
?>
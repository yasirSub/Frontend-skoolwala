<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * @package : Ramom School Management System
 * @version : 6.5
 * @developed by : RamomCoder
 * @support : ramomcoder@yahoo.com
 * @author url : http://codecanyon.net/user/RamomCoder
 * @filename : Api.php
 */

class Api extends CI_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->model('authentication_model');
        $this->load->model('employee_model');
        // Disable CSRF protection for API endpoints
        $this->config->set_item('csrf_protection', false);
        // Set content type to JSON
        header('Content-Type: application/json');
    }
    
    /**
     * API: Role 3 (Teacher) Login
     * Authenticates teacher login credentials
     */
    public function teacherLogin()
    {
        header('Content-Type: application/json');
        
        $username = $this->input->post('username');
        $password = $this->input->post('password');
        
        if (empty($username) || empty($password)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Username and password are required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        try {
            // Load authentication model
            $this->load->model('authentication_model');
            
            // Check login credentials
            $login_data = $this->authentication_model->login_credential($username, $password);
            
            if ($login_data === false) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Invalid username or password'
                );
                http_response_code(401);
                echo json_encode($response);
                return;
            }
            
            // Check if user has role 3 (teacher)
            if ($login_data->role != 3) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'User is not authorized as a teacher'
                );
                http_response_code(403);
                echo json_encode($response);
                return;
            }
            
            // Get teacher details
            $teacher_data = $this->db->select('id, name, email, mobileno, photo, branch_id')
                                   ->get_where('staff', array('id' => $login_data->user_id))
                                   ->row();
            
            if (empty($teacher_data)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Teacher data not found'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // SET SESSION DATA FOR AUTHENTICATION
            $sessionData = array(
                'loggedin' => true,
                'loggedin_id' => $login_data->id,
                'loggedin_userid' => $login_data->user_id,
                'loggedin_role_id' => $login_data->role,
                'loggedin_branch' => $teacher_data->branch_id,
                'loggedin_type' => 'teacher',
                'set_session_id' => get_session_id(),
                'set_lang' => 'english'
            );
            $this->authentication_model->sessionSet($sessionData);
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'user_id' => $login_data->user_id,
                    'username' => $login_data->username,
                    'role' => $login_data->role,
                    'teacher_id' => $teacher_data->id,
                    'name' => $teacher_data->name,
                    'email' => $teacher_data->email,
                    'mobile' => $teacher_data->mobileno,
                    'photo' => $teacher_data->photo,
                    'branch_id' => $teacher_data->branch_id,
                    'last_login' => $login_data->last_login
                ),
                'message' => 'Teacher login successful'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Login failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Attendance for Role 3 (Teacher)
     * Gets or updates attendance records
     */
    public function teacherAttendance()
    {
        header('Content-Type: application/json');
        
        // For public access, we need to check authentication manually
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $action = $this->input->post('action');
        $teacher_id = get_loggedin_user_id();
        
        try {
            if ($action == 'get') {
                // Get attendance data
                $date = $this->input->post('date');
                $class_id = $this->input->post('class_id');
                $section_id = $this->input->post('section_id');
                $branch_id = $this->application_model->get_branch_id();
                
                if (empty($date) || empty($class_id) || empty($section_id)) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Date, class_id and section_id are required'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    return;
                }
                
                // Load attendance model
                $this->load->model('attendance_model');
                
                // Get student attendance
                $attendance_data = $this->attendance_model->getStudentAttendence($class_id, $section_id, $date, $branch_id);
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'date' => $date,
                        'class_id' => $class_id,
                        'section_id' => $section_id,
                        'attendance' => $attendance_data
                    ),
                    'message' => 'Attendance data retrieved successfully'
                );
                http_response_code(200);
                
            } elseif ($action == 'save') {
                // Save attendance data
                $attendance_data = $this->input->post('attendance_data');
                $date = $this->input->post('date');
                $class_id = $this->input->post('class_id');
                $section_id = $this->input->post('section_id');
                
                if (empty($attendance_data) || empty($date) || empty($class_id) || empty($section_id)) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Attendance data, date, class_id and section_id are required'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    return;
                }
                
                // Process attendance data
                $saved_count = 0;
                foreach ($attendance_data as $student_id => $status) {
                    // Check if attendance record already exists
                    $this->db->select('id');
                    $this->db->from('student_attendance');
                    $this->db->where('enroll_id', $student_id);
                    $this->db->where('date', $date);
                    $query = $this->db->get();
                    
                    $attendance_record = array(
                        'enroll_id' => $student_id,
                        'date' => $date,
                        'status' => $status['status'],
                        'remark' => isset($status['remark']) ? $status['remark'] : ''
                    );
                    
                    if ($query->num_rows() > 0) {
                        // Update existing record
                        $this->db->where('id', $query->row()->id);
                        $this->db->update('student_attendance', $attendance_record);
                    } else {
                        // Insert new record
                        $this->db->insert('student_attendance', $attendance_record);
                    }
                    $saved_count++;
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'saved_records' => $saved_count
                    ),
                    'message' => 'Attendance data saved successfully'
                );
                http_response_code(200);
                
            } else {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Invalid action. Use "get" or "save"'
                );
                http_response_code(400);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Attendance operation failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Teacher Self Attendance (Present/Absent) with Conditional Times
     * Allows teachers to mark their own attendance with in_time for Present and out_time for Absent
     */
    public function teacherSelfAttendance()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $teacher_id = get_loggedin_user_id();
        $branch_id = $this->application_model->get_branch_id(); // Get branch ID
        $action = $this->input->post('action'); // 'mark' or 'get'
        
        try {
            if ($action == 'mark') {
                // Mark teacher attendance
                $status = $this->input->post('status'); // 'P' for present, 'A' for absent
                $date = $this->input->post('date') ? $this->input->post('date') : date('Y-m-d');
                $remark = $this->input->post('remark') ? $this->input->post('remark') : '';
                
                // Get current time for automatic time setting
                $current_time = date('H:i:s');
                
                if (empty($status) || !in_array($status, array('P', 'A'))) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Status is required and must be either "P" (Present) or "A" (Absent)'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    return;
                }
                
                // Check if attendance record already exists for this teacher on this date
                $this->db->select('id');
                $this->db->from('staff_attendance');
                $this->db->where('staff_id', $teacher_id);
                $this->db->where('date', $date);
                $query = $this->db->get();
                
                // Set time based on status
                $attendance_record = array(
                    'staff_id' => $teacher_id,
                    'branch_id' => $branch_id, // Add branch_id to the record
                    'date' => $date,
                    'status' => $status,
                    'remark' => $remark
                );
                
                // Add time based on status
                if ($status == 'P') {
                    // For Present status, set in_time
                    $attendance_record['in_time'] = $current_time;
                } else if ($status == 'A') {
                    // For Absent status, set out_time
                    $attendance_record['out_time'] = $current_time;
                }
                
                if ($query->num_rows() > 0) {
                    // Update existing record
                    $this->db->where('id', $query->row()->id);
                    $this->db->update('staff_attendance', $attendance_record);
                    $message = 'Attendance updated successfully';
                } else {
                    // Insert new record
                    $this->db->insert('staff_attendance', $attendance_record);
                    $message = 'Attendance marked successfully';
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'teacher_id' => $teacher_id,
                        'branch_id' => $branch_id,
                        'date' => $date,
                        'status' => $status,
                        'in_time' => isset($attendance_record['in_time']) ? $attendance_record['in_time'] : null,
                        'out_time' => isset($attendance_record['out_time']) ? $attendance_record['out_time'] : null,
                        'remark' => $remark
                    ),
                    'message' => $message
                );
                http_response_code(200);
                
            } elseif ($action == 'get') {
                // Get teacher's attendance records
                $date = $this->input->post('date');
                $start_date = $this->input->post('start_date');
                $end_date = $this->input->post('end_date');
                
                $this->db->select('date, status, in_time, out_time, remark');
                $this->db->from('staff_attendance');
                $this->db->where('staff_id', $teacher_id);
                $this->db->where('branch_id', $branch_id); // Filter by branch_id
                
                if (!empty($date)) {
                    // Get specific date
                    $this->db->where('date', $date);
                } elseif (!empty($start_date) && !empty($end_date)) {
                    // Get date range
                    $this->db->where('date >=', $start_date);
                    $this->db->where('date <=', $end_date);
                } else {
                    // Get today's attendance by default
                    $this->db->where('date', date('Y-m-d'));
                }
                
                $this->db->order_by('date', 'DESC');
                $query = $this->db->get();
                $attendance_records = $query->result_array();
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'teacher_id' => $teacher_id,
                        'branch_id' => $branch_id,
                        'records' => $attendance_records
                    ),
                    'message' => 'Attendance records retrieved successfully'
                );
                http_response_code(200);
                
            } else {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Invalid action. Use "mark" or "get"'
                );
                http_response_code(400);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Attendance operation failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get Present Days Count for Teacher
     * Returns the count of days the teacher was marked as Present
     */
    public function teacherPresentDaysCount()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $teacher_id = get_loggedin_user_id();
        
        try {
            // Build query to count present days
            $this->db->from('staff_attendance');
            $this->db->where('staff_id', $teacher_id);
            $this->db->where('status', 'P');
            
            $present_count = $this->db->count_all_results();
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'teacher_id' => $teacher_id,
                    'present_days_count' => $present_count,
                ),
                'message' => 'Present days count retrieved successfully'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve present days count: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get Absent Days Count for Teacher
     * Returns the count of days the teacher was marked as Absent
     */
    public function teacherAbsentDaysCount()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $teacher_id = get_loggedin_user_id();
        
        try {
            // Build query to count absent days
            $this->db->from('staff_attendance');
            $this->db->where('staff_id', $teacher_id);
            $this->db->where('status', 'A'); // Only count Absent days
            
            
            $absent_count = $this->db->count_all_results();
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'teacher_id' => $teacher_id,
                    'absent_days_count' => $absent_count,
                ),
                'message' => 'Absent days count retrieved successfully'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve absent days count: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Role 3 (Teacher) Profile
     * Gets teacher profile information
     */
    public function teacherProfile()
    {
        header('Content-Type: application/json');
        
        // For public access, we need to check authentication manually
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        try {
            $teacher_id = get_loggedin_user_id();
            
            // Load employee model
            $this->load->model('employee_model');
            
            // Get teacher profile data
            $profile_data = $this->employee_model->getSingleStaff($teacher_id);
            
            if (empty($profile_data)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Teacher profile not found'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // Format the response data
            $formatted_data = array(
                'id' => $profile_data['id'],
                'staff_id' => $profile_data['staff_id'],
                'name' => $profile_data['name'],
                'email' => $profile_data['email'],
                'mobile_no' => $profile_data['mobileno'],
                'sex' => $profile_data['sex'],
                'religion' => $profile_data['religion'],
                'blood_group' => $profile_data['blood_group'],
                'birthday' => $profile_data['birthday'],
                'present_address' => $profile_data['present_address'],
                'permanent_address' => $profile_data['permanent_address'],
                'photo' => $profile_data['photo'],
                'designation' => $profile_data['designation_name'],
                'department' => $profile_data['department_name'],
                'joining_date' => $profile_data['joining_date'],
                'qualification' => $profile_data['qualification'],
                'experience_details' => $profile_data['experience_details'],
                'total_experience' => $profile_data['total_experience'],
                'facebook_url' => $profile_data['facebook_url'],
                'linkedin_url' => $profile_data['linkedin_url'],
                'twitter_url' => $profile_data['twitter_url'],
                'username' => $profile_data['username'],
                'role' => $profile_data['role'],
                'active' => $profile_data['active'] ? true : false
            );
            
            $response = array(
                'status' => 'success',
                'data' => $formatted_data,
                'message' => 'Teacher profile retrieved successfully'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve teacher profile: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get School Name and URL from Custom Domain
     * Retrieves school name and URL information from the custom_domain table
     */
    public function getSchoolInfo()
    {
        header('Content-Type: application/json');
        
        try {
            // Check if custom_domain table exists
            if (!$this->db->table_exists('custom_domain')) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Custom domain table does not exist'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // Query the custom_domain table to get all approved domains
            $this->db->select('cd.school_id, cd.url, b.name as school_name');
            $this->db->from('custom_domain as cd');
            $this->db->join('branch as b', 'b.id = cd.school_id', 'inner');
            $this->db->where('cd.status', 1); // Only approved domains
            $query = $this->db->get();
            
            if ($query->num_rows() > 0) {
                $results = $query->result();
                
                // Format the data
                $schools = array();
                foreach ($results as $row) {
                    $schools[] = array(
                        'school_id' => $row->school_id,
                        'school_name' => $row->school_name,
                        'url' => $row->url
                    );
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => $schools,
                    'message' => 'School information retrieved successfully'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'success',
                    'data' => array(),
                    'message' => 'No approved schools found in custom domain table'
                );
                http_response_code(200);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve school information: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get Class List
     * Retrieves list of classes for the current branch
     */
    public function getClassList()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        try {
            $branch_id = $this->application_model->get_branch_id();
            
            // Load App_lib to get class list
            $this->load->library('app_lib');
            
            // Get class list for the branch
            $classList = $this->app_lib->getClass($branch_id, false);
            
            if (!empty($classList)) {
                $classes = array();
                foreach ($classList as $class_id => $class_name) {
                    $classes[] = array(
                        'class_id' => $class_id,
                        'class_name' => $class_name
                    );
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => $classes,
                    'message' => 'Class list retrieved successfully'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'success',
                    'data' => array(),
                    'message' => 'No classes found for this branch'
                );
                http_response_code(200);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve class list: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get Section List by Class
     * Retrieves list of sections for a given class
     */
    public function getSectionListByClass()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $class_id = $this->input->post('class_id');
        
        if (empty($class_id)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Class ID is required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        try {
            // Load App_lib to get section list
            $this->load->library('app_lib');
            
            // Get section list for the class
            $sectionList = $this->app_lib->getSections($class_id, false, false);
            
            if (!empty($sectionList)) {
                $sections = array();
                foreach ($sectionList as $section_id => $section_name) {
                    // Skip the empty option
                    if (!empty($section_id)) {
                        $sections[] = array(
                            'section_id' => $section_id,
                            'section_name' => $section_name
                        );
                    }
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => $sections,
                    'message' => 'Section list retrieved successfully'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'success',
                    'data' => array(),
                    'message' => 'No sections found for this class'
                );
                http_response_code(200);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve section list: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Get Student List by Class, Section, and Date
     * Retrieves list of students for a given class, section, and date
     */
    public function getStudentList()
    {
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            return;
        }
        
        $class_id = $this->input->post('class_id');
        $section_id = $this->input->post('section_id');
        $date = $this->input->post('date');
        
        // Validate required parameters
        if (empty($class_id) || empty($section_id)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Class ID and Section ID are required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        // If date is not provided, use today's date
        if (empty($date)) {
            $date = date('Y-m-d');
        }
        
        try {
            $branch_id = $this->application_model->get_branch_id();
            
            // Load Multiclass_model to get student list
            $this->load->model('multiclass_model');
            
            // Get student list for the class and section
            $studentList = $this->multiclass_model->getStudentListByClassSection($class_id, $section_id, $branch_id);
            
            if (!empty($studentList)) {
                // Add attendance status for each student
                $students = array();
                foreach ($studentList as $student) {
                    // Check if student has attendance record for the given date
                    $this->db->select('id, status, remark');
                    $this->db->from('student_attendance');
                    $this->db->where('enroll_id', $student['id']);
                    $this->db->where('date', $date);
                    $attendance_query = $this->db->get();
                    
                    $attendance_status = '';
                    $attendance_remark = '';
                    if ($attendance_query->num_rows() > 0) {
                        $attendance_record = $attendance_query->row();
                        $attendance_status = $attendance_record->status;
                        $attendance_remark = $attendance_record->remark;
                    }
                    
                    $students[] = array(
                        'enroll_id' => $student['id'],
                        'student_id' => $student['student_id'],
                        'name' => $student['fullname'],
                        'register_no' => $student['register_no'],
                        'roll' => $student['roll'],
                        'photo' => $student['photo'],
                        'gender' => $student['gender'],
                        'attendance_status' => $attendance_status,
                        'attendance_remark' => $attendance_remark
                    );
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => $students,
                    'message' => 'Student list retrieved successfully'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'success',
                    'data' => array(),
                    'message' => 'No students found for this class and section'
                );
                http_response_code(200);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve student list: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Student Attendance
     * Gets or sets student attendance records
     */
    public function studentAttendance()
    {
        
        
        header('Content-Type: application/json');
    
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            exit;
        }
        
        $action = $this->input->post('action'); // get or set
        $teacher_id = get_loggedin_user_id();
        
        try {
            if ($action == 'get') {
                // Get attendance data
                $date = $this->input->post('date');
                $class_id = $this->input->post('class_id');
                $section_id = $this->input->post('section_id');
                $branch_id = $this->application_model->get_branch_id();
                
                // Date is optional, use today if not provided
                if (empty($date)) {
                    $date = date('Y-m-d');
                }
                
                if (empty($class_id) || empty($section_id)) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Class ID and Section ID are required'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    exit;
                }
                
                // Load Multiclass_model to get student list
                $this->load->model('multiclass_model');
                
                // Get student list for the class and section
                $studentList = $this->multiclass_model->getStudentListByClassSection($class_id, $section_id, $branch_id);
                
                if (!empty($studentList)) {
                    // Add attendance status for each student
                    $students = array();
                    foreach ($studentList as $student) {
                        // Check if student has attendance record for the given date
                        $this->db->select('id, status, remark');
                        $this->db->from('student_attendance');
                        $this->db->where('enroll_id', $student['id']);
                        $this->db->where('date', $date);
                        $attendance_query = $this->db->get();
                        
                        $attendance_status = '';
                        $attendance_remark = '';
                        if ($attendance_query->num_rows() > 0) {
                            $attendance_record = $attendance_query->row();
                            $attendance_status = $attendance_record->status;
                            $attendance_remark = $attendance_record->remark;
                        }
                        
                        $students[] = array(
                            'enroll_id' => $student['id'],
                            'student_id' => $student['student_id'],
                            'name' => $student['fullname'],
                            'register_no' => $student['register_no'],
                            'roll' => $student['roll'],
                            'photo' => $student['photo'],
                            'gender' => $student['gender'],
                            'attendance_status' => $attendance_status,
                            'attendance_remark' => $attendance_remark
                        );
                    }
                    
                    $response = array(
                        'status' => 'success',
                        'data' => array(
                            'date' => $date,
                            'class_id' => $class_id,
                            'section_id' => $section_id,
                            'students' => $students
                        ),
                        'message' => 'Student attendance data retrieved successfully'
                    );
                    http_response_code(200);
                } else {
                    $response = array(
                        'status' => 'success',
                        'data' => array(
                            'date' => $date,
                            'class_id' => $class_id,
                            'section_id' => $section_id,
                            'students' => array()
                        ),
                        'message' => 'No students found for this class and section'
                    );
                    http_response_code(200);
                }
                
            } elseif ($action == 'set') {
                // Set attendance data for a single student
                $enroll_id = $this->input->post('enroll_id');
                $status = $this->input->post('status');
                $date = $this->input->post('date');
                $remark = $this->input->post('remark');
                
                // Date is optional, use today if not provided
                if (empty($date)) {
                    $date = date('Y-m-d');
                }
                
                // Validate required parameters
                if (empty($enroll_id) || empty($status)) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Enroll ID and Status are required'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    exit;
                }
                
                if (!in_array($status, array('P', 'A', 'H', 'L'))) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Status must be P (Present), A (Absent), H (Half Day), or L (Late)'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    exit;
                }
                
                $branch_id = $this->application_model->get_branch_id();
                
                $this->db->select('id');
                $this->db->from('student_attendance');
                $this->db->where('enroll_id', $enroll_id);
                $this->db->where('date', $date);
                $query = $this->db->get();
                
                $attendance_record = array(
                    'enroll_id' => $enroll_id,
                    'date' => $date,
                    'status' => $status,
                    'remark' => $remark,
                    'branch_id' => $branch_id,
                    'qr_code' => 0
                );
                
                if ($query->num_rows() > 0) {
                    $this->db->where('id', $query->row()->id);
                    $this->db->update('student_attendance', $attendance_record);
                    $message = 'Attendance updated successfully';
                } else {
                    $this->db->insert('student_attendance', $attendance_record);
                    $message = 'Attendance marked successfully';
                }
                
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'enroll_id' => $enroll_id,
                        'date' => $date,
                        'status' => $status,
                        'remark' => $remark
                    ),
                    'message' => $message
                );
                http_response_code(200);
                
            } else {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Invalid action. Use "get" or "set"'
                );
                http_response_code(400);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Attendance operation failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
        exit;
    }
    
    /**
     * API: Staff QR Code Attendance
     * Marks attendance for staff using QR code
     */
    public function staffQrAttendance()
    {
        // Clear any previous output
        if (ob_get_level()) {
            ob_clean();
        }
        
        header('Content-Type: application/json');
        
        // Check authentication
        if (!is_loggedin() || loggedin_role_id() != 3) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Unauthorized access. Teacher login required.'
            );
            http_response_code(401);
            echo json_encode($response);
            exit;
        }
        
        // Get the raw input data
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        if (empty($data)) {
            $staff_id = $this->input->post('staff_id');
            $in_out_time = $this->input->post('in_out_time');
            $remark = $this->input->post('remark');
        } else {
            // Get from JSON data
            $staff_id = isset($data['staff_id']) ? $data['staff_id'] : '';
            $in_out_time = isset($data['in_out_time']) ? $data['in_out_time'] : '';
            $remark = isset($data['remark']) ? $data['remark'] : '';
        }
        
        // Validate required parameters
        if (empty($staff_id) || empty($in_out_time)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Staff ID and in/out time are required'
            );
            http_response_code(400);
            echo json_encode($response);
            exit;
        }
        
        // Validate in_out_time value
        if (!in_array($in_out_time, array('in_time', 'out_time'))) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'In/out time must be either "in_time" or "out_time"'
            );
            http_response_code(400);
            echo json_encode($response);
            exit;
        }
        
        try {
            // Load required models
            $this->load->model('qrcode_attendance_model');
            
            // Get staff details
            $staff_detail = $this->qrcode_attendance_model->getSingleStaff($staff_id);
            if (empty($staff_detail)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Staff not found'
                );
                http_response_code(404);
                echo json_encode($response);
                exit;
            }
            
            // Check if attendance record already exists for today
            $attendance = $this->db->where(array('staff_id' => $staff_id, 'date' => date('Y-m-d')))->get('staff_attendance')->row();
            
            // Check if attendance has already been taken
            if (!empty($attendance)) {
                if (($in_out_time == 'in_time' && !empty($attendance->in_time)) || 
                    ($in_out_time == 'out_time' && !empty($attendance->out_time))) {
                    $response = array(
                        'status' => 'error',
                        'data' => array(),
                        'message' => 'Attendance has already been taken for this time period'
                    );
                    http_response_code(400);
                    echo json_encode($response);
                    exit;
                }
            }
            
            // Get QR code settings for the branch
            $setting = $this->qrcode_attendance_model->getSettings(empty($staff_detail->branch_id) ? 0 : $staff_detail->branch_id);
            
            // Determine attendance status based on settings
            $attendance_status = '';
            if ($in_out_time == 'in_time') {
                if ($setting->auto_late_detect == 1) {
                    if (strtotime($setting->staff_in_time) <= time()) {
                        $attendance_status = 'L'; // Late
                    } else {
                        $attendance_status = 'P'; // Present
                    }
                } else {
                    $attendance_status = 'P'; // Present by default
                }
            } else {
                if ($setting->auto_late_detect == 1) {
                    if (strtotime($setting->staff_out_time) >= time()) {
                        $attendance_status = 'HD'; // Half Day
                    }
                }
            }
            
            if (empty($attendance)) {
                // Insert new attendance record
                $array_attendance = array(
                    'staff_id' => $staff_id,
                    'status' => $attendance_status,
                    'remark' => $remark ? $remark : '',
                    'qr_code' => 1, // Tinyint format
                    'date' => date('Y-m-d'),
                    'branch_id' => $staff_detail->branch_id,
                );
                $array_attendance[$in_out_time] = date('H:i:s');
                $this->db->insert('staff_attendance', $array_attendance);
                $message = 'Attendance marked successfully';
            } else {
                // Update existing attendance record
                $update_data = array();
                $update_data[$in_out_time] = date('H:i:s');
                if (!empty($remark)) {
                    $update_data['remark'] = $remark;
                }
                if (!empty($attendance_status)) {
                    $update_data['status'] = $attendance_status;
                }
                $this->db->where('id', $attendance->id);
                $this->db->update('staff_attendance', $update_data);
                $message = 'Attendance updated successfully';
            }
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'staff_id' => $staff_id,
                    'date' => date('Y-m-d'),
                    'time' => date('H:i:s'),
                    'in_out_time' => $in_out_time,
                    'status' => $attendance_status,
                    'remark' => $remark
                ),
                'message' => $message
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Attendance operation failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
        exit;
    }
}
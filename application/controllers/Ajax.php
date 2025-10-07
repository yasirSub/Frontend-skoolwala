<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * @package : Ramom School Management System
 * @version : 6.5
 * @developed by : RamomCoder
 * @support : ramomcoder@yahoo.com
 * @author url : http://codecanyon.net/user/RamomCoder
 * @filename : Ajax.php
 */

class Ajax extends MY_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->model('ajax_model');
        $this->load->model('home_model');
    }
    
    /**
     * API: Get list of schools for dropdown selection
     * Returns JSON response with school list
     */
    public function getSchoolList()
    {
        header('Content-Type: application/json');
        
        try {
            $school_list = $this->home_model->branch_list();
            if (!empty($school_list)) {
                $response = array(
                    'status' => 'success',
                    'data' => $school_list,
                    'message' => 'Schools retrieved successfully'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'No schools available'
                );
                http_response_code(404);
            }
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve schools: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }   
    
    /**
     * API: Get school details by ID
     * Returns JSON response with school information including logo
     */
    public function getSchoolDetails()
    {
        header('Content-Type: application/json');
        
        $school_id = $this->input->post('school_id');
        if (empty($school_id)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'School ID is required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        try {
            // Get school basic information
            $school = $this->db->select('id, school_name, address, email, mobileno, status')
                              ->get_where('branch', array('id' => $school_id, 'status' => 1))
                              ->row();
            
            if (empty($school)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'School not found or inactive'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // Get school logo URL
            $logo_url = $this->application_model->getBranchImage($school_id, 'logo');
            
            // Get URL alias for redirect
            $cms_setting = $this->db->select('url_alias')
                                   ->get_where('front_cms_setting', array('branch_id' => $school_id))
                                   ->row();
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'id' => $school->id,
                    'school_name' => $school->school_name,
                    'address' => $school->address,
                    'email' => $school->email,
                    'phone' => $school->mobileno,
                    'logo_url' => $logo_url,
                    'url_alias' => !empty($cms_setting) ? $cms_setting->url_alias : null,
                    'login_url' => !empty($cms_setting) && !empty($cms_setting->url_alias) 
                                  ? base_url($cms_setting->url_alias) 
                                  : base_url('authentication/index/' . $school_id)
                ),
                'message' => 'School details retrieved successfully'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to retrieve school details: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }
    
    /**
     * API: Validate employee school access
     * Checks if employee belongs to selected school
     */
    public function validateEmployeeSchool()
    {
        header('Content-Type: application/json');
        
        $username = $this->input->post('username');
        $school_id = $this->input->post('school_id');
        
        if (empty($username) || empty($school_id)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Username and School ID are required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        try {
            // Get user credentials
            $login_credential = $this->db->select('*')
                                        ->get_where('login_credential', array('username' => $username))
                                        ->row();
            
            if (empty($login_credential)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'User not found'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // Get user's school based on role
            $user_school_id = null;
            
            if ($login_credential->role == 6) { // Parent
                $user = $this->db->select('branch_id')
                                ->get_where('parent', array('id' => $login_credential->user_id))
                                ->row();
                $user_school_id = !empty($user) ? $user->branch_id : null;
            } elseif ($login_credential->role == 7) { // Student
                $user = $this->db->select('enroll.branch_id')
                                ->from('enroll')
                                ->join('student', 'student.id = enroll.student_id', 'inner')
                                ->where('student.id', $login_credential->user_id)
                                ->limit(1)
                                ->get()
                                ->row();
                $user_school_id = !empty($user) ? $user->branch_id : null;
            } else { // Staff/Employee
                $user = $this->db->select('branch_id')
                                ->get_where('staff', array('id' => $login_credential->user_id))
                                ->row();
                $user_school_id = !empty($user) ? $user->branch_id : null;
            }
            
            if ($user_school_id == $school_id) {
                $response = array(
                    'status' => 'success',
                    'data' => array(
                        'valid' => true,
                        'role' => $login_credential->role,
                        'school_id' => $user_school_id
                    ),
                    'message' => 'Employee has access to selected school'
                );
                http_response_code(200);
            } else {
                $response = array(
                    'status' => 'error',
                    'data' => array(
                        'valid' => false,
                        'user_school_id' => $user_school_id,
                        'selected_school_id' => $school_id
                    ),
                    'message' => 'Employee does not have access to selected school'
                );
                http_response_code(403);
            }
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Validation failed: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    /**
     * API: Set selected school in session
     * Stores school selection for login redirect
     */
    public function setSelectedSchool()
    {
        header('Content-Type: application/json');
        
        $school_id = $this->input->post('school_id');
        
        if (empty($school_id)) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'School ID is required'
            );
            http_response_code(400);
            echo json_encode($response);
            return;
        }
        
        try {
            // Validate school exists and is active
            $school = $this->db->select('id, school_name')
                              ->get_where('branch', array('id' => $school_id, 'status' => 1))
                              ->row();
            
            if (empty($school)) {
                $response = array(
                    'status' => 'error',
                    'data' => array(),
                    'message' => 'Invalid or inactive school'
                );
                http_response_code(404);
                echo json_encode($response);
                return;
            }
            
            // Store in session
            $this->session->set_userdata('selected_school_id', $school_id);
            
            $response = array(
                'status' => 'success',
                'data' => array(
                    'school_id' => $school_id,
                    'school_name' => $school->school_name
                ),
                'message' => 'School selection saved successfully'
            );
            http_response_code(200);
            
        } catch (Exception $e) {
            $response = array(
                'status' => 'error',
                'data' => array(),
                'message' => 'Failed to save school selection: ' . $e->getMessage()
            );
            http_response_code(500);
        }
        
        echo json_encode($response);
    }

    // get exam list based on the branch
    public function getExamByBranch()
    {
        $html = "";
        $branchID = $this->application_model->get_branch_id();
        if (!empty($branchID)) {
            $this->db->select('id,name,term_id');
            $this->db->where(array('branch_id' => $branchID, 'session_id' => get_session_id()));
            $result = $this->db->get('exam')->result_array();
            if (count($result)) {
                $html .= '<option value="">' . translate('select') . '</option>';
                foreach ($result as $row) {
                    if ($row['term_id'] != 0) {
                        $term = $this->db->select('name')->where('id', $row['term_id'])->get('exam_term')->row()->name;
                        $name = $row['name'] . ' (' . $term . ')';
                    } else {
                        $name = $row['name'];
                    }
                    $html .= '<option value="' . $row['id'] . '">' . $name . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_branch_first') . '</option>';
        }
        echo $html;
    }

    // get class assign modal
    public function getClassAssignM()
    {
        $classID = $this->input->post('class_id');
        $sectionID = $this->input->post('section_id');
        $branchID = get_type_name_by_id('class', $classID, 'branch_id');
        $html = "";
        $subjects = $this->db->get_where('subject', array('branch_id' => $branchID))->result_array();
        if (count($subjects)) {
            foreach ($subjects as $row) {
                $query_assign = $this->db->get_where("subject_assign", array(
                    'class_id' => $classID,
                    'section_id' => $sectionID,
                    'session_id' => get_session_id(),
                    'subject_id' => $row['id'],
                ));
                $html .= '<option value="' . $row['id'] . '"' . ($query_assign->num_rows() != 0 ? 'selected' : '') . '>' . $row['name'] . '</option>';
            }
        }
        $data['branch_id'] = $branchID;
        $data['class_id'] = $classID;
        $data['section_id'] = $sectionID;
        $data['subject'] = $html;
        echo json_encode($data);
    }

    public function getAdvanceSalaryDetails()
    {
        if (get_permission('advance_salary', 'is_add')) {
            $this->data['salary_id'] = $this->input->post('id');
            $this->load->view('advance_salary/approvel_modalView', $this->data);
        }
    }

    public function getLeaveCategoryDetails()
    {
        if (get_permission('leave_category', 'is_edit')) {
            $id = $this->input->post('id');
            $this->db->where('id', $id);
            $query = $this->db->get('leave_category');
            $result = $query->row_array();
            echo json_encode($result);
        }
    }

    public function getDataByBranch()
    {
        $html = "";
        $table = $this->input->post('table');
        $branch_id = $this->application_model->get_branch_id();
        if (!empty($branch_id)) {
            $result = $this->db->select('id,name')->where('branch_id', $branch_id)->get($table)->result_array();
            if (count($result)) {
                $html .= "<option value=''>" . translate('select') . "</option>";
                foreach ($result as $row) {
                    $html .= '<option value="' . $row['id'] . '">' . $row['name'] . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_branch_first') . '</option>';
        }
        echo $html;
    }

    public function getClassByBranch()
    {
        $html = "";
        $branch_id = $this->application_model->get_branch_id();
        if (!empty($branch_id)) {
            $classes = $this->db->select('id,name')->where('branch_id', $branch_id)->get('class')->result_array();
            if (count($classes)) {
                $html .= "<option value=''>" . translate('select') . "</option>";
                foreach ($classes as $row) {
                    $html .= '<option value="' . $row['id'] . '">' . $row['name'] . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_branch_first') . '</option>';
        }
        echo $html;
    }

    public function getStudentByClass($enroll = 0)
    {
        $html = "";
        $class_id = $this->input->post('class_id');
        $section_id = $this->input->post('section_id');
        $branch_id = $this->application_model->get_branch_id();
        $student_id = (isset($_POST['student_id']) ? $_POST['student_id'] : 0);
        if (!empty($class_id)) {
            $this->db->select('e.student_id,e.id,e.roll,CONCAT(s.first_name, " ", s.last_name) as fullname');
            $this->db->from('enroll as e');
            $this->db->join('student as s', 's.id = e.student_id', 'inner');
            $this->db->join('login_credential as l', 'l.user_id = e.student_id and l.role = 7', 'left');
            $this->db->where('l.active', 1);
            $this->db->where('e.session_id', get_session_id());
            if (!empty($section_id)) {
                $this->db->where('e.section_id', $section_id);
            }
            $this->db->where('e.class_id', $class_id);
            $this->db->where('e.branch_id', $branch_id);
            $result = $this->db->get()->result_array();
            if (count($result)) {
                $html .= "<option value=''>" . translate('select') . "</option>";
                foreach ($result as $row) {
                    if ($enroll == 0) {
                        $sel = ($row['student_id']  == $student_id ? 'selected' : '');
                        $html .= '<option value="' . $row['student_id'] . '"' . $sel . '>' . $row['fullname'] . ' ( Roll : ' . $row['roll'] . ')</option>';
                    } else {
                        $sel = ($row['id']  == $student_id ? 'selected' : '');
                        $html .= '<option value="' . $row['id'] . '"' . $sel . '>' . $row['fullname'] . ' (' . translate('roll') . " : " . $row['roll'] . ')</option>';
                    }
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_class_first') . '</option>';
        }
        echo $html;
    }

    // get section list based on the class
    public function getSectionByClass()
    {
        $html = "";
        $classID = $this->input->post("class_id");
        $mode = $this->input->post("all");
        $multi = $this->input->post("multi");
        if (!empty($classID)) {
            $getClassTeacher = $this->app_lib->getClassTeacher($classID);
            if (is_array($getClassTeacher)) {
                $result = $getClassTeacher;
                if (count($result) == 0) {
                    $this->db->select('timetable_class.section_id,section.name as section_name');
                    $this->db->from('timetable_class');
                    $this->db->join('section', 'section.id = timetable_class.section_id', 'left');
                    $this->db->where(array('timetable_class.teacher_id' => get_loggedin_user_id(), 'timetable_class.session_id' => get_session_id(), 'timetable_class.class_id' => $classID));
                    $this->db->group_by('timetable_class.section_id'); 
                    $result = $this->db->get()->result_array();
                }
            } else {
                $result = $this->db->select('sections_allocation.section_id,section.name as section_name')
                    ->from('sections_allocation')
                    ->join('section', 'section.id = sections_allocation.section_id', 'left')
                    ->where('sections_allocation.class_id', $classID)
                    ->get()->result_array();
            }
            if (count($result)) {
                if ($multi == false) {
                   $html .= '<option value="">' . translate('select') . '</option>';
                }
                if ($mode == true && !is_array($getClassTeacher)) {
                    $html .= '<option value="all">' . translate('all_sections') . '</option>';
                }
                foreach ($result as $row) {
                    $html .= '<option value="' . $row['section_id'] . '">' . $row['section_name'] . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_selection_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_class_first') . '</option>';
        }
        echo $html;
    }

    public function getStafflistRole()
    {
        $html = "";
        $branch_id = $this->application_model->get_branch_id();
        if (!empty($branch_id)) {
            $role_id = $this->input->post('role_id');
            $selected_id = (isset($_POST['staff_id']) ? $_POST['staff_id'] : 0);
            $this->db->select('staff.id,staff.name,staff.staff_id,lc.role');
            $this->db->from('staff');
            $this->db->join('login_credential as lc', 'lc.user_id = staff.id AND lc.role != 6 AND lc.role != 7', 'inner');
            if (!empty($role_id)) {
                $this->db->where('lc.role', $role_id);
            }
            $this->db->where('staff.branch_id', $branch_id);
            $this->db->order_by('staff.id', 'asc');
            $result = $this->db->get()->result_array();
            if (count($result)) {
                $html .= "<option value=''>" . translate('select') . "</option>";
                foreach ($result as $staff) {
                    $selected = ($staff['id'] == $selected_id ? 'selected' : '');
                    $html .= "<option value='" . $staff['id'] . "' " . $selected . ">" . $staff['name'] . " (" . $staff['staff_id'] . ")</option>";
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_branch_first') . '</option>';
        }
        echo $html;
    }

    // get staff all details
    public function getEmployeeList()
    {
        $html = "";
        $role_id = $this->input->post('role');
        $designation = $this->input->post('designation');
        $department = $this->input->post('department');
        $selected_id = (isset($_POST['staff_id']) ? $_POST['staff_id'] : 0);
        $this->db->select('staff.*,staff_designation.name as des_name,staff_department.name as dep_name,login_credential.role as role_id, roles.name as role');
        $this->db->from('staff');
        $this->db->join('login_credential', 'login_credential.user_id = staff.id', 'inner');
        $this->db->join('roles', 'roles.id = login_credential.role', 'left');
        $this->db->join('staff_designation', 'staff_designation.id = staff.designation', 'left');
        $this->db->join('staff_department', 'staff_department.id = staff.department', 'left');
        $this->db->where('login_credential.role', $role_id);
        $this->db->where('login_credential.active', 1);
        if ($designation != '') {
            $this->db->where('staff.designation', $designation);
        }

        if ($department != '') {
            $this->db->where('staff.department', $department);
        }

        $result = $this->db->get()->result_array();
        if (count($result)) {
            $html .= "<option value=''>" . translate('select') . "</option>";
            foreach ($result as $row) {
                $selected = ($row['id'] == $selected_id ? 'selected' : '');
                $html .= "<option value='" . $row['id'] . "' " . $selected . ">" . $row['name'] . " (" . $row['staff_id'] . ")</option>";
            }
        } else {
            $html .= '<option value="">' . translate('no_information_available') . '</option>';
        }
        echo $html;
    }

    // get subject list based on the class
    public function getSubjectByClass()
    {
        $html = "";
        $classID = $this->input->post('classID');
        if (!empty($classID)) {
            $this->db->select('subject_assign.subject_id,subject.name,subject.subject_code');
            $this->db->from('subject_assign');
            $this->db->join('subject', 'subject.id = subject_assign.subject_id', 'left');
            $this->db->where('subject_assign.class_id', $classID);
            if (!is_superadmin_loggedin()) {
                $this->db->where('subject_assign.branch_id', get_loggedin_branch_id());
            }
            $subjects = $this->db->get()->result_array();
            if (count($subjects)) {
                $html .= '<option value="">' . translate('select') . '</option>';
                foreach ($subjects as $row) {
                    $html .= '<option value="' . $row['subject_id'] . '">' . $row['name'] . ' (' . $row['subject_code'] . ')</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_information_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('select_class_first') . '</option>';
        }
        echo $html;
    }

    public function get_salary_template_details()
    {
        if (get_permission('salary_template', 'is_view')) {
            $template_id = $this->input->post('id');
            $this->data['allowances'] = $this->ajax_model->get('salary_template_details', array('type' => 1, 'salary_template_id' => $template_id));
            $this->data['deductions'] = $this->ajax_model->get('salary_template_details', array('type' => 2, 'salary_template_id' => $template_id));
            $this->data['template'] = $this->ajax_model->get('salary_template', array('id' => $template_id), true);
            $this->load->view('payroll/qview_salary_templete', $this->data);
        }
    }

    public function department_details()
    {
        if (get_permission('department', 'is_edit')) {
            $id = $this->input->post('id');
            $this->db->where('id', $id);
            $query = $this->db->get('staff_department');
            $result = $query->row_array();
            echo json_encode($result);
        }
    }

    public function designation_details()
    {
    if (get_permission('designation', 'is_edit')) {
            $id = $this->input->post('id');
            $this->db->where('id', $id);
            $query = $this->db->get('staff_designation');
            $result = $query->row_array();
            echo json_encode($result);
        }
    }

    public function getLoginAuto()
    {
        if (is_superadmin_loggedin()) {
            $getBranch = $this->getBranchDetails();
            $data = array();
            if ($getBranch['stu_generate'] == 1) {
               $data['student'] = 1;
            } else {
                $data['student'] = 0;
            }

            if ($getBranch['grd_generate'] == 1) {
                $data['guardian'] = 1;
            } else {
                $data['guardian'] = 0;
            }
            echo json_encode($data);
        }
    }

    public function getProductCategoryDetails()
    {
        if (get_permission('product_category', 'is_edit')) {
            $id = $this->input->post('id');
            $this->db->where('id', $id);
            $query = $this->db->get('product_category');
            $result = $query->row_array();
            echo json_encode($result);
        }
    }

    public function teacherLogin()
    {
        echo 'here';
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
        
        $action = $this->input->post('action'); // get or save
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
}
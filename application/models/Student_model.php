<?php
if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class Student_model extends MY_Model
{

    public function __construct()
    {
        parent::__construct();
    }

    // moderator student all information
    public function save($data = array(), $getBranch = array())
    {
        $hostelID = empty($data['hostel_id']) ? 0 : $data['hostel_id'];
        $roomID = empty($data['room_id']) ? 0 : $data['room_id'];

        $previous_details = array(
            'school_name' => $this->input->post('school_name'),
            'qualification' => $this->input->post('qualification'),
            'remarks' => $this->input->post('previous_remarks'),
        );
        if (empty($previous_details)) {
            $previous_details = "";
        } else {
            $previous_details = json_encode($previous_details);
        }

        $inser_data1 = array(
            'register_no' => $this->input->post('register_no'),
            'admission_date' => (!empty($data['admission_date']) ? date("Y-m-d", strtotime($data['admission_date'])) : ""),
            'first_name' => $this->input->post('first_name'),
            'last_name' => $this->input->post('last_name'),
            'gender' => $this->input->post('gender'),
            'birthday' => (!empty($data['birthday']) ? date("Y-m-d", strtotime($data['birthday'])) : ""),
            'religion' => $this->input->post('religion'),
            'caste' => $this->input->post('caste'),
            'blood_group' => $this->input->post('blood_group'),
            'mother_tongue' => $this->input->post('mother_tongue'),
            'current_address' => $this->input->post('current_address'),
            'permanent_address' => $this->input->post('permanent_address'),
            'city' => $this->input->post('city'),
            'state' => $this->input->post('state'),
            'mobileno' => $this->input->post('mobileno'),
            'category_id' => (isset($data['category_id']) ? $data['category_id'] : 0),
            'email' => $this->input->post('email'),
            'parent_id' => $this->input->post('parent_id'),
            'route_id' => (empty($this->input->post('route_id')) ? 0 : $this->input->post('route_id')),
            'vehicle_id' => (empty($this->input->post('vehicle_id')) ? 0 : $this->input->post('vehicle_id')),
            'stoppage_point_id' => (empty($this->input->post('stoppage_point_id')) ? null : $this->input->post('stoppage_point_id')),
            'hostel_id' => $hostelID,
            'room_id' => $roomID,
            'previous_details' => $previous_details,
            'photo' => $this->uploadImage('student'),
        );

        // moderator guardian all information
        if (!isset($data['student_id']) && empty($data['student_id'])) {
            if (!isset($data['guardian_chk'])) {
                // add new guardian all information in db
                if (!empty($data['grd_name']) || !empty($data['father_name'])) {
                    $arrayParent = array(
                        'name' => $this->input->post('grd_name'),
                        'relation' => $this->input->post('grd_relation'),
                        'father_name' => $this->input->post('father_name'),
                        'mother_name' => $this->input->post('mother_name'),
                        'occupation' => $this->input->post('grd_occupation'),
                        'income' => $this->input->post('grd_income'),
                        'education' => $this->input->post('grd_education'),
                        'email' => $this->input->post('grd_email'),
                        'mobileno' => $this->input->post('grd_mobileno'),
                        'address' => $this->input->post('grd_address'),
                        'city' => $this->input->post('grd_city'),
                        'state' => $this->input->post('grd_state'),
                        'branch_id' => $this->application_model->get_branch_id(),
                        'photo' => $this->uploadImage('parent', 'guardian_photo'),
                    );
                    $this->db->insert('parent', $arrayParent);
                    $parentID = $this->db->insert_id();

                    // save guardian login credential information in the database
                    if ($getBranch['grd_generate'] == 1) {
                        $grd_username = $getBranch['grd_username_prefix'] . $parentID;
                        $grd_password = $getBranch['grd_default_password'];
                    } else {
                        $grd_username = $data['grd_username'];
                        $grd_password = $data['grd_password'];
                    }
                    $parent_credential = array(
                        'username' => $grd_username,
                        'role' => 6,
                        'user_id' => $parentID,
                        'password' => $this->app_lib->pass_hashed($grd_password),
                    );
                    $this->db->insert('login_credential', $parent_credential);
                } else {
                    $parentID = 0;
                }
            } else {
                $parentID = $data['parent_id'];
            }

            $inser_data1['parent_id'] = $parentID;
            // insert student all information in the database
            $this->db->insert('student', $inser_data1);
            $student_id = $this->db->insert_id();

            // save student login credential information in the database
            if ($getBranch['stu_generate'] == 1) {
                $stu_username = $getBranch['stu_username_prefix'] . $student_id;
                $stu_password = $getBranch['stu_default_password'];
            } else {
                $stu_username = $data['username'];
                $stu_password = $data['password'];

            }
            $inser_data2 = array(
                'user_id' => $student_id,
                'username' => $stu_username,
                'role' => 7,
                'password' => $this->app_lib->pass_hashed($stu_password),
            );
            $this->db->insert('login_credential', $inser_data2);

            // return student information
            $studentData = array(
                'student_id' => $student_id,
                'email' => $this->input->post('email'),
                'username' => $stu_username,
                'password' => $stu_password,
            );

            if (!empty($data['grd_name']) || !empty($data['father_name'])) {
                // send parent account activate email
                $emailData = array(
                    'name' => $this->input->post('grd_name'),
                    'username' => $grd_username,
                    'password' => $grd_password,
                    'user_role' => 6,
                    'email' => $this->input->post('grd_email'),
                );
                $this->email_model->sentStaffRegisteredAccount($emailData);
            }
            return $studentData;
        } else {
            // update student all information in the database
            $inser_data1['parent_id'] = $data['parent_id'];
            $this->db->where('id', $data['student_id']);
            $this->db->update('student', $inser_data1);

            // update login credential information in the database
            $this->db->where('user_id', $data['student_id']);
            $this->db->where('role', 7);
            $this->db->update('login_credential', array('username' => $data['username']));
        }
    }

    public function csvImport($row = array(), $classID = '', $sectionID = '', $branchID = '')
    {
        // getting existing father data
        if ($row['GuardianUsername'] !== '') {
            $getParent = $this->db->select('parent.id')
                ->from('login_credential')->join('parent', 'parent.id = login_credential.user_id', 'left')
                ->where(array('parent.branch_id' => $branchID, 'login_credential.username' => $row['GuardianUsername']))
                ->get()->row_array();
        }

        // getting branch settings
        $getSettings = $this->db->select('*')
            ->where('id', $branchID)
            ->from('branch')
            ->get()->row_array();

        if (isset($getParent) && count($getParent)) {
            $parentID = $getParent['id'];
        } else {
            // add new guardian all information in db
            $arrayParent = array(
                'name' => $row['GuardianName'],
                'relation' => $row['GuardianRelation'],
                'father_name' => $row['FatherName'],
                'mother_name' => $row['MotherName'],
                'occupation' => $row['GuardianOccupation'],
                'mobileno' => $row['GuardianMobileNo'],
                'address' => $row['GuardianAddress'],
                'email' => $row['GuardianEmail'],
                'branch_id' => $branchID,
                'photo' => 'defualt.png',
            );
            $this->db->insert('parent', $arrayParent);
            $parentID = $this->db->insert_id();

            // save guardian login credential information in the database
            if ($getSettings['grd_generate'] == 1) {
                $grd_username = $getSettings['grd_username_prefix'] . $parentID;
                $grd_password = $getSettings['grd_default_password'];
            } else {
                $grd_username = $row['GuardianUsername'];
                $grd_password = $row['GuardianPassword'];
            }
            $parent_credential = array(
                'username' => $grd_username,
                'role' => 6,
                'user_id' => $parentID,
                'password' => $this->app_lib->pass_hashed($grd_password),
            );
            $this->db->insert('login_credential', $parent_credential);
        }

        $inser_data1 = array(
            'first_name' => $row['FirstName'],
            'last_name' => $row['LastName'],
            'blood_group' => $row['BloodGroup'],
            'gender' => $row['Gender'],
            'birthday' => date("Y-m-d", strtotime($row['Birthday'])),
            'mother_tongue' => $row['MotherTongue'],
            'religion' => $row['Religion'],
            'parent_id' => $parentID,
            'caste' => $row['Caste'],
            'mobileno' => $row['Phone'],
            'city' => $row['City'],
            'state' => $row['State'],
            'current_address' => $row['PresentAddress'],
            'permanent_address' => $row['PermanentAddress'],
            'category_id' => $row['CategoryID'],
            'admission_date' => date("Y-m-d", strtotime($row['AdmissionDate'])),
            'register_no' => $row['RegisterNo'],
            'photo' => 'defualt.png',
            'email' => $row['StudentEmail'],
        );

        //save all student information in the database file
        $this->db->insert('student', $inser_data1);
        $studentID = $this->db->insert_id();

        // save student login credential information in the database
        if ($getSettings['stu_generate'] == 1) {
            $stu_username = $getSettings['stu_username_prefix'] . $studentID;
            $stu_password = $getSettings['stu_default_password'];
        } else {
            $stu_username = $row['StudentUsername'];
            $stu_password = $row['StudentPassword'];
        }

        //save student login credential
        $inser_data2 = array(
            'username' => $stu_username,
            'role' => 7,
            'user_id' => $studentID,
            'password' => $this->app_lib->pass_hashed($stu_password),
        );
        $this->db->insert('login_credential', $inser_data2);

        //save student enroll information in the database file
        $arrayEnroll = array(
            'student_id' => $studentID,
            'class_id' => $classID,
            'section_id' => $sectionID,
            'branch_id' => $branchID,
            'roll' => $row['Roll'],
            'session_id' => get_session_id(),
        );
        $this->db->insert('enroll', $arrayEnroll);
    }

    public function getFeeProgress($id)
    {
        $this->db->select('IFNULL(SUM(gd.amount), 0) as totalfees,IFNULL(SUM(p.amount), 0) as totalpay,IFNULL(SUM(p.discount),0) as totaldiscount');
        $this->db->from('fee_allocation as a');
        $this->db->join('fee_groups_details as gd', 'gd.fee_groups_id = a.group_id', 'inner');
        $this->db->join('fee_payment_history as p', 'p.allocation_id = a.id and p.type_id = gd.fee_type_id', 'left');
        $this->db->where('a.student_id', $id);
        $this->db->where('a.session_id', get_session_id());
        $r = $this->db->get()->row_array();
        $total_amount = floatval($r['totalfees']);
        $total_paid = floatval($r['totalpay'] + $r['totaldiscount']);
        if ($total_paid != 0) {
            $percentage = ($total_paid / $total_amount) * 100;
            return number_format($percentage);
        } else {
            return 0;
        }
    }

    public function getStudentList($classID = '', $sectionID = '', $branchID = '', $deactivate = false, $start = '', $end = '')
    {
        $this->db->select('e.*,s.photo, CONCAT_WS(" ", s.first_name, s.last_name) as fullname,s.register_no,s.gender,s.admission_date,s.parent_id,s.email,s.blood_group,s.birthday,l.active,c.name as class_name,se.name as section_name');
        $this->db->from('enroll as e');
        $this->db->join('student as s', 'e.student_id = s.id', 'inner');
        $this->db->join('login_credential as l', 'l.user_id = s.id and l.role = 7', 'inner');
        $this->db->join('class as c', 'e.class_id = c.id', 'left');
        $this->db->join('section as se', 'e.section_id=se.id', 'left');
        if (!empty($classID)) {
            $this->db->where('e.class_id', $classID);
        }
        if (!empty($start) && !empty($end)) {
            $this->db->where('s.admission_date >=', $start);
            $this->db->where('s.admission_date <=', $end);
        }
        $this->db->where('e.branch_id', $branchID);
        $this->db->where('e.session_id', get_session_id());
        $this->db->order_by('s.id', 'ASC');
        if ($sectionID != 'all' && !empty($sectionID)) {
            $this->db->where('e.section_id', $sectionID);
        }
        if ($deactivate == true) {
            $this->db->where('l.active', 0);
        }
        return $this->db->get();
    }

    public function getSearchStudentList($search_text)
    {
        $this->db->select('e.*,s.photo,s.first_name,s.last_name,s.register_no,s.parent_id,s.email,s.blood_group,s.birthday,c.name as class_name,se.name as section_name,sp.name as parent_name');
        $this->db->from('enroll as e');
        $this->db->join('student as s', 'e.student_id = s.id', 'left');
        $this->db->join('class as c', 'e.class_id = c.id', 'left');
        $this->db->join('section as se', 'e.section_id=se.id', 'left');
        $this->db->join('parent as sp', 'sp.id = s.parent_id', 'left');
        $this->db->where('e.session_id', get_session_id());
        if (!is_superadmin_loggedin()) {
            $this->db->where('e.branch_id', get_loggedin_branch_id());
        }
        $this->db->group_start();
        $this->db->like('s.first_name', $search_text);
        $this->db->or_like('s.last_name', $search_text);
        $this->db->or_like('s.register_no', $search_text);
        $this->db->or_like('s.email', $search_text);
        $this->db->or_like('e.roll', $search_text);
        $this->db->or_like('s.blood_group', $search_text);
        $this->db->or_like('sp.name', $search_text);
        $this->db->group_end();
        $this->db->order_by('s.id', 'desc');
        return $this->db->get();
    }

    public function getSingleStudent($id = '', $enroll = false)
    {
        $this->db->select('s.*,l.username,l.active,e.class_id,e.section_id,e.id as enrollid,e.roll,e.branch_id,e.session_id,c.name as class_name,se.name as section_name,sc.name as category_name');
        $this->db->from('enroll as e');
        $this->db->join('student as s', 'e.student_id = s.id', 'left');
        $this->db->join('login_credential as l', 'l.user_id = s.id and l.role = 7', 'inner');
        $this->db->join('class as c', 'e.class_id = c.id', 'left');
        $this->db->join('section as se', 'e.section_id = se.id', 'left');
        $this->db->join('student_category as sc', 's.category_id=sc.id', 'left');
        if ($enroll == true) {
            $this->db->where('e.id', $id);
        } else {
            $this->db->where('s.id', $id);
        }
        $this->db->where('e.session_id', get_session_id());
        if (!is_superadmin_loggedin()) {
            $this->db->where('e.branch_id', get_loggedin_branch_id());
        }
        $query = $this->db->get();
        if ($query->num_rows() == 0) {
            show_404();
        }
        return $query->row_array();
    }

    public function regSerNumber($school_id = '')
    {
        $registerNoPrefix = '';
        if (!empty($school_id)) {
            $schoolconfig = $this->db->select('reg_prefix_enable,reg_start_from,institution_code,reg_prefix_digit')->where(array('id' => $school_id))->get('branch')->row();
            if ($schoolconfig->reg_prefix_enable == 1) {
                $registerNoPrefix = $schoolconfig->institution_code . $schoolconfig->reg_start_from;
                $last_registerNo = $this->app_lib->studentLastRegID($school_id);
                if (!empty($last_registerNo)) {
                    $last_registerNo_digit = str_replace($schoolconfig->institution_code, "", $last_registerNo->register_no);
                    if (!is_numeric($last_registerNo_digit)) {
                        $last_registerNo_digit = $schoolconfig->reg_start_from;
                    } else {
                        $last_registerNo_digit = $last_registerNo_digit + 1;
                    }
                    $registerNoPrefix = $schoolconfig->institution_code . sprintf("%0" . $schoolconfig->reg_prefix_digit . "d", $last_registerNo_digit);
                } else {
                    $registerNoPrefix = $schoolconfig->institution_code . sprintf("%0" . $schoolconfig->reg_prefix_digit . "d", $schoolconfig->reg_start_from);
                }
            }
            return $registerNoPrefix;
        } else {
            $config = $this->db->select('institution_code,reg_prefix')->where(array('id' => 1))->get('global_settings')->row();
            if ($config->reg_prefix == 'on') {
                $prefix = $config->institution_code;
            }
            $result = $this->db->select("max(id) as id")->get('student')->row_array();
            $id = $result["id"];
            if (!empty($id)) {
                $maxNum = str_pad($id + 1, 5, '0', STR_PAD_LEFT);
            } else {
                $maxNum = '00001';
            }
            return ($prefix . $maxNum);
        }
    }

    public function getDisableReason($student_id = '')
    {
        $this->db->select("rd.*,disable_reason.name as reason");
        $this->db->from('disable_reason_details as rd');
        $this->db->join('disable_reason', 'disable_reason.id = rd.reason_id', 'left');
        $this->db->where('student_id', $student_id);
        $this->db->order_by('rd.id', 'DESC');
        $this->db->limit(1);
        $row = $this->db->get()->row();
        return $row;
    }

    public function getSiblingList($parent_id = '', $student_id = '')
    {
        $this->db->select('s.photo, s.register_no, CONCAT_WS(" ",s.first_name, s.last_name) as fullname,s.gender,s.mobileno,e.roll,e.branch_id,c.name as class_name,se.name as section_name');
        $this->db->from('enroll as e');
        $this->db->join('student as s', 'e.student_id = s.id', 'inner');
        $this->db->join('class as c', 'e.class_id = c.id', 'left');
        $this->db->join('section as se', 'e.section_id = se.id', 'left');
        $this->db->where_not_in('s.id', $student_id);
        $this->db->where('s.parent_id', $parent_id);
        $this->db->order_by('s.id', 'ASC');
        $query = $this->db->get();
        return $query->result();
    }

    public function getParentList($class_id = '', $section_id = '', $branch_id = '')
    {
        $this->db->select('p.name as g_name,p.father_name,p.mother_name,p.occupation,count(s.parent_id) as child,p.mobileno,s.parent_id');
        $this->db->from('student as s');
        $this->db->join('enroll as e', 'e.student_id = s.id', 'inner');
        $this->db->join('parent as p', 'p.id = s.parent_id', 'inner');
        $this->db->where('e.class_id', $class_id);
        if ($section_id != 'all') {
            $this->db->where('e.section_id', $section_id);
        }
        $this->db->where('e.branch_id', $branch_id);
        $this->db->where('e.session_id', get_session_id());
        $this->db->order_by('s.id', 'ASC');
        $this->db->group_by('p.id');
        $query = $this->db->get();
        return $query->result_array();
    }

    public function getSiblingListByClass($parent_id = '', $class_id = '', $section_id = '')
    {
        $this->db->select('s.register_no,e.id as enroll_id,CONCAT_WS(" ",s.first_name, s.last_name) as fullname,s.gender,c.name as class_name,se.name as section_name');
        $this->db->from('enroll as e');
        $this->db->join('student as s', 'e.student_id = s.id', 'inner');
        $this->db->join('class as c', 'e.class_id = c.id', 'left');
        $this->db->join('section as se', 'e.section_id = se.id', 'left');
        $this->db->where('e.class_id', $class_id);
        if ($section_id != 'all') {
            $this->db->where('e.section_id', $section_id);
        }
        $this->db->where('e.session_id', get_session_id());
        $this->db->where('s.parent_id', $parent_id);
        $this->db->order_by('s.id', 'ASC');
        $query = $this->db->get();
        return $query->result();
    }

    public function studentListDT()
    {
        $branchID = $this->application_model->get_branch_id();
        $classID = $this->input->post('class_id');
        $sectionID = $this->input->post('section_id');
        $sessionID = get_session_id();

        // system fields validation rules
        $validArr = array();
        $validationArr = $this->student_fields_model->getStatusArr($branchID);
        foreach ($validationArr as $key => $value) {
            $validArr[$value->prefix] = (empty($value->status) ? 0 : 1);
        }

        // getting a list of classes assigned to a teacher
        $assigned_cs_list = $this->app_lib->get_ownClassSection();

        // custom fields data
        $i = 1;
        $field_sel_array = array();
        $field_val_array = array();
        $show_custom_fields = custom_form_table('student', $branchID);
        if (!empty($show_custom_fields)) {
            foreach ($show_custom_fields as $key => $fields) {
                $ctb_counter = "table_custom_" . $i;
                $field_sel_array[] = $ctb_counter . '.value as cfid_' . $fields['id'];
                $field_val_array[] = $ctb_counter . '.value';
                $this->datatables->join('custom_fields_values as ' . $ctb_counter, 'enroll.student_id = ' . $ctb_counter . '.relid AND ' . $ctb_counter . '.field_id = ' . $fields['id'], 'left');
                $i++;
            }
        }
        $field_select = (empty($field_sel_array)) ? "" : "," . implode(',', $field_sel_array);
        $custom_fields_column_order = (empty($field_val_array)) ? "" : "," . implode(',', $field_val_array);

        // Database query
        $this->datatables->select('enroll.*,CONCAT_WS(" ",student.first_name, student.last_name) as fullname,student.photo,student.mobileno,student.admission_date,student.gender,student.register_no,student.birthday,enroll.roll,class.name as class_name,student.parent_id,section.name as section_name,student_category.name as category,parent.name as guardian_name,parent.mobileno as guardian_mobileno' . $field_select);
        $this->datatables->from('enroll');
        $this->datatables->join('student', 'student.id = enroll.student_id', 'inner');
        $this->datatables->join('class', 'class.id = enroll.class_id', 'left');
        $this->datatables->join('section', 'section.id = enroll.section_id', 'left');
        $this->datatables->join('student_category', 'student_category.id = student.category_id', 'left');
        $this->datatables->join('parent', 'parent.id = student.parent_id', 'left');
        $this->datatables->search_value('student.register_no,student.first_name,student.last_name,student.gender,student_category.name,class.name,section.name,enroll.roll,parent.name' . $field_select);
        $this->datatables->column_order('enroll.id,enroll.id,student.first_name,class.name,section.name,student.gender,student.mobileno,student.register_no,enroll.roll,student.birthday,parent.name' . $custom_fields_column_order);
        $this->datatables->order_by('enroll.id', 'desc');
        $this->datatables->where('student.active', 1);
        $this->datatables->where('enroll.session_id', $sessionID);
        $this->datatables->where('enroll.branch_id', $branchID);
        if (!empty($classID)) {
            $this->datatables->where('enroll.class_id', $classID);
        }
        if (!empty($sectionID)) {
            $this->datatables->where('enroll.section_id', $sectionID);
        }

        // filter classes by teacher assigned classes
        if ($assigned_cs_list != false && !empty($assigned_cs_list)) {
            $this->datatables->group_start();
            foreach ($assigned_cs_list as $class_key => $class_value) {
                foreach ($class_value as $section_key => $section_value) {
                    $this->datatables->or_group_start();
                    $this->datatables->where('enroll.class_id', $class_key);
                    $this->datatables->where('enroll.section_id', $section_value);
                    $this->datatables->group_end();

                }
            }
            $this->datatables->group_end();
        }
        $results = $this->datatables->generate();

        // data processing for DataTable
        $records = array();
        $records = json_decode($results);
        $data = array();
        foreach ($records->data as $key => $record) {
            $fee_progress = $this->getFeeProgress($record->id);

            // age calculation
            if(!empty($record->birthday)){
                $birthday = new DateTime($record->birthday);
                $today = new DateTime('today');
                $age = $birthday->diff($today)->y;
                $stu_age = html_escape($age);
            }else{
                $stu_age = "N/A";
            }
            // photo
            $photo = "<img src='" . get_image_url('student', $record->photo) . "' height='50'>";

            // actions btn
            $actions = '<button class="btn btn-circle icon btn-default" data-toggle="tooltip" data-original-title="' . translate('quick_view') . '" data-loading-text="<i class=\'fas fa-spinner fa-spin\'></i>" onclick="studentQuickView(' . "'" . $record->id . "'" . ', this)"><i class="fas fa-qrcode"></i></button>';
            if (get_permission('student', 'is_edit')) {
                $actions .= '<a href="' . base_url('student/profile/') . $record->id . '" class="btn btn-circle btn-default icon" data-toggle="tooltip" data-original-title="' . translate('details') . '"> <i class="far fa-arrow-alt-circle-right"></i></a>';
            }
            if (get_permission('student', 'is_delete')) {
                $actions .= btn_delete('student/delete_data/' . $record->id . '/' . $record->student_id);
            }
            // dt-data array 
            $row   = array();
            $row[] = "<div class='checked-area'><div class='checkbox-replace'>
                            <label class='i-checks'>
                                <input type='checkbox' class='cb_bulkdelete' id='" . $record->student_id . "'><i></i>
                            </label>
                        </div></div>";
if ($validArr['student_photo']) {
            $row[] = $photo;
}
            $row[] = $record->fullname;
            $row[] = $record->class_name;
            $row[] = $record->section_name;
if ($validArr['gender']) {
            $row[] = translate($record->gender);
}
if ($validArr['student_mobile_no']) {
            $row[] = $record->mobileno;
}
            $row[] = $record->register_no . "\n<small class='text-muted bs-block'>"._d($record->admission_date)."</small>";
if ($validArr['roll']) {
            $row[] = $record->roll;
}
            $row[] = $stu_age;
            if (empty($record->parent_id)) {
                $row[] = 'N/A';
            } else {
                $mobileno = empty($record->guardian_mobileno) ? '' : "\n<small class='text-muted bs-block'>" . $record->guardian_mobileno . "</small>";
                $row[] = $record->guardian_name . $mobileno;
            }
            if (count($show_custom_fields)) {
                foreach ($show_custom_fields as $fields) {
                    $field_label   = 'cfid_' . $fields['id'];
                    $row[] = $record->$field_label;
                }
            }
            $row[] = '<div class="progress progress-xl m-none prb-mw">
                        <div class="progress-bar text-dark" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: ' . $fee_progress . '%;">' . $fee_progress.'%</div>
                    </div>';
            $row[] = $actions;
            $data[] = $row;
        }
        $json_data = array(
            "draw"                => intval($records->draw),
            "recordsTotal"        => intval($records->recordsTotal),
            "recordsFiltered"     => intval($records->recordsFiltered),
            "data"                => $data,
        );
        return json_encode($json_data);
    }
}

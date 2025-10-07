<?php
if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class Homework_model extends MY_Model
{

    public function __construct()
    {
        parent::__construct();
    }

    public function getHomeworkDT_list()
    {
        $classID = $this->input->post('class_id');
        $sectionID = $this->input->post('section_id');
        $subjectID = $this->input->post('subject_id');
        $branchID = $this->application_model->get_branch_id();

        // getting a list of classes / subject assigned to a teacher
        $assigned_cs_list = $this->app_lib->get_ownClassSection();
        // filter classes by teacher assigned classes
        if ($assigned_cs_list != false && !empty($assigned_cs_list)) {
            $arraySubject = [];
            foreach ($assigned_cs_list as $class_key => $class_value) {
                foreach ($class_value as $section_key => $section_value) {
                    $getSubject = $this->subject_model->getSubjectByClassSection($class_key, $section_value);
                    foreach ($getSubject->result() as $subject_key => $subject_value) {
                        $arraySubject[$class_key][] = [$section_value, $subject_value->subject_id];

                    }
                }
            }
        } 

        $this->datatables->select('homework.*,subject.name as subject_name,class.name as class_name,section.name as section_name,staff.name as creator_name');
        $this->datatables->from('homework');
        $this->datatables->join('subject', 'subject.id = homework.subject_id', 'left');
        $this->datatables->join('class', 'class.id = homework.class_id', 'left');
        $this->datatables->join('section', 'section.id = homework.section_id', 'left');
        $this->datatables->join('staff', 'staff.id = homework.created_by', 'left');
        if (!empty($classID)) 
            $this->datatables->where('homework.class_id', $classID);
        if (!empty($sectionID))
            $this->datatables->where('homework.section_id', $sectionID);
        if (!empty($subjectID))
            $this->datatables->where('homework.subject_id', $subjectID);
        $this->datatables->where('homework.branch_id', $branchID);
        $this->datatables->where('homework.session_id', get_session_id());

        // filtering classes/subjects by assigned teacher
        if ($assigned_cs_list != false && !empty($arraySubject)) {
            $this->datatables->group_start();
                foreach ($arraySubject as $class => $class_value) {
                    foreach ($class_value as $skey => $section_value) {
                        $this->datatables->or_group_start();
                        $this->datatables->where('homework.class_id', $class);
                        $this->datatables->where('homework.section_id', $section_value[0]);
                        $this->datatables->where('homework.subject_id', $section_value[1]);
                        $this->datatables->group_end();
                    }
                }
            $this->datatables->group_end();
        } 

        $this->datatables->search_value('subject.name,section.name,class.name,homework.date_of_homework,homework.date_of_submission,homework.schedule_date,staff.name');
        $this->datatables->column_order('homework.id,subject.name,class.id,section.id,homework.date_of_homework,homework.date_of_submission,homework.sms_notification,homework.status,homework.schedule_date,creator_name');
        $this->datatables->order_by('homework.id', 'desc');
        $results = $this->datatables->generate();
        
        return $results;
    }

    public function evaluationCounter($classID, $sectionID, $homeworkID)
    {
        $countStu = $this->db->where(array('class_id' => $classID, 'section_id' => $sectionID, 'session_id' => get_session_id()))->get('enroll')->num_rows();
        $countEva = $this->db->where(array('homework_id' => $homeworkID, 'status' => 'c'))->get('homework_evaluation')->num_rows();
        $incomplete = ($countStu - $countEva);
        return array('total' => $countStu, 'complete' => $countEva, 'incomplete' => $incomplete);
    }

    public function getEvaluate($homeworkID)
    {
        $this->db->select('homework.*,CONCAT_WS(" ",s.first_name, s.last_name) as fullname,s.register_no,e.student_id, e.roll,subject.name as subject_name,class.name as class_name,section.name as section_name,he.id as ev_id,he.status as ev_status,he.remark as ev_remarks,he.rank,hs.message,hs.enc_name');
        $this->db->from('homework');
        $this->db->join('enroll as e', 'e.class_id=homework.class_id and e.section_id = homework.section_id and e.session_id = homework.session_id', 'inner');
        $this->db->join('student as s', 'e.student_id = s.id', 'inner');
        $this->db->join('homework_evaluation as he', 'he.homework_id = homework.id and he.student_id = e.student_id', 'left');
        $this->db->join('homework_submit as hs', 'hs.homework_id = homework.id and hs.student_id = e.student_id', 'left');
        $this->db->join('subject', 'subject.id = homework.subject_id', 'left');
        $this->db->join('class', 'class.id = homework.class_id', 'left');
        $this->db->join('section', 'section.id = homework.section_id', 'left');
        $this->db->where('homework.id', $homeworkID);
        if (!is_superadmin_loggedin()) {
            $this->db->where('homework.branch_id', get_loggedin_branch_id());
        }
        $this->db->where('homework.session_id', get_session_id());
        $this->db->order_by('homework.id', 'desc');
        return $this->db->get()->result_array();
    }

    public function getEvaluateDT($homeworkID = '')
    {
        $this->datatables->select('homework.*,CONCAT_WS(" ",s.first_name, s.last_name) as fullname,s.register_no,s.mobileno,e.student_id,s.gender,subject.name as subject_name,class.name as class_name,section.name as section_name,he.id as ev_id,he.status as ev_status,he.remark as ev_remarks,he.rank,hs.message,hs.enc_name');
        $this->datatables->from('enroll as e');
        $this->datatables->join('homework', 'homework.class_id = e.class_id and homework.section_id = e.section_id and homework.session_id = e.session_id', 'inner');
        $this->datatables->join('student as s', 'e.student_id = s.id', 'inner');
        $this->datatables->join('homework_evaluation as he', 'he.homework_id = homework.id and he.student_id = e.student_id', 'left');
        $this->datatables->join('homework_submit as hs', 'hs.homework_id = homework.id and hs.student_id = e.student_id', 'left');
        $this->datatables->join('subject', 'subject.id = homework.subject_id', 'left');
        $this->datatables->join('class', 'class.id = homework.class_id', 'left');
        $this->datatables->join('section', 'section.id = homework.section_id', 'left');
        $this->datatables->where('homework.id', $homeworkID);
        if (!is_superadmin_loggedin()) {
            $this->datatables->where('homework.branch_id', get_loggedin_branch_id());
        }
        $this->datatables->where('homework.session_id', get_session_id());
        $this->datatables->search_value('s.first_name,s.last_name,s.register_no,subject.name');
        $this->datatables->column_order('homework.id,s.first_name,homework.class_id,s.gender,s.register_no,s.mobileno,subject.name,he.status,he.rank');
        $this->datatables->order_by('homework.id', 'desc');
        return $this->datatables->generate();
    }

    // save student homework in DB
    public function save($data)
    {
    	$status = isset($data['published_later']) ? TRUE : FALSE;
        $sms_notification = isset($data['notification_sms']) ? TRUE : FALSE;
    	$arrayHomework = array(
    		'branch_id' => $this->application_model->get_branch_id(),
    		'class_id' => $data['class_id'],
    		'section_id' => $data['section_id'], 
    		'session_id' => get_session_id(), 
    		'subject_id' => $data['subject_id'], 
    		'date_of_homework' => date("Y-m-d", strtotime($data['date_of_homework'])), 
    		'date_of_submission' => date("Y-m-d", strtotime($data['date_of_submission'])), 
    		'description' => $data['homework'], 
    		'created_by' => get_loggedin_user_id(), 
    		'create_date' => date("Y-m-d"), 
    		'status' => $status, 
            'sms_notification' => $sms_notification, 
    	);
    	if ($status == TRUE) {
    		$arrayHomework['schedule_date'] = date("Y-m-d", strtotime($data['schedule_date']));
    	} else {
            $arrayHomework['schedule_date'] = null;
        }
        if (isset($data['homework_id'])) {
            if (!is_superadmin_loggedin()) 
                $this->db->where('branch_id', get_loggedin_branch_id());
            $this->db->where('id', $data['homework_id']);
            $this->db->update('homework', $arrayHomework);
            $insert_id = $data['homework_id'];
        } else {
            $this->db->insert('homework', $arrayHomework);
            $insert_id = $this->db->insert_id();
        }

        if (isset($_FILES["attachment_file"]) && !empty($_FILES['attachment_file']['name'])) {
            $uploaddir = './uploads/attachments/homework/';
            if (!is_dir($uploaddir) && !mkdir($uploaddir)) {
                die("Error creating folder $uploaddir");
            }
            $fileInfo = pathinfo($_FILES["attachment_file"]["name"]);
            $document = basename($_FILES['attachment_file']['name']);

            $file_name = $insert_id . '.' . $fileInfo['extension'];
            move_uploaded_file($_FILES["attachment_file"]["tmp_name"], $uploaddir . $file_name);
        } else {
            if (isset($data['old_document'])) {
               $document = $data['old_document'];
            } else {
                $document = "";
            }
        }

        $this->db->where('id', $insert_id);
        $this->db->update('homework', array('document' => $document));

        //send homework sms notification
        if (isset($data['notification_sms'])) {
        	$stuList = $this->application_model->getStudentListByClassSection($arrayHomework['class_id'], $arrayHomework['section_id'], $arrayHomework['branch_id']);
        	foreach ($stuList as $row) {
        		$row['date_of_homework'] = $arrayHomework['date_of_homework'];
        		$row['date_of_submission'] = $arrayHomework['date_of_submission'];
        		$row['subject_id'] = $arrayHomework['subject_id'];
        		$this->sms_model->sendHomework($row);
        	}
        }
    }
}

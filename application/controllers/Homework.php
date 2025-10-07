<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * @package : Ramom school management system
 * @version : 7.0
 * @developed by : RamomCoder
 * @support : ramomcoder@yahoo.com
 * @author url : http://codecanyon.net/user/RamomCoder
 * @filename : Homework.php
 * @copyright : Reserved RamomCoder Team
 */

class Homework extends Admin_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->library('datatables');
        $this->load->model('homework_model');
        $this->load->model('subject_model');
        $this->load->model('sms_model');
        if (!moduleIsEnabled('homework')) {
            access_denied();
        }
    }

    /* student form validation rules */
    protected function homework_search_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'trim|required');
        }
        $this->form_validation->set_rules('class_id', translate('class'), 'trim|required');
        $this->form_validation->set_rules('section_id', translate('section'), 'trim');
        $this->form_validation->set_rules('subject_id', translate('subject'), 'trim');
    }

    public function index()
    {
        // check access permission
        if (!get_permission('homework', 'is_view')) {
            access_denied();
        }

        $branchID = $this->application_model->get_branch_id();
        if ($_POST) {
            $this->homework_search_validation();
            if ($this->form_validation->run() == true) {
                $export_title = get_type_name_by_id('branch', $branchID) . ' - ' . translate('homework') . ' ' . translate('list');
                $array = array('status' => 'success', 'export_title' => $export_title,'error' => '');
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail','error' => $error);
            }
            echo json_encode($array);
            exit();
        }
        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('homework');
        $this->data['sub_page'] = 'homework/index';
        $this->data['main_menu'] = 'homework';
        $this->load->view('layout/index', $this->data);
    }

    public function getHomeworkListDT()
    {
        if ($_POST) {
            if (get_permission('homework', 'is_view')) {
                $submit_btn = $this->input->post('submit_btn');
                if (empty($submit_btn)) {
                    $json_data = array(
                        "draw"                => intval(0),
                        "recordsTotal"        => intval(0),
                        "recordsFiltered"     => intval(0),
                        "data"                => [],
                    );
                    echo json_encode($json_data);
                } else {
                    $results = $this->homework_model->getHomeworkDT_list();
                    $startDT = $this->input->post('start');
                    $records = array();
                    $records = json_decode($results);
                    $data = array();
                    $count = $startDT + 1;
                    foreach ($records->data as $key => $record) {
                        // actions btn
                        $actions = '<button class="btn btn-circle icon btn-default" data-toggle="tooltip" data-original-title="' . translate('evaluate') . '" data-loading-text="<i class=\'fas fa-spinner fa-spin\'></i>" onclick="getEvaluate(' . "'" . $record->id . "'" . ', this)"><i class="fas fa-bars"></i></button>';
                        if (get_permission('homework', 'is_edit')) {
                            $actions .= '<a href="' . base_url('homework/edit/' . $record->id) . '" class="btn btn-circle btn-default icon"><i class="fas fa-pen-nib"></i></a>';
                        }
                        if (get_permission('homework', 'is_delete')) {
                            $actions .=  btn_delete('homework/delete/' . $record->id);
                        }
                        if ($record->sms_notification == 1) {
                            $sms_status = translate('yes');
                            $sms_labelmode = 'label-success-custom';
                        } else {
                            $sms_labelmode = 'label-info-custom';
                            $sms_status = translate('no');
                        }
                        if ($record->status == 0) {
                            $status = translate('published');
                            $labelmode = 'label-success-custom';
                        } else {
                            $labelmode = 'label-info-custom';
                            $status = translate('pending');
                        }
                        // dt-data array 
                        $row   = array();
                        $row[] = $count++;
                        $row[] = $record->subject_name;
                        $row[] = $record->class_name;
                        $row[] = $record->section_name;
                        $row[] = _d($record->date_of_homework);
                        $row[] = _d($record->date_of_submission);
                        $row[] = "<span class='value label " . $sms_labelmode . " '>" . $sms_status . "</span>";
                        $row[] = "<span class='value label " . $labelmode . " '>" . $status . "</span>";
                        $row[] = empty(_d($record->schedule_date))  ? "N/A" : _d($record->schedule_date);
                        $row[] = $record->creator_name;
                        $row[] = $actions;
                        $data[] = $row;
                    }
                    $json_data = array(
                        "draw"                => intval($records->draw),
                        "recordsTotal"        => intval($records->recordsTotal),
                        "recordsFiltered"     => intval($records->recordsFiltered),
                        "data"                => $data,
                    );
                    echo json_encode($json_data);
                }
            }
        }
    }

    public function add()
    {
        if (!get_permission('homework', 'is_add')) {
            access_denied();
        }

        if ($_POST) {
            $this->homework_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                $response = $this->homework_model->save($post);
                set_alert('success', translate('information_has_been_saved_successfully'));
                $url = base_url('homework');
                $array = array('status' => 'success', 'url' => $url);
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail','error' => $error);
            }
            echo json_encode($array);
            exit();
        }
        
        $this->data['branch_id'] = $this->application_model->get_branch_id();
        $this->data['title'] = translate('homework');
        $this->data['sub_page'] = 'homework/add';
        $this->data['main_menu'] = 'homework';
        $this->data['headerelements'] = array(
            'css' => array(
                'vendor/summernote/summernote.css',
                'vendor/bootstrap-fileupload/bootstrap-fileupload.min.css',
            ),
            'js' => array(
                'vendor/summernote/summernote.js',
                'vendor/bootstrap-fileupload/bootstrap-fileupload.min.js',
            ),
        );
        $this->load->view('layout/index', $this->data);
    }

    public function edit($id='')
    {
        if (!get_permission('homework', 'is_edit')) {
            access_denied();
        }
        
        if ($_POST) {
            $this->homework_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                $response = $this->homework_model->save($post);
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('homework');
                $array = array('status' => 'success', 'url' => $url);
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail','error' => $error);
            }
            echo json_encode($array);
            exit();
        }
        
        $this->data['homework'] = $this->app_lib->getTable('homework', array('t.id' => $id), true);
        $this->data['branch_id'] = $this->application_model->get_branch_id();
        $this->data['title'] = translate('homework');
        $this->data['sub_page'] = 'homework/edit';
        $this->data['main_menu'] = 'homework';
        $this->data['headerelements'] = array(
            'css' => array(
                'vendor/summernote/summernote.css',
                'vendor/bootstrap-fileupload/bootstrap-fileupload.min.css',
            ),
            'js' => array(
                'vendor/summernote/summernote.js',
                'vendor/bootstrap-fileupload/bootstrap-fileupload.min.js',
            ),
        );
        $this->load->view('layout/index', $this->data);
    }

    public function evaluate($id='')
    {
        // check access permission
        if (!get_permission('homework_evaluate', 'is_view')) {
            access_denied();
        }

        $branchID = $this->application_model->get_branch_id();
        $this->data['homeworklist'] = $this->homework_model->getEvaluate($id);
        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('homework');
        $this->data['sub_page'] = 'homework/evaluate_list';
        $this->data['main_menu'] = 'homework';
        $this->load->view('layout/index', $this->data);
    }

    function evaluate_save()
    {
        // check access permission
        if (!get_permission('homework_evaluate', 'is_add')) {
            ajax_access_denied();
        }
        if ($_POST) {
            $this->form_validation->set_rules('date', translate('date'), 'trim|required');
            if ($this->form_validation->run() !== false) {
                $evaluate = $this->input->post('evaluate');
                $homeworkID = $this->input->post('homework_id');
                $date = date("Y-m-d", strtotime($this->input->post('date')));
                foreach ($evaluate as $key => $value) {
                    $attStatus = (isset($value['status']) ? $value['status'] : "");
                    $arrayAttendance = array(
                        'homework_id' => $homeworkID,
                        'student_id' => $value['student_id'],
                        'status' => $attStatus,
                        'rank' => $value['rank'],
                        'remark' => $value['remark'],
                        'date' => $date,
                    );
                    if (empty($value['evaluation_id'])) {
                        $this->db->insert('homework_evaluation', $arrayAttendance);
                    } else {
                        $this->db->where('id', $value['evaluation_id']);
                        $this->db->update('homework_evaluation', array('rank' => $value['rank'], 'status' => $attStatus, 'remark' => $value['remark'], 'date' => $date));
                    }
                }
                $this->db->where('id', $homeworkID);
                $this->db->update('homework', array('evaluation_date' => $date, 'evaluated_by' => get_loggedin_user_id()));
                set_alert('success', translate('information_has_been_saved_successfully'));
                $array  = array('status' => 'success', 'message' => translate('information_has_been_saved_successfully'));
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail', 'error' => $error);
            }
            echo json_encode($array);
            exit();
        }  
    }

    public function evaluateModal()
    {
        $this->data['homeworkID'] = $this->input->post('homework_id');
        echo $this->load->view('homework/evaluateModal', $this->data, true);
    }

    public function report()
    {
        // check access permission
        if (!get_permission('evaluation_report', 'is_view')) {
            access_denied();
        }

        $branchID = $this->application_model->get_branch_id();
        if ($_POST) {
            $this->homework_search_validation();
            if ($this->form_validation->run() == true) {
                $export_title = get_type_name_by_id('branch', $branchID) . ' - ' . translate('evaluation_report');
                $array = array('status' => 'success', 'export_title' => $export_title,'error' => '');
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail','error' => $error);
                
            }
            echo json_encode($array);
            exit();
        }
        if ($_POST) {
            $classID = $this->input->post('class_id');
            $sectionID = $this->input->post('section_id');
            $subjectID = $this->input->post('subject_id');
            $this->data['homeworklist'] = $this->homework_model->getList($classID, $sectionID, $subjectID, $branchID);
        }
        
        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('homework');
        $this->data['sub_page'] = 'homework/report';
        $this->data['main_menu'] = 'homework';
        $this->load->view('layout/index', $this->data);
    }


    public function getHomeworkReportListDT()
    {
        if ($_POST) {
            if (get_permission('evaluation_report', 'is_view')) {
                $submit_btn = $this->input->post('submit_btn');
                if (empty($submit_btn)) {
                    $json_data = array(
                        "draw"                => intval(0),
                        "recordsTotal"        => intval(0),
                        "recordsFiltered"     => intval(0),
                        "data"                => [],
                    );
                    echo json_encode($json_data);
                } else {
                    $results = $this->homework_model->getHomeworkDT_list();
                    $startDT = $this->input->post('start');
                    $records = array();
                    $records = json_decode($results);
                    $data = array();
                    $count = $startDT + 1;
                    foreach ($records->data as $key => $record) {
                        $getCounter = $this->homework_model->evaluationCounter($record->class_id, $record->section_id, $record->id);
                        // actions btn
                        $actions = '<button class="btn btn-circle btn-default" data-toggle="tooltip" data-original-title="' . translate('evaluate') . '" data-loading-text="<i class=\'fas fa-spinner fa-spin\'></i> Loading" onclick="getReport(' . "'" . $record->id . "'" . ', this)"><i class="fas fa-bars"></i> ' . translate('details') . '</button>';
                        if ($record->sms_notification == 1) {
                            $sms_status = translate('yes');
                            $sms_labelmode = 'label-success-custom';
                        } else {
                            $sms_labelmode = 'label-info-custom';
                            $sms_status = translate('no');
                        }
                        if ($record->status == 0) {
                            $status = translate('published');
                            $labelmode = 'label-success-custom';
                        } else {
                            $labelmode = 'label-info-custom';
                            $status = translate('pending');
                        }
                        // dt-data array 
                        $row   = array();
                        $row[] = $count++;
                        $row[] = $record->subject_name;
                        $row[] = $record->class_name;
                        $row[] = $record->section_name;
                        $row[] = _d($record->date_of_homework);
                        $row[] = _d($record->date_of_submission);
                        $row[] = $getCounter['complete'] .'/'. $getCounter['incomplete'];
                        $row[] = $getCounter['total'];
                        $row[] = $actions;
                        $data[] = $row;
                    }
                    $json_data = array(
                        "draw"                => intval($records->draw),
                        "recordsTotal"        => intval($records->recordsTotal),
                        "recordsFiltered"     => intval($records->recordsFiltered),
                        "data"                => $data,
                    );
                    echo json_encode($json_data);
                }
            }
        }
    }

    public function evaluateDetails()
    {
        if ($_POST) {
            if (get_permission('evaluation_report', 'is_view')) {
                $id = $this->input->post('homework_id');
                if (empty($id)) {
                    $json_data = array(
                        "draw"                => intval(0),
                        "recordsTotal"        => intval(0),
                        "recordsFiltered"     => intval(0),
                        "data"                => [],
                    );
                    echo json_encode($json_data);
                } else {
                    $results = $this->homework_model->getEvaluateDT($id);
                    $startDT = $this->input->post('start');
                    $records = array();
                    $records = json_decode($results);
                    $data = array();
                    $count = $startDT + 1;
                    foreach ($records->data as $key => $record) {
                        if ($record->ev_status == 'u' || $record->ev_status == '') {
                            $labelmode = 'label-danger-custom';
                            $status = translate('incomplete');
                        } else {
                            $status = translate('complete');
                            $labelmode = 'label-success-custom';
                        }
                        // dt-data array 
                        $row   = array();
                        $row[] = $count++;
                        $row[] = $record->fullname;
                        $row[] = $record->class_name . " ({$record->section_name})";
                        $row[] = translate($record->gender);
                        $row[] = $record->register_no;
                        $row[] = $record->mobileno;
                        $row[] = $record->subject_name;
                        $row[] = "<span class='value label " . $labelmode . " '>" . $status . "</span>";
                        $row[] = $record->rank;
                        $row[] = $record->ev_remarks;
                        $data[] = $row;
                    }
                    $json_data = array(
                        "draw"                => intval($records->draw),
                        "recordsTotal"        => intval($records->recordsTotal),
                        "recordsFiltered"     => intval($records->recordsFiltered),
                        "data"                => $data,
                    );
                    echo json_encode($json_data);
                }
            }
        }
    }

    public function download($id)
    {
        $this->load->helper('download');
        $name     = get_type_name_by_id('homework', $id, 'document');
        $ext      = explode(".", $name);
        $filepath = "./uploads/attachments/homework/" . $id . "." . $ext[1];
        $data     = file_get_contents($filepath);
        force_download($name, $data);
    }

    public function download_submitted()
    {
        $this->load->helper('download');
        $encrypt_name = urldecode($this->input->get('file'));
        if(preg_match('/^[^.][-a-z0-9_.]+[a-z]$/i', $encrypt_name)) {
            $file_name = $this->db->select('file_name')->where('enc_name', $encrypt_name)->get('homework_submit')->row()->file_name;
            if (!empty($file_name)) {
                force_download($file_name, file_get_contents('uploads/attachments/homework_submit/' . $encrypt_name));
            }
        }
    }

    public function delete($id = '')
    {
        if (get_permission('homework', 'is_delete') && !empty($id)) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $name = get_type_name_by_id('homework', $id, 'document');
            $ext = explode(".", $name);
            $this->db->where('id', $id);
            $this->db->delete('homework');
            $filepath = "./uploads/attachments/homework/" . $id . "." . $ext[1];
            if (file_exists($filepath)) {
                unlink($filepath);
            }
        }
    }

    /* homework form validation rules */
    protected function homework_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $this->form_validation->set_rules('class_id', translate('class'), 'trim|required');
        $this->form_validation->set_rules('section_id', translate('section'), 'trim|required');
        $this->form_validation->set_rules('subject_id', translate('subject'), 'trim|required');
        $this->form_validation->set_rules('date_of_homework', translate('date_of_homework'), 'trim|required');
        $this->form_validation->set_rules('date_of_submission', translate('date_of_submission'), 'trim|required');
        if (isset($_POST['published_later'])) {
            $this->form_validation->set_rules('schedule_date', translate('schedule_date'), 'trim|required');
        }
        $this->form_validation->set_rules('homework', translate('homework'), 'trim|required');
        $this->form_validation->set_rules('attachment_file', translate('attachment'), 'callback_handle_upload');
    }

    // upload file form validation
    public function handle_upload()
    {
        if (isset($_FILES["attachment_file"]) && !empty($_FILES['attachment_file']['name'])) {
            $allowedExts = array_map('trim', array_map('strtolower', explode(',', $this->data['global_config']['file_extension'])));
            $allowedSizeKB = $this->data['global_config']['file_size'];
            $allowedSize = floatval(1024 * $allowedSizeKB);
            
            $file_size = $_FILES["attachment_file"]["size"];
            $file_name = $_FILES["attachment_file"]["name"];
            $extension = pathinfo($file_name, PATHINFO_EXTENSION);
            if ($files = filesize($_FILES["attachment_file"]['tmp_name'])) {
                if (!in_array(strtolower($extension), $allowedExts)) {
                    $this->form_validation->set_message('handle_upload', translate('this_file_type_is_not_allowed'));
                    return false;
                }
                if ($file_size > $allowedSize) {
                    $this->form_validation->set_message('handle_upload', translate('file_size_shoud_be_less_than') . " $allowedSizeKB KB.");
                    return false;
                }
            } else {
                $this->form_validation->set_message('handle_upload', translate('error_reading_the_file'));
                return false;
            }
            return true;
        }
    }
}

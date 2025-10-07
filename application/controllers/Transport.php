<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * @package : Ramom school management system
 * @version : 7.0
 * @developed by : RamomCoder
 * @support : ramomcoder@yahoo.com
 * @author url : http://codecanyon.net/user/RamomCoder
 * @filename : Transport.php
 * @copyright : Reserved RamomCoder Team
 */

class Transport extends Admin_Controller
{

    public function __construct()
    {
        parent::__construct();
        if (!moduleIsEnabled('transport')) {
            access_denied();
        }
        $this->load->model('transport_model');
        $this->load->library('datatables');
    }

    public function index()
    {
        redirect(base_url(), 'refresh');
    }

    protected function route_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $this->form_validation->set_rules('route_name', translate('route_name'), 'trim|required');
        $this->form_validation->set_rules('start_place', translate('start_place'), 'required');
        $this->form_validation->set_rules('stop_place', translate('stop_place'), 'trim|required');
        $stoppages = $this->input->post('stoppage');
        if (!empty($stoppages)) {
            $stoppageID_array = [];
            foreach ($stoppages as $key => $value) {
                $this->form_validation->set_rules('stoppage[' . $key . '][stoppage_id]', translate('stoppage'), 'trim|required');
                $this->form_validation->set_rules('stoppage[' . $key . '][stop_time]', translate('stop_time'), 'trim|required');
                $this->form_validation->set_rules('stoppage[' . $key . '][route_fare]', translate('route_fare'), 'trim|required');
                $stoppageID = $value["stoppage_id"];
                if (array_key_exists($stoppageID, $stoppageID_array) && $stoppageID != "") {
                    $this->form_validation->set_rules('stoppage[' . $key . '][stoppage_id]', translate('stoppage'), 'trim|callback_duplicate_rules');
                } else {
                    $stoppageID_array[$stoppageID] = 0;
                }
            }
        }
    }

    public function duplicate_rules($name)
    {
        $this->form_validation->set_message("duplicate_rules", translate('duplicate_stoppage_found'));
        return false;
    }

    // route user interface
    public function route()
    {
        if (!get_permission('transport_route', 'is_view')) {
            access_denied();
        }
        if ($_POST) {
            if (!get_permission('transport_route', 'is_add')) {
                ajax_access_denied();
            }
            $this->route_validation();
            if ($this->form_validation->run() == true) {
                $post = $this->input->post();
                //save all route information in the database file
                $this->transport_model->route_save($post);
                set_alert('success', translate('information_has_been_saved_successfully'));
                $url = base_url('transport/route');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['headerelements'] = [
            'css' => [
                'vendor/bootstrap-timepicker/css/bootstrap-timepicker.css',
            ],
            'js' => [
                'vendor/bootstrap-timepicker/bootstrap-timepicker.js',
            ],
        ];
        $this->data['transportlist'] = $this->app_lib->getTable('transport_route');
        $this->data['branch_id'] = $this->application_model->get_branch_id();
        $this->data['title'] = translate('route_master');
        $this->data['sub_page'] = 'transport/route';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    // route all information are prepared and user interface
    public function route_edit($id = '')
    {
        if (!get_permission('transport_route', 'is_edit')) {
            access_denied();
        }
        $route = $this->app_lib->getTable('transport_route', ['t.id' => $id], true);
        if (empty($route)) {
            show_404();
        }
        if ($_POST) {
            $this->route_validation();
            if ($this->form_validation->run() == true) {
                $post = $this->input->post();
                //save all route information in the database file
                $this->transport_model->route_save($post);
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('transport/route');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['headerelements'] = [
            'css' => [
                'vendor/bootstrap-timepicker/css/bootstrap-timepicker.css',
            ],
            'js' => [
                'vendor/bootstrap-timepicker/bootstrap-timepicker.js',
            ],
        ];
        $this->data['route'] = $route;
        $this->data['stoppages'] = $this->transport_model->stoppage_pointByRoute($id);
        $this->data['title'] = translate('route_master');
        $this->data['sub_page'] = 'transport/route_edit';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    public function getStoppageAjax()
    {
        if ($_POST) {
            $branchID = $this->application_model->get_branch_id();
            $this->data['branch_id'] = $branchID;
            $this->db->where('branch_id', $branchID);
            $result = $this->db->get('transport_stoppage')->result();
            $stoppagelist = ['' => translate('select')];
            foreach ($result as $key => $value) {
                $stoppagelist[$value->id] = $value->stop_position;
            }
            $this->data['stoppagelist'] = $stoppagelist;
            echo $this->load->view('transport/getStoppageAjax', $this->data, true);
        }
    }

    public function getStoppageDetails()
    {
        if ($_POST) {
            $stoppage_id = $this->input->post('stoppage_id');
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('id', $stoppage_id);
            $r = $this->db->get('transport_stoppage_point')->row();
            echo json_encode(['stop_time' => date("g:i A", strtotime($r->stop_time)), 'route_fare' => $r->route_fare]);
        }
    }

    public function route_delete($id = '')
    {
        if (get_permission('transport_route', 'is_delete')) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('id', $id);
            $this->db->delete('transport_route');
            if ($this->db->affected_rows() > 0) {
                $this->db->where('route_id', $id);
                $this->db->delete('transport_stoppage_point');
            }
        }
    }

    protected function vehicle_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $this->form_validation->set_rules('vehicle_no', translate('vehicle_no'), 'trim|required');
        $this->form_validation->set_rules('capacity', translate('capacity'), 'required|numeric');
        $this->form_validation->set_rules('driver_name', translate('driver_name'), 'trim|required');
        $this->form_validation->set_rules('driver_phone', translate('driver_phone'), 'trim|required');
        $this->form_validation->set_rules('driver_license', translate('driver_license'), 'trim|required');
    }

    // vehicle information add and delete
    public function vehicle()
    {
        if (!get_permission('transport_vehicle', 'is_view')) {
            access_denied();
        }
        if ($_POST) {
            if (!get_permission('transport_vehicle', 'is_add')) {
                ajax_access_denied();
            }
            $this->vehicle_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                //save all vehicle information in the database file
                $this->transport_model->vehicle_save($post);
                set_alert('success', translate('information_has_been_saved_successfully'));
                $url = base_url('transport/vehicle');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['transportlist'] = $this->app_lib->getTable('transport_vehicle');
        $this->data['title'] = translate('vehicle_master');
        $this->data['sub_page'] = 'transport/vehicle';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    // vehicle information edit
    public function vehicle_edit($id = '')
    {
        if (!get_permission('transport_vehicle', 'is_edit')) {
            access_denied();
        }
        $vehicle = $this->app_lib->getTable('transport_vehicle', ['t.id' => $id], true);
        if (empty($vehicle)) {
            show_404();
        }
        if ($_POST) {
            $this->vehicle_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                //save all vehicle information in the database file
                $this->transport_model->vehicle_save($post);
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('transport/vehicle');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['vehicle'] = $vehicle;
        $this->data['title'] = translate('vehicle_master');
        $this->data['sub_page'] = 'transport/vehicle_edit';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    public function vehicle_delete($id = '')
    {
        if (get_permission('transport_route', 'is_delete')) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('id', $id);
            $this->db->delete('transport_vehicle');
        }
    }

    // stoppage information add and delete
    public function stoppage()
    {
        if (!get_permission('transport_stoppage', 'is_view')) {
            access_denied();
        }

        if ($_POST) {
            if (!get_permission('transport_stoppage', 'is_add')) {
                ajax_access_denied();
            }
            $this->stoppage_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                //save all stoppage information in the database file
                $this->transport_model->stoppage_save($post);
                set_alert('success', translate('information_has_been_saved_successfully'));
                $url = base_url('transport/stoppage');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['stoppagelist'] = $this->app_lib->getTable('transport_stoppage');
        $this->data['title'] = translate('stoppage');
        $this->data['sub_page'] = 'transport/stoppage';
        $this->data['main_menu'] = 'transport';
        $this->data['headerelements'] = [
            'css' => [
                'vendor/bootstrap-timepicker/css/bootstrap-timepicker.css',
            ],
            'js' => [
                'vendor/bootstrap-timepicker/bootstrap-timepicker.js',
            ],
        ];
        $this->load->view('layout/index', $this->data);
    }

    // stoppage information edit
    public function stoppage_edit($id = '')
    {
        if (!get_permission('transport_stoppage', 'is_edit')) {
            access_denied();
        }
        if ($_POST) {
            $this->stoppage_validation();
            if ($this->form_validation->run() !== false) {
                $post = $this->input->post();
                //save all stoppage information in the database file
                $this->transport_model->stoppage_save($post);
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('transport/stoppage');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['stoppage'] = $this->app_lib->getTable('transport_stoppage', ['t.id' => $id], true);
        $this->data['title'] = translate('stoppage');
        $this->data['sub_page'] = 'transport/stoppage_edit';
        $this->data['main_menu'] = 'transport';
        $this->data['headerelements'] = [
            'css' => [
                'vendor/bootstrap-timepicker/css/bootstrap-timepicker.css',
            ],
            'js' => [
                'vendor/bootstrap-timepicker/bootstrap-timepicker.js',
            ],
        ];
        $this->load->view('layout/index', $this->data);
    }

    public function stoppage_delete($id = '')
    {
        if (get_permission('transport_stoppage', 'is_delete')) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('id', $id);
            $this->db->delete('transport_stoppage');
        }
    }

    /* user interface with assign vehicles and stoppage information and delete */
    protected function assign_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $this->form_validation->set_rules('route_id', translate('transport_route'), 'required|callback_unique_route_assign');
        $this->form_validation->set_rules('vehicle[]', translate('vehicle'), 'required');
    }

    public function vehicle_assign()
    {
        if (!get_permission('transport_assign', 'is_view')) {
            access_denied();
        }
        $branchID = $this->application_model->get_branch_id();
        if ($_POST) {
            if (!get_permission('transport_assign', 'is_add')) {
                ajax_access_denied();
            }
            $this->assign_validation();
            if ($this->form_validation->run() !== false) {
                $vehicles = $this->input->post('vehicle');
                foreach ($vehicles as $vehicle) {
                    $arrayData[] = [
                        'branch_id' => $branchID,
                        'route_id' => $this->input->post('route_id'),
                        'vehicle_id' => $vehicle,
                    ];
                }
                $this->db->insert_batch('transport_assign', $arrayData);
                set_alert('success', translate('information_has_been_saved_successfully'));
                $url = base_url('transport/vehicle_assign');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('assign_vehicle');
        $this->data['sub_page'] = 'transport/vehicle_assign';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);

    }

    /* user interface with vehicles assign information edit */
    public function assign_edit($id = '')
    {
        if (!get_permission('transport_assign', 'is_edit')) {
            access_denied();
        }
        if ($_POST) {
            $this->assign_validation();
            if ($this->form_validation->run() !== false) {
                $branchID = $this->application_model->get_branch_id();
                $routeID = $this->input->post('route_id');
                $vehicles = $this->input->post('vehicle');
                foreach ($vehicles as $vehicle) {
                    $data = [
                        'branch_id' => $branchID,
                        'route_id' => $id,
                        'vehicle_id' => $vehicle,
                    ];
                    $query = $this->db->get_where("transport_assign", $data);
                    if ($query->num_rows() == 0) {
                        $this->db->insert('transport_assign', $data);
                    } else {
                        $this->db->where('id', $query->row()->id);
                        $this->db->update('transport_assign', [
                            'route_id' => $routeID,
                        ]);
                    }
                }
                $this->db->where_not_in('vehicle_id', $vehicles);
                $this->db->where('route_id', $routeID);
                $this->db->where('branch_id', $branchID);
                $this->db->delete('transport_assign');
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('transport/vehicle_assign');
                $array = ['status' => 'success', 'url' => $url, 'error' => ''];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'url' => '', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }

        $this->data['assign'] = $this->transport_model->getAssignEdit($id);
        $this->data['title'] = translate('assign_vehicle');
        $this->data['sub_page'] = 'transport/vehicle_assign_edit';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    public function assign_delete($id = '')
    {
        if (get_permission('transport_assign', 'is_delete')) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('route_id', $id);
            $this->db->delete('transport_assign');
        }
    }

    // validate here, if the check route assign
    public function unique_route_assign($id)
    {
        if ($this->uri->segment(3)) {
            $this->db->where_not_in('route_id', $this->uri->segment(3));
        }
        $this->db->where(['route_id' => $id]);
        $uniform_row = $this->db->get('transport_assign')->num_rows();
        if ($uniform_row == 0) {
            return true;
        } else {
            $this->form_validation->set_message("unique_route_assign", "This route is already assigned.");
            return false;
        }
    }

    /* student transport allocation report */
    public function report()
    {
        if (!get_permission('transport_allocation', 'is_view')) {
            access_denied();
        }

        $branchID = $this->application_model->get_branch_id();
        if ($_POST) {
            $classID = $this->input->post('class_id');
            $sectionID = $this->input->post('section_id');
            $this->data['allocationlist'] = $this->transport_model->allocation_report($classID, $sectionID, $branchID);
        }

        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('allocation_report');
        $this->data['sub_page'] = 'transport/allocation';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    public function allocation_delete($id)
    {
        if (get_permission('transport_allocation', 'is_delete')) {
            $this->db->select('student_id');
            $this->db->where('id', $id);
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $student_id = $this->db->get('enroll')->row()->student_id;
            if (!empty($student_id)) {
                $arrayData = ['vehicle_id' => 0, 'route_id' => 0, 'stoppage_point_id' => null];
                $this->db->where('id', $student_id);
                $this->db->update('student', $arrayData);
                if ($this->db->affected_rows() > 0) {
                    $this->db->where('enroll_id', $id);
                    $this->db->delete('transport_fee_details');
                }
            }
        }
    }

    /* get vehicle list based on the route */
    public function get_vehicle_by_route()
    {
        $routeID = $this->input->post("routeID");
        if (!empty($routeID)) {
            $this->db->select('transport_assign.vehicle_id,transport_vehicle.vehicle_no');
            $this->db->from('transport_assign');
            $this->db->join('transport_vehicle', 'transport_vehicle.id = transport_assign.vehicle_id', 'inner');
            $this->db->order_by('transport_vehicle.id', 'asc');
            $this->db->where('transport_assign.route_id', $routeID);
            $query = $this->db->get();
            if ($query->num_rows() != 0) {
                echo '<option value="">' . translate('select') . '</option>';
                $vehicles = $query->result_array();
                foreach ($vehicles as $row) {
                    echo '<option value="' . $row['vehicle_id'] . '">' . $row['vehicle_no'] . '</option>';
                }
            } else {
                echo '<option value="">' . translate('no_selection_available') . '</option>';
            }
        } else {
            echo '<option value="">' . translate('first_select_the_route') . '</option>';
        }
    }

    /* get stoppage poin list based on the route */
    public function getStoppagePoinByRoute()
    {
        $routeID = $this->input->post("routeID");
        if (!empty($routeID)) {
            $this->db->select('transport_stoppage_point.id,transport_stoppage.stop_position');
            $this->db->from('transport_stoppage_point');
            $this->db->join('transport_stoppage', 'transport_stoppage.id = transport_stoppage_point.stoppage_id', 'inner');
            $this->db->order_by('transport_stoppage_point.order_no', 'asc');
            $this->db->where('transport_stoppage_point.route_id', $routeID);
            $query = $this->db->get();
            if ($query->num_rows() != 0) {
                echo '<option value="">' . translate('select') . '</option>';
                $vehicles = $query->result();
                foreach ($vehicles as $row) {
                    echo '<option value="' . $row->id . '">' . $row->stop_position . '</option>';
                }
            } else {
                echo '<option value="">' . translate('no_selection_available') . '</option>';
            }
        } else {
            echo '<option value="">' . translate('first_select_the_route') . '</option>';
        }
    }

    /* get vehicle list based on the branch */
    public function getVehicleByBranch()
    {
        $html = "";
        $branchID = $this->application_model->get_branch_id();
        if (!empty($branchID)) {
            $result = $this->db->select('id,vehicle_no')->where('branch_id', $branchID)->get('transport_vehicle')->result_array();
            if (count($result)) {
                $html .= '<option value="">' . translate('select') . '</option>';
                foreach ($result as $row) {
                    $html .= '<option value="' . $row['id'] . '">' . $row['vehicle_no'] . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_selection_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('first_select_the_route') . '</option>';
        }
        echo $html;
    }

    /* get stoppage list based on the branch */
    public function getStoppageByBranch()
    {
        $html = "";
        $branchID = $this->application_model->get_branch_id();
        if (!empty($branchID)) {
            $result = $this->db->select('id,stop_position')->where('branch_id', $branchID)->get('transport_stoppage')->result_array();
            if (count($result)) {
                $html .= '<option value="">' . translate('select') . '</option>';
                foreach ($result as $row) {
                    $html .= '<option value="' . $row['id'] . '">' . $row['stop_position'] . '</option>';
                }
            } else {
                $html .= '<option value="">' . translate('no_selection_available') . '</option>';
            }
        } else {
            $html .= '<option value="">' . translate('first_select_the_branch') . '</option>';
        }
        echo $html;
    }

    protected function stoppage_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $this->form_validation->set_rules('stop_position', translate('stoppage'), 'trim|required');
        $this->form_validation->set_rules('stop_time', translate('stop_time'), 'required');
        $this->form_validation->set_rules('route_fare', translate('route_fare'), 'trim|required|numeric');
    }

    /* transport fees type form validation rules */
    protected function fine_validation()
    {
        if (is_superadmin_loggedin()) {
            $this->form_validation->set_rules('branch_id', translate('branch'), 'required');
        }
        $fine_type = $this->input->post('fine_type');
        $this->form_validation->set_rules('month_id', translate('month'), 'trim|required|callback_checkUniqueMonth');
        $this->form_validation->set_rules('due_date', translate('due_date'), 'trim|required');
        $this->form_validation->set_rules('fine_type', translate('fine_type'), 'trim|required');
        if ($fine_type != 0) {
            $this->form_validation->set_rules('fee_frequency', translate('fee_frequency'), 'trim|required');
            $this->form_validation->set_rules('fine_value', translate('fine') . " " . translate('value'), 'trim|required|numeric|greater_than[0]');
        }
    }

    public function checkUniqueMonth($month)
    {
        $fineID = $this->input->post('fine_id');
        $branchID = $this->application_model->get_branch_id();

        if (!empty($fineID)) {
            $this->db->where_not_in('id', $fineID);
        }
        $this->db->where('month', $month);
        $this->db->where('session_id', get_session_id());
        if (!empty($branchID))
            $this->db->where('branch_id', $branchID);
        $query = $this->db->get('transport_fee_fine');
        if ($query->num_rows() > 0) {
            $this->form_validation->set_message("checkUniqueMonth", translate('already_taken'));
            return false;
        } else {
            return true;
        }
    }

    public function fees_setup()
    {
        if (!get_permission('transport_fees_setup', 'is_view')) {
            access_denied();
        }
        $branchID = $this->application_model->get_branch_id();
        if ($_POST) {
            if (!get_permission('transport_fees_setup', 'is_add')) {
                ajax_access_denied();
            }
            $this->fine_validation();
            if ($this->form_validation->run() !== false) {
                if (isset($_POST['apply_for_all_months'])) {
                    for ($i=1; $i < 13; $i++) { 
                        $month = str_pad($i, 2, "0", STR_PAD_LEFT);
                        $insertData = [
                            'month' => $month,
                            'fine_type' => $this->input->post('fine_type'),
                            'fine_value' => empty($this->input->post('fine_value')) ? NULL : $this->input->post('fine_value'),
                            'fee_frequency' => empty($this->input->post('fee_frequency')) ? NULL : $this->input->post('fee_frequency'),
                            'branch_id' => $branchID,
                            'session_id' => get_session_id(),
                        ];
                        $due_date = $this->input->post('due_date');
                        $timestamp = strtotime($due_date);
                        $insertData['due_date'] = date("Y-" . $month  . "-d", $timestamp);

                        $this->db->where('month', $month);
                        $this->db->where('session_id', get_session_id());
                        if (!empty($branchID))
                            $this->db->where('branch_id', $branchID);
                        $query = $this->db->get('transport_fee_fine');
                        if ($query->num_rows() > 0) {
                            $this->db->where('id', $query->row()->id);
                            $this->db->update('transport_fee_fine', $insertData);
                        } else {
                            $this->db->insert('transport_fee_fine', $insertData);
                        }
                    }
                } else {
                    $insertData = [
                        'month' => $this->input->post('month_id'),
                        'due_date' => $this->input->post('due_date'),
                        'fine_type' => $this->input->post('fine_type'),
                        'fine_value' => empty($this->input->post('fine_value')) ? NULL : $this->input->post('fine_value'),
                        'fee_frequency' => empty($this->input->post('fine_type')) ? NULL : $this->input->post('fee_frequency'),
                        'branch_id' => $branchID,
                        'session_id' => get_session_id(),
                    ];
                    $this->db->insert('transport_fee_fine', $insertData);
                }
                set_alert('success', translate('information_has_been_saved_successfully'));
                $array = ['status' => 'success'];
            } else {
                $error = $this->form_validation->error_array();
                $array = ['status' => 'fail', 'error' => $error];
            }
            echo json_encode($array);
            exit();
        }
        $this->data['branch_id'] = $branchID;
        $this->data['title'] = translate('fees_setup');
        $this->data['main_menu'] = 'transport';
        $this->data['sub_page'] = 'transport/fees_setup';
        $this->load->view('layout/index', $this->data);
    }

    public function fees_setup_edit($id = '')
    {
        if (!get_permission('transport_fees_setup', 'is_edit')) {
            access_denied();
        }
        $result = $this->app_lib->getTable('transport_fee_fine', array('t.id' => $id), true);
        if (empty($result)) {
            show_404();
        }
        if ($_POST) {
            $branchID = $this->application_model->get_branch_id();
            $this->fine_validation();
            if ($this->form_validation->run() !== false) {
                $insertData = [
                    'month' => $this->input->post('month_id'),
                    'due_date' => $this->input->post('due_date'),
                    'fine_type' => $this->input->post('fine_type'),
                    'fine_value' => empty($this->input->post('fine_value')) ? NULL : $this->input->post('fine_value'),
                    'fee_frequency' => empty($this->input->post('fine_type')) ? NULL : $this->input->post('fee_frequency'),
                    'branch_id' => $branchID,
                    'session_id' => get_session_id(),
                ];
                $this->db->where('id', $id);
                $this->db->update('transport_fee_fine', $insertData);
                set_alert('success', translate('information_has_been_updated_successfully'));
                $url = base_url('transport/fees_setup');
                $array = array('status' => 'success', 'url' => $url);
            } else {
                $error = $this->form_validation->error_array();
                $array = array('status' => 'fail', 'error' => $error);
            }
            echo json_encode($array);
            exit();
        }
        $this->data['fine'] = $result;
        $this->data['title'] = translate('fees_setup');
        $this->data['sub_page'] = 'transport/fees_setup_edit';
        $this->data['main_menu'] = 'transport';
        $this->load->view('layout/index', $this->data);
    }

    public function getFineListDT()
    {
        if ($_POST) {
            $feeFrequency = array(
                '' => "-",
                '0' => translate('fixed'),
                '1' => translate('daily'),
                '7' => translate('weekly'),
                '30' => translate('monthly'),
                '365' => translate('annually'),
            );
            $arrayFineType = array(
                '0' => translate('no'),
                '1' => translate('fixed_amount'),
                '2' => translate('percentage'),
            );
            $results = $this->transport_model->getTransportFineList();
            $results = json_decode($results);
            $data = array();
            if (!empty($results->data)) {
                foreach ($results->data as $key => $record) {
                    // actions btn
                    $actions = '';
                    if (get_permission('transport_fees_setup', 'is_edit')) {
                        $actions .= '<a href="' . base_url('transport/fees_setup_edit/' . $record->id) . '" class="btn btn-circle btn-default icon"><i class="fas fa-pen-nib"></i></a>';
                    }
                    if (get_permission('transport_fees_setup', 'is_delete')) {
                        $actions .= btn_delete('transport/fine_delete/' . $record->id);
                    }
                    // dt-data array 
                    $row   = array();
                    if (is_superadmin_loggedin()){
                        $row[] = $record->branch_name;
                    }
                    $row[] = $this->app_lib->getMonthslist($record->month);
                    $row[] = _d($record->due_date);;
                    $row[] = $arrayFineType[$record->fine_type];
                    if ($record->fine_type == 0) {
                        $row[] = "-";
                    } elseif ($record->fine_type == 1) {
                        $row[] = currencyFormat($record->fine_value);
                    } else {
                        $row[] = $record->fine_value . "%";
                    }
                    $row[] = $feeFrequency[$record->fee_frequency];
                    $row[] = $actions;
                    $data[] = $row;
                }
            }
            $json_data = array(
                "draw"                => intval($results->draw),
                "recordsTotal"        => intval($results->recordsTotal),
                "recordsFiltered"     => intval($results->recordsFiltered),
                "data"                => $data,
            );
            echo json_encode($json_data);
        }
    }

    public function fine_delete($id)
    {
        if (get_permission('transport_fees_setup', 'is_delete')) {
            if (!is_superadmin_loggedin()) {
                $this->db->where('branch_id', get_loggedin_branch_id());
            }
            $this->db->where('id', $id);
            $this->db->delete('transport_fee_fine');
        }
    }
}

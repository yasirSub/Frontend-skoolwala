<?php
if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class Event_model extends MY_Model
{

    public function __construct()
    {
        parent::__construct();
    }

    function save($data = array())
    {
        $arrayEvent = array(
            'branch_id' => $data['branch_id'],
            'title' => $this->input->post('title'),
            'remark' => $this->input->post('remarks'),
            'type' => $data['type'],
            'audition' => $data['audition'],
            'image' => $data['image'],
            'show_web' => (isset($_POST['show_website']) ? 1 : 0),
            'selected_list' => $data['selected_list'],
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'status' => 1,
        );

        if (isset($data['id']) && !empty($data['id'])) {
            $this->db->where('id', $data['id']);
            $this->db->update('event', $arrayEvent);
        } else {
            $arrayEvent['created_by'] = get_loggedin_user_id();
            $arrayEvent['session_id'] = get_session_id();
            $this->db->insert('event', $arrayEvent);
        }
    }

    public function getEventListDT()
    {
        $this->datatables->select('event.*,staff.name as staff_name');
        $this->datatables->from('event');
        $this->datatables->join('staff', 'staff.id = event.created_by', 'left');
        if (!is_superadmin_loggedin()) {
            $this->datatables->where('event.branch_id', get_loggedin_branch_id());
            $column_order = '';
        } else {
            $column_order = 'event.branch_id,';
        }
        $this->datatables->search_value('event.title,staff.name,event.start_date,event.end_date');
        $this->datatables->column_order('event.id,'.$column_order.'event.title,event.image,event.type,event.start_date,event.end_date,event.audition,staff.name');
        $this->datatables->order_by('event.id', 'asc');
        $results = $this->datatables->generate();
        $records = array();
        $records = json_decode($results);
        $data = array();
        $start = $this->input->post('start');
        $count = $start + 1;
        foreach ($records->data as $key => $record) {
            $event_types = "";
            if($record->type != 'holiday'){
                $event_types = get_type_name_by_id('event_types', $record->type);
            }else{
                $event_types = translate('holiday'); 
            }
            $auditions = array(
                "1" => "everybody",
                "2" => "class",
                "3" => "section",
            );
            $audition = $auditions[$record->audition];
            $aud = translate($audition);
            if($record->audition != 1){
                if ($record->audition == 2) {
                    $selecteds = json_decode($record->selected_list); 
                    foreach ($selecteds as $selected) {
                        $aud .= "<small class='text-muted bs-block'> - " . get_type_name_by_id('class', $selected) . '</small>' ;
                    }
                }
                if ($record->audition == 3) {
                    $selecteds = json_decode($record->selected_list); 
                    foreach ($selecteds as $selected) {
                        $selected = explode('-', $selected);
                        $aud .= "<small class='text-muted bs-block'> - " . get_type_name_by_id('class', $selected[0]) . " (" . get_type_name_by_id('section', $selected[1])  . ')</small>' ;
                    }
                }
            }
            $actions = '<button class="btn btn-circle icon btn-default icon" data-loading-text="<i class=\'fas fa-spinner fa-spin\'></i>" onclick="viewEvent(' . "'" . $record->id . "'" . ', this)"><i class="far fa-eye"></i></button>';
            // edit link
            if (get_permission('event', 'is_edit')) {
                $actions .= '<a href="'.base_url('event/edit/'.$record->id).'" class="btn btn-circle btn-default icon"><i class="fas fa-pen-nib"></i></a>';
            }
            // deletion link
            if (get_permission('event', 'is_delete')) {
                $actions .=  btn_delete('event/delete/'.$record->id);
            }
            // dt-data array 
            $row   = array();
            $row[] = $count++;
if (is_superadmin_loggedin()) {
            $row[] = get_type_name_by_id('branch', $record->branch_id);
}
            $row[] = $record->title;
            $row[] = '<img src="'.base_url('uploads/frontend/events/' . $record->image ).'" height="60" />';
            $row[] = $event_types;
            $row[] = _d($record->start_date);
            $row[] = _d($record->end_date);
            $row[] = $aud;
            $row[] = $record->staff_name;

if (get_permission('event', 'is_edit')) {
            $row[] = '<div class="material-switch ml-xs">
                        <input class="event-website" id="websiteswitch_'.$record->id.'" data-id="'.$record->id.'" name="evt_switch_website'.$record->id.'" 
                        type="checkbox" '.($record->show_web == 1 ? 'checked' : '').'/>
                        <label for="websiteswitch_'.$record->id.'" class="label-primary"></label>
                    </div>';
            $row[] = '<div class="material-switch ml-xs">
                        <input class="event-switch" id="switch_'.$record->id.'" data-id="'.$record->id.'" name="evt_switch'.$record->id.'" 
                        type="checkbox" '.($record->status == 1 ? 'checked' : '').'/>
                        <label for="switch_'.$record->id.'" class="label-primary"></label>
                    </div>';
} else {
            $row[] = '-';
            $row[] = '-';
}
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
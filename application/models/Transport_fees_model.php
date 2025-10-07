<?php
if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class Transport_fees_model extends MY_Model
{
    public function __construct()
    {
        parent::__construct();
    }

    public function getStudentTransportFeesByEnroll($enroll_id = '', $stoppage_point_id = '', $branchID = '')
    {
        if (!empty($enroll_id)) {
            $this->db->select('transport_fee_fine.*,IFNULL(transport_fee_details.id, 0) as fee_details_id');
            $this->db->from('transport_fee_fine');
            if (!empty($stoppage_point_id)) {
                $this->db->join('transport_fee_details', 'transport_fee_details.transport_fee_fine_id = transport_fee_fine.id and transport_fee_details.stoppage_point_id = ' . $stoppage_point_id . ' and transport_fee_details.enroll_id = ' . $enroll_id, 'left');
            } else {
                $this->db->join('transport_fee_details', 'transport_fee_details.transport_fee_fine_id = transport_fee_fine.id and transport_fee_details.enroll_id = ' . $enroll_id, 'left');
            }
            $this->db->where('transport_fee_fine.session_id', get_session_id());
            $this->db->where('transport_fee_fine.branch_id', $branchID);
            $this->db->order_by('transport_fee_fine.month', 'asc');
            return $this->db->get()->result();
        }
        return [];
    }

    public function feeAssignUpdate($data_insert, $enroll_id)
    {
        if (!empty($data_insert)) {
            $not_in_row = array();
            foreach ($data_insert as $insert_key => $insert_value) {
                $this->db->where('enroll_id', $enroll_id);
                $this->db->where('stoppage_point_id', $insert_value['stoppage_point_id']);
                $this->db->where('transport_fee_fine_id', $insert_value['transport_fee_fine_id']);
                $q = $this->db->get('transport_fee_details');
                if ($q->num_rows() > 0) {
                    $not_in_row[] = $q->row()->id;
                } else {
                    $this->db->insert('transport_fee_details', $data_insert[$insert_key]);
                    $not_in_row[] = $this->db->insert_id();
                }
            }
            $this->db->where('enroll_id', $enroll_id);
            $this->db->where_not_in('id', $not_in_row);
            $this->db->delete('transport_fee_details');
        }
    }
}

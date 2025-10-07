<?php
if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

class Offline_payments_model extends MY_Model
{
    public function __construct()
    {
        parent::__construct();
    }

    public function typeSave($data = array())
    {
        $arrayData = array(
            'branch_id' => $this->application_model->get_branch_id(),
            'name' => $data['type_name'],
            'note' => $data['note'],
        );
        if (!isset($data['type_id'])) {
            $this->db->insert('offline_payment_types', $arrayData);
        } else {
            $this->db->where('id', $data['type_id']);
            $this->db->update('offline_payment_types', $arrayData);
        }
    }

    public function getOfflinePaymentsList($where = array(), $single = false)
    {
        $this->db->select('op.*,CONCAT_WS(" ",student.first_name, student.last_name) as fullname,student.email,student.mobileno,student.register_no,class.name as class_name,section.name as section_name,branch.name as branchname');
        $this->db->from('offline_fees_payments as op');
        $this->db->join('enroll', 'enroll.id = op.student_enroll_id', 'inner');
        $this->db->join('branch', 'branch.id = enroll.branch_id', 'left');
        $this->db->join('student', 'student.id = enroll.student_id', 'left');
        $this->db->join('class', 'class.id = enroll.class_id', 'left');
        $this->db->join('section', 'section.id = enroll.section_id', 'left');
        if (!is_superadmin_loggedin()) {
            $this->db->where('enroll.branch_id', get_loggedin_branch_id());
        }
        if (!empty($where)) {
            foreach ($where as $key => $value) {
                if (!empty($value)) {
                    $this->db->where($key, $value);
                }
            }
        }
        if ($single == true) {
            $result = $this->db->get()->row_array();
        } else {
            $this->db->order_by('op.id', 'ASC');
            $result = $this->db->get()->result();
        }
        return $result;
    }

    public function update($id = '')
    {
        $r = $this->db->where('id', $id)->get('offline_fees_payments')->row();
        $arrayFees = array(
            'allocation_id' => $r->fees_allocation_id,
            'type_id' => $r->fees_type_id,
            'amount' => $r->amount,
            'fine' => $r->fine,
            'collect_by' => "",
            'discount' => 0,
            'pay_via' => 15,
            'collect_by' => 'online',
            'remarks' => "Fees deposits via offline Payments Trx ID: " . $id,
            'date' => date("Y-m-d"),
        );
        // transport fees data processing
        if (!empty($r->transport_fee_details_id)) {
            $arrayFees['allocation_id'] = NULL;
            $arrayFees['type_id'] = NULL;
            $arrayFees['transport_fee_details_id'] = $r->transport_fee_details_id;
        }

        // insert in DB
        $this->db->insert('fee_payment_history', $arrayFees);

        // transaction voucher save function
        $getSeeting = $this->fees_model->get('transactions_links', array('branch_id' => get_loggedin_branch_id()), true);
        if ($getSeeting['status']) {
            $arrayTransaction = array(
                'account_id' => $getSeeting['deposit'],
                'amount' => $arrayFees['amount'] + $arrayFees['fine'],
                'date' => $arrayFees['date'],
            );
            $this->fees_model->saveTransaction($arrayTransaction);
        }
    }
}

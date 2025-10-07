<?php 
    // system fields validation rules
    $validArr = array();
    $validationArr = $this->student_fields_model->getStatusArr($branch_id);
    foreach ($validationArr as $key => $value) {
        $validArr[$value->prefix] = (empty($value->status) ? 0 : 1);
    }
?>
<thead>
	<tr>
		<th width="10" class="no-sort no-export">
			<div class="checkbox-replace">
				<label class="i-checks"><input type="checkbox" id="selectAllchkbox"><i></i></label>
			</div>
		</th>
<?php if ($validArr['student_photo']) { ?>
		<th class="no-sort"><?=translate('photo')?></th>
<?php } ?>
		<th><?=translate('name')?></th>
		<th><?=translate('class')?></th>
		<th><?=translate('section')?></th>
<?php if ($validArr['gender']) { ?>
		<th><?=translate('gender')?></th>
<?php } if ($validArr['student_mobile_no']) { ?>
		<th><?=translate('mobile_no')?></th>
<?php } ?>
		<th><?=translate('register_no')?></th>
<?php if ($validArr['roll']) { ?>
		<th width="80"><?=translate('roll')?></th>
<?php } ?>
		<th><?=translate('age')?></th>
		<th><?=translate('guardian_name')?></th>
	<?php
	$show_custom_fields = custom_form_table('student', $branch_id);
	if (count($show_custom_fields)) {
		foreach ($show_custom_fields as $fields) {
	?>
		<th><?=$fields['field_label']?></th>
	<?php } } ?>
		<th class="no-sort no-export"><?=translate('fees_progress')?></th>
		<th><?=translate('action')?></th>
	</tr>
</thead>
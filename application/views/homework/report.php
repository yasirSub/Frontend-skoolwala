<?php $widget = (is_superadmin_loggedin() ? 3 : 4); ?>
<div class="row">
	<div class="col-md-12">
		<section class="panel">
		<?php echo form_open($this->uri->uri_string(), array('class' => 'search_form'));?>
			<header class="panel-heading">
				<h4 class="panel-title"><?=translate('select_ground')?></h4>
			</header>
			<div class="panel-body">
				<div class="row mb-sm">
					<?php if (is_superadmin_loggedin()): ?>
					<div class="col-md-3 mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('branch')?> <span class="required">*</span></label>
							<?php
								$arrayBranch = $this->app_lib->getSelectList('branch');
								echo form_dropdown("branch_id", $arrayBranch, set_value('branch_id'), "class='form-control' id='branch_id'
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<?php endif; ?>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('class')?> <span class="required">*</span></label>
							<?php
								$arrayClass = $this->app_lib->getClass($branch_id);
								echo form_dropdown("class_id", $arrayClass, set_value('class_id'), "class='form-control' id='class_id' onchange='getSectionByClass(this.value,0)'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('section')?></label>
							<?php
								$arraySection = $this->app_lib->getSections(set_value('class_id'), false);
								echo form_dropdown("section_id", $arraySection, set_value('section_id'), "class='form-control' id='section_id'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?>">
						<div class="form-group">
							<label class="control-label"><?=translate('subject')?></label>
							<?php
								if(!empty(set_value('class_id'))) {
									$arraySubject = array("" => translate('select'));
									$query = $this->subject_model->getSubjectByClassSection(set_value('class_id'), set_value('section_id'));
									$subjects = $query->result_array();
									foreach ($subjects as $row){
										$subjectID = $row['subject_id'];
										$arraySubject[$subjectID] = $row['subjectname'] . " (" . $row['subject_code'] . ")";
									}
								} else {
									$arraySubject = array("" => translate('select_class_first'));
								}
								echo form_dropdown("subject_id", $arraySubject, set_value('subject_id'), "class='form-control' id='subject_id'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
				</div>
			</div>
			<footer class="panel-footer">
				<div class="row">
					<div class="col-md-offset-10 col-md-2">
						<button type="submit" name="search" value="1" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing" class="btn btn btn-default btn-block"> <i class="fas fa-filter"></i> <?=translate('filter')?></button>
					</div>
				</div>
			</footer>
			<?php echo form_close();?>
		</section>
		
		<section class="panel appear-animation" data-appear-animation-type="<?php echo $global_config['animations'];?>" data-appear-animation-delay="100">
			<header class="panel-heading">
				<h4 class="panel-title"><i class="fas fa-list"></i> <?=translate('evaluation_report')?></h4>
			</header>
			<div class="panel-body">
				<div class="export_title"><?=translate('evaluation_report')?></div>
				<table class="table table-bordered table-condensed" id="homeworkReports" width="100%">
					<thead>
						<tr>
							<th><?=translate('sl')?></th>
							<th><?=translate('subject')?></th>
							<th><?=translate('class')?></th>
							<th><?=translate('section')?></th>
							<th><?=translate('date_of_homework')?></th>
							<th><?=translate('date_of_submission')?></th>
							<th class="no-sort"><?=translate('complete')?>/<?=translate('incomplete')?></th>
							<th class="no-sort"><?=translate('total') .' '. translate('student')?></th>
							<th><?=translate('action')?></th>
						</tr>
					</thead>
				</table>
			</div>
			<?php echo form_close(); ?>
		</section>
	</div>
</div>

<div class="zoom-anim-dialog modal-block modal-block-full mfp-hide" id="modal">
	<section class="panel">
		<header class="panel-heading">
			<h4 class="panel-title"><i class="fas fa-bars"></i> <?php echo translate('view_report') . " " . translate('details') ?></h4>
		</header>
		<div class="panel-body">
			<table class="table table-bordered table-condensed" id="tableReport" width="100%">
				<thead>
					<tr>
						<th><?=translate('sl')?></th>
						<th><?=translate('student')?></th>
						<th><?=translate('class')?></th>
						<th><?=translate('gender')?></th>
						<th><?=translate('register_no')?></th>
						<th><?=translate('mobile_no')?></th>
						<th><?=translate('subject')?></th>
						<th><?=translate('status')?></th>
						<th><?=translate('rank_out_of_5')?></th>
						<th><?=translate('remarks')?></th>
					</tr>
				</thead>
			</table>
		</div>
		<footer class="panel-footer">
			<div class="row">
				<div class="col-md-12 text-right">
					<button class="btn btn-default modal-dismiss"><?php echo translate('close'); ?></button>
				</div>
			</div>
		</footer>
	</section>
</div>

<script type="text/javascript">
	var searchBtn = "";
	var cusDataTable = "";
	var cusDataTable_Report = "";
	var homework_id = "";
	$(document).ready(function () {
		let filter = function (d) {
			d.branch_id = $('#branch_id').val();
			d.class_id = $('#class_id').val();
			d.section_id = $('#section_id').val();
			d.subject_id = $('#subject_id').val();
			d.submit_btn = searchBtn;
		};
		let filter_report = function (d) {
			d.homework_id = homework_id;
		};
		cusDataTable = initDatatable("#homeworkReports", "homework/getHomeworkReportListDT", filter);
		// get evaluation report
		cusDataTable_Report = initDatatable("#tableReport", "homework/evaluateDetails", filter_report);
        $("form.search_form").on('submit', function(e){
        	var $this = $(this);
            e.preventDefault();
            var btn = $this.find('[type="submit"]');
            $.ajax({
                url: $(this).attr('action'),
                type: "POST",
                data: $(this).serialize(),
                dataType: 'json',
                beforeSend: function () {
                    btn.button('loading');
                },
                success: function (data) {
					$('.error').html("");
					if (data.status == "fail") {
						animation_panel_hide();
						$.each(data.error, function (index, value) {
							$this.find("[name='" + index + "']").parents('.form-group').find('.error').html(value);
						});
					} else {
						/*
						if (searchBtn == "") {
							cusDataTable.columns.adjust();
						}*/
						$(".export_title").html(data.export_title);
						searchBtn = 1;
						branch_ID = $('#branch_id').val();
						animation_panel_show();
						cusDataTable.draw();
					}
                },
                complete: function (data) {
                    btn.button('reset');
                },
                error: function () {
                    btn.button('reset');
                }
            });
        });

		$('#branch_id').on('change', function() {
			var branchID = $(this).val();
			getClassByBranch(branchID);
			$('#subject_id').html('').append('<option value=""><?=translate("select")?></option>');
		});

		$('#section_id').on('change', function() {
			var classID = $('#class_id').val();
			var sectionID =$(this).val();
			$.ajax({
				url: base_url + 'subject/getByClassSection',
				type: 'POST',
				data: {
					classID: classID,
					sectionID: sectionID
				},
				success: function (data) {
					$('#subject_id').html(data);
				}
			});
		});
	});

	function getReport(id, ele) {
		var btn = $(ele);
		btn.button('loading');
		homework_id = id;
		cusDataTable_Report.ajax.reload(function(data) {
			mfp_modal('#modal');
			btn.button('reset');
		});
	}
</script>	
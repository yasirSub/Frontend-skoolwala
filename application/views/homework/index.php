<?php $widget = (is_superadmin_loggedin() ? 3 : 4); ?>
<div class="row">
	<div class="col-md-12">
		<section class="panel">
		<?php echo form_open($this->uri->uri_string(), array('class' => 'search_form'));?>
			<header class="panel-heading">
				<h4 class="panel-title"><?=translate('select_ground')?></h4>
			<?php if (get_permission('homework', 'is_add')): ?>
				<div class="panel-btn">
					<a href="<?=base_url('homework/add')?>" id="addLeave" class="btn btn-default btn-circle" >
						<i class="fas fa-plus-circle"></i> <?=translate('add') . " " . translate('homework')?>
					</a>
				</div>
			<?php endif; ?>
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
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('section')?></label>
							<?php
								$arraySection = $this->app_lib->getSections(set_value('class_id'), false);
								echo form_dropdown("section_id", $arraySection, set_value('section_id'), "class='form-control' id='section_id' data-plugin-selectTwo data-width='100%'");
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
								echo form_dropdown("subject_id", $arraySubject, set_value('subject_id'), "class='form-control' id='subject_id' data-plugin-selectTwo data-width='100%'");
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
				<h4 class="panel-title"><i class="fas fa-list"></i> <?=translate('homework')?></h4>
			</header>
			<div class="panel-body">
				<div class="export_title"><?=translate('homework') . " " . translate('list')?></div>
				<table class="table table-bordered table-condensed" id="homeworkList" width="100%">
					<thead>
						<tr>
							<th><?=translate('sl')?></th>
							<th><?=translate('subject')?></th>
							<th><?=translate('class')?></th>
							<th><?=translate('section')?></th>
							<th><?=translate('date_of_homework')?></th>
							<th><?=translate('date_of_submission')?></th>
							<th><?=translate('sms_notification')?></th>
							<th><?=translate('status')?></th>
							<th><?=translate('scheduled_at')?></th>
							<th><?=translate('created_by')?></th>
							<th><?=translate('action')?></th>
						</tr>
					</thead>
				</table>
			</div>
			<?php echo form_close(); ?>
		</section>
	</div>
</div>

<div class="zoom-anim-dialog modal-block modal-block-lg mfp-hide" id="modal">
	<section class="panel">
		<header class="panel-heading">
			<h4 class="panel-title"><i class="fas fa-bars"></i> <?php echo translate('evaluate'); ?></h4>
		</header>
		<div class="panel-body">
			<div id='quick_view'></div>
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
	$(document).ready(function () {
		let filter = function (d) {
			d.branch_id = $('#branch_id').val();
			d.class_id = $('#class_id').val();
			d.section_id = $('#section_id').val();
			d.subject_id = $('#subject_id').val();
			d.submit_btn = searchBtn;
		};
		cusDataTable = initDatatable("#homeworkList", "homework/getHomeworkListDT", filter);
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

	// get details
	function getEvaluate(id,elem) {
		var btn = $(elem);
	    $.ajax({
	        url: base_url + 'homework/evaluateModal',
	        type: 'POST',
	        data: {'homework_id': id},
	        dataType: "html",
	        beforeSend: function () {
	            btn.button('loading');
	        },
	        success: function (data) {
	            $('#quick_view').html(data);
	            mfp_modal('#modal');
	        },
	        error: function (xhr) {
	            btn.button('reset');
	        },
	        complete: function () {
	            btn.button('reset');

	        }
	    });
	}
</script>	
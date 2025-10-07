<div class="row">
	<div class="col-md-8">
		<section class="panel pg-fw">
			<div class="panel-body">
				<h5 class="chart-title mb-xs"><?php echo translate('homework') . " " . translate('details'); ?></h5>
				<div class="mt-lg">
					<p><?php echo $homework->description; ?></p>

				</div>
			</div>
		</section>
<?php 
$date_of_submission = strtotime($homework->date_of_submission);
$today = strtotime(date('Y-m-d'));
if($homework->ev_status !== 'c' && $date_of_submission >= $today) {
	?>
		<section class="panel pg-fw">
			<div class="panel-body">
				<h5 class="chart-title mb-xs"><?php echo translate('submit') . " " . translate('assignment') ?></h5>
				<div class="mt-lg">
				<?php echo form_open_multipart('userrole/assignment_upload', array('class' => 'frm-assigment'));?>
			        <input type="hidden" id="homeworkID"  name="homework_id" value="<?php echo $homework->id ?>">
			        <input type="hidden" id="assigmentID" name="assigment_id" value="<?php echo $homework->hs_id ?>">
					<div class="form-group">
						<label class="control-label"><?php echo translate('attachment_file') ?> </label>
						<div class="row">
							<div class="col-md-12">
								<div class="fileupload fileupload-new" data-provides="fileupload">
									<div class="input-append">
										<div class="uneditable-input">
											<i class="fas fa-file fileupload-exists"></i>
											<span class="fileupload-preview"></span>
										</div>
										<span class="btn btn-default btn-file">
											<span class="fileupload-exists">Change</span>
											<span class="fileupload-new">Select file</span>
											<input type="file" name="attachment_file" value="" />
										</span>
										<a href="#" class="btn btn-default fileupload-exists" data-dismiss="fileupload">Remove</a>
									</div>
								</div>
								<span class="error"></span>
							</div>
						</div>
						<input type="hidden" id="old_file" name="old_file" value="<?php echo $homework->enc_name ?>">
					</div>
					<div class="form-group mb-md">
						<label class="control-label"><?php echo translate('message') ?> <span class="required">*</span></label>
						<textarea name="message" id="message" rows="4" autocomplete="off"  class="form-control"><?php echo $homework->message ?></textarea>
						<span class="error"></span>
					</div>
					<button type="submit" class="btn btn-default" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing"><?php echo empty($homework->hs_id) ? translate('submit') : translate('re_submit'); ?></button>
				<?php echo form_close(); ?>
				</div>
			</div>
		</section>
<?php } ?>
	</div>
	<div class="col-md-4">
		<ul class="nav nav-stacked">
			<li><i class="far fa-calendar"></i> <span class="text-weight-semibold"><?=translate('date_of_homework')?></span> : <?=_d($homework->date_of_homework)?></li>
			<li><i class="far fa-calendar"></i> <span class="text-weight-semibold"><?=translate('date_of_submission')?></span> : <?=_d($homework->date_of_submission)?></li>
			<li><i class="far fa-calendar"></i> <span class="text-weight-semibold"><?=translate('evaluation_date')?></span> : <?=$homework->evaluation_date != null ? _d($homework->evaluation_date) : "N/A";?></li>
			<li><span class="text-weight-semibold"><?=translate('created_by')?></span> : <?=$homework->created_by != null ? get_type_name_by_id('staff', $homework->created_by) : "N/A";?></li>
			<li><span class="text-weight-semibold"><?=translate('status')?></span> : <?php 
			if ($homework->ev_status == 'u' || $homework->ev_status == '') {
				if (empty($homework->hs_id) || $homework->ev_status == 'u') {
					$labelmode = 'label-danger-custom';
					$status = translate('incomplete');
				} else {
					$labelmode = 'label-info-custom';
					$status = translate('submitted');
				}
			} else {
				$status = translate('complete');
				$labelmode = 'label-success-custom';
			}
			echo "<span class='value label " . $labelmode . " '>" . $status . "</span>";
			 ?></li>
			<li><span class="text-weight-semibold"><?=translate('evaluated_by')?></span> : <?=!empty($homework->evaluated_by) ? get_type_name_by_id('staff',$homework->evaluated_by) : "N/A";?></li>
			<li><span class="text-weight-semibold"><?=translate('rank_out_of_5')?></span> : <?=!empty($homework->rank) ? $homework->rank : "N/A";?></li>
			<li><span class="text-weight-semibold"><?=translate('remarks')?></span> : <?=!empty($homework->ev_remarks) ? $homework->ev_remarks : "N/A";?></li>
		</ul>
		<ul class="nav nav-stacked mt-md">
			<li><span class="text-weight-semibold"><?=translate('subject')?></span> : <?=$homework->subject_name?></li>
			<li><span class="text-weight-semibold"><?=translate('class')?></span> : <?=$homework->class_name?></li>
			<li><span class="text-weight-semibold"><?=translate('section')?></span> : <?=$homework->section_name?></li>
<?php if (!empty($homework->document)) { ?>
			<li><span class="text-weight-semibold"><?=translate('documents')?></span> : <a href="<?=base_url('homework/download/' . $homework->id)?>" style="display: initial;" class="btn btn-default btn-circle icon" data-toggle="tooltip" data-original-title="<?=translate('download')?>"><i class="fas fa-cloud-download-alt"></i></a></li>
<?php } ?>
		</ul>
	<?php if (!empty($homework->enc_name)) { ?>
		<ul class="nav nav-stacked mt-md">
			<li><span class="text-weight-semibold"><?=translate('submitted_file')?></span> : <a href="<?=base_url('homework/download_submitted?file=' . $homework->enc_name)?>" style="display: initial;" class="btn btn-default btn-circle icon" data-toggle="tooltip" data-original-title="<?=translate('download')?>"><i class="fas fa-cloud-download-alt"></i></a></li>
		</ul>
	<?php } ?>
	</div>
</div>

<script type="text/javascript">
    $("form.frm-assigment").on('submit', function(e){
        e.preventDefault();
        var $this = $(this);
        var btn = $this.find('[type="submit"]');
        
        $.ajax({
            url: $(this).attr('action'),
            type: "POST",
            data: new FormData(this),
            dataType: "json",
            contentType: false,
            processData: false,
            cache: false,
            beforeSend: function () {
                btn.button('loading');
            },
            success: function (data) {
                console.log(data.error);
                $('.error').html("");
                if (data.status == "fail") {
                    $.each(data.error, function (index, value) {
                        $this.find("[name='" + index + "']").parents('.form-group').find('.error').html(value);
                    });
                    btn.button('reset');
                } else if (data.status == "access_denied") {
                    window.location.href = base_url + "dashboard";
                } else {
                    location.reload(true);
                }
            },
            error: function () {
                btn.button('reset');
            }
        });
    });
</script>
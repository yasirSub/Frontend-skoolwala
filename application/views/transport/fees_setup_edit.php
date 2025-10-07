<?php 
$status = $fine['fine_type'] == 0 ? 'disabled' : '';
 ?>
<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li>
				<a href="<?=base_url('transport/fees_setup')?>"><i class="fas fa-list-ul"></i> <?php echo translate('fees') . " " . translate('list'); ?></a>
			</li>
			<li class="active">
				<a href="#create" data-toggle="tab"><i class="far fa-edit"></i> <?php echo translate('edit') . " " . translate('fees'); ?></a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="tab-pane active" id="create">
				<?php echo form_open($this->uri->uri_string(), array('class' => 'form-horizontal form-bordered frm-submit')); ?>
					<input type="hidden" name="fine_id" value="<?=$fine['id']?>">
					<?php if (is_superadmin_loggedin() ): ?>
					<div class="form-group">
						<label class="control-label col-md-3"><?=translate('branch')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<?php
								$arrayBranch = $this->app_lib->getSelectList('branch');
								echo form_dropdown("branch_id", $arrayBranch, $fine['branch_id'], "class='form-control' id='branch_id'
								data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<?php endif; ?>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('month'); ?> <span class="required">*</span></label>
						<div class="col-md-6">
							<?php
								$arrayGroup = $this->app_lib->getMonthslist();
								echo form_dropdown("month_id", $arrayGroup, set_value('month_id', $fine['month']), "class='form-control'
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('due_date'); ?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="due_date" value="<?php echo set_value('due_date', $fine['due_date']) ?>" data-plugin-datepicker
							data-plugin-options='{"startView": 1}' autocomplete="off" />
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('fine_type'); ?></label>
						<div class="col-md-6">
							<?php
								$arrayFine = array(
									'' => translate('select'),
									'0' => translate('no'),
									'1' => translate('fixed_amount'),
									'2' => translate('percentage'),
								);
								echo form_dropdown("fine_type", $arrayFine, set_value('due_date', $fine['fine_type']), "class='form-control' id='fineType'
								data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('fine') . " " . translate('value'); ?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" <?php echo $status; ?> name="fine_value" id="fine_value" value="<?=$fine['fine_value']?>" autocomplete="off" />
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('late_fee_frequency'); ?></label>
						<div class="col-md-6 mb-md">
							<?php
								$feeFrequency = array(
									'' => translate('select'),
									'0' => translate('fixed'),
									'1' => translate('daily'),
									'7' => translate('weekly'),
									'30' => translate('monthly'),
									'365' => translate('annually'),
								);
								echo form_dropdown("fee_frequency", $feeFrequency, $fine['fee_frequency'], "class='form-control' id='feeFrequency' $status
								data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<footer class="panel-footer">
						<div class="row">
							<div class="col-md-2 col-md-offset-3">
								<button type="submit" class="btn btn-default btn-block" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
									<i class="fas fa-plus-circle"></i> <?php echo translate('update'); ?>
								</button>
							</div>
						</div>	
					</footer>
				<?php echo form_close(); ?>
			</div>
		</div>
	</div>
</section>
<script>
	$("#fineType").on("change", function() {	
		if ($(this).val() == 0) {
			$('#feeFrequency').val("").prop('disabled', true).trigger('change');
			$('#fine_value').val("").prop('disabled', true);
		} else {
			$('#feeFrequency').prop('disabled', false);
			$('#fine_value').prop('disabled', false);
		}
	});
</script>
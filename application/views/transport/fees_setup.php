<?php $currency_symbol = $global_config['currency_symbol']; ?>
<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li class="active">
				<a href="#list" data-toggle="tab"><i class="fas fa-list-ul"></i> <?php echo translate('fees') . " " . translate('list'); ?></a>
			</li>
<?php if (get_permission('transport_fees_setup', 'is_add')){ ?>
			<li>
				<a href="#create" data-toggle="tab"><i class="far fa-edit"></i> <?php echo translate('add') . " " . translate('fees'); ?></a>
			</li>
<?php } ?>
		</ul>
		<div class="tab-content">
			<div id="list" class="tab-pane active">
				<div class="mb-md">
					<div class="export_title"><?php echo translate('transport') . " " .  translate('fine') . " " . translate('list'); ?></div>
					<table class="table table-bordered table-hover table-condensed" id="transport-fine-list" cellpadding="0" cellspacing="0" width="100%">
						<thead>
							<tr>
							<?php if (is_superadmin_loggedin()): ?>
								<th><?=translate('branch')?></th>
							<?php endif; ?>
								<th><?=translate('month')?></th>
								<th><?=translate('due_date')?></th>
								<th><?=translate('fine_type')?></th>
								<th><?=translate('fine_value')?></th>
								<th><?=translate('late_fee_frequency')?></th>
								<th><?=translate('action')?></th>
							</tr>
						</thead>
					</table>
				</div>
			</div>
<?php if (get_permission('transport_fees_setup', 'is_add')){ ?>
			<div class="tab-pane" id="create">
				<?php echo form_open($this->uri->uri_string(), array('class' => 'form-horizontal form-bordered frm-submit')); ?>
					<?php if (is_superadmin_loggedin() ): ?>
					<div class="form-group">
						<label class="control-label col-md-3"><?=translate('branch')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<?php
								$arrayBranch = $this->app_lib->getSelectList('branch');
								echo form_dropdown("branch_id", $arrayBranch, set_value('branch_id'), "class='form-control' id='branch_id'
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
								echo form_dropdown("month_id", $arrayGroup, set_value('month_id'), "class='form-control'
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('due_date'); ?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="due_date" value="" data-plugin-datepicker
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
								echo form_dropdown("fine_type", $arrayFine, set_value('branch_id'), "class='form-control' id='fineType'
								data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('fine') . " " . translate('value'); ?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="fine_value" id="fine_value"  value="<?=set_value('fine_value')?>" autocomplete="off" />
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?php echo translate('late_fee_frequency'); ?> <span class="required">*</span></label>
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
								echo form_dropdown("fee_frequency", $feeFrequency, set_value('branch_id'), "class='form-control' id='feeFrequency'
								data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="form-group">
						<div class="col-md-offset-3 col-md-6 mb-lg">
							<div class="checkbox-replace">
								<label class="i-checks"><input type="checkbox" name="apply_for_all_months" id="freeTrial" value="1"><i></i> This Details Apply For All Months</label>
							</div>
						</div>
					</div>
					<footer class="panel-footer">
						<div class="row">
							<div class="col-md-2 col-md-offset-3">
								<button type="submit" class="btn btn-default btn-block" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
									<i class="fas fa-plus-circle"></i> <?php echo translate('save'); ?>
								</button>
							</div>
						</div>	
					</footer>
				<?php echo form_close(); ?>
			</div>
<?php } ?>
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
	var cusDataTable = '';
	$(document).ready(function () {
		cusDataTable = initDatatable('#transport-fine-list', 'transport/getFineListDT');
	});
</script>
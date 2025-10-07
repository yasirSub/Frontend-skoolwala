<?php $currency_symbol = $global_config['currency_symbol']; ?>
<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li class="active">
				<a href="#list" data-toggle="tab"><i class="fas fa-list-ul"></i> <?=translate('route_list')?></a>
			</li>
<?php if (get_permission('transport_route', 'is_add')): ?>
			<li>
				<a href="#create" data-toggle="tab"><i class="far fa-edit"></i> <?=translate('create_route')?></a>
			</li>
<?php endif; ?>
		</ul>
		<div class="tab-content">
			<div id="list" class="tab-pane active">
				<table class="table table-bordered table-hover table-condensed mb-none table-export">
					<thead>
						<tr>
							<th><?=translate('sl')?></th>
						<?php if (is_superadmin_loggedin()): ?>
							<th><?=translate('branch')?></th>
						<?php endif; ?>
							<th><?=translate('route_name')?></th>
							<th><?=translate('start_place')?></th>
							<th><?=translate('stop_place')?></th>
							<th><?=translate('stoppage')?></th>
							<th><?=translate('remarks')?></th>
							<th><?=translate('action')?></th>
						</tr>
					</thead>
					<tbody>
					<?php
					$count = 1;
					foreach ($transportlist as $row):
						?>
						<tr>
							<td><?php echo $count++; ?></td>
						<?php if (is_superadmin_loggedin()): ?>
							<td><?php echo $row['branch_name']; ?></td>
						<?php endif; ?>
							<td><?php echo $row['name'];?></td>
							<td><?php echo $row['start_place'];?></td>
							<td><?php echo $row['stop_place'];?></td>
							<td><?php 
								$stoppages = $this->transport_model->stoppage_pointByRoute($row['id']);
								foreach ($stoppages as $skey => $sval) {
									echo $sval->stop_position . "<small class='text-muted bs-block'> - " . translate('route_fare') . ": " . currencyFormat($sval->route_fare) . " / " . translate('stop_time') . ": " . date("g:i A", strtotime($sval->stop_time)) . "</small>";
								} ?></td>
							<td><?php echo $row['remarks'];?></td>
							<td>
							<?php if (get_permission('transport_route', 'is_edit')): ?>
								<!--update link-->
								<a href="<?php echo base_url('transport/route_edit/' . $row['id']);?>" class="btn btn-default btn-circle icon">
									<i class="fas fa-pen-nib"></i>
								</a>
							<?php endif; if (get_permission('transport_route', 'is_add')): ?>
								<!-- delete link -->
								<?php echo btn_delete('transport/route_delete/' . $row['id']);?>
							<?php endif; ?>
							</td>
						</tr>
						<?php endforeach;?>
					</tbody>
				</table>
			</div>
<?php if (get_permission('transport_route', 'is_add')): ?>
			<div class="tab-pane" id="create">
				<?php echo form_open($this->uri->uri_string(), array('class' => 'frm-submit'));?>
				<div class="mt-lg form-horizontal form-bordered">
<?php if (is_superadmin_loggedin()): ?>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('branch')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<?php
								$arrayBranch = $this->app_lib->getSelectList('branch');
								echo form_dropdown("branch_id", $arrayBranch, "", "class='form-control' id='branchID' data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity'");
							?>
							<span class="error"></span>
						</div>
					</div>
<?php endif; ?>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('route_name')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="route_name" autocomplete="off" value="" />
							<span class="error"></span>
						</div>
					</div>

					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('start_place')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="start_place" value="" />
							<span class="error"></span>
						</div>
					</div>

					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('stop_place')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="stop_place" value="" />
							<span class="error"></span>
						</div>
					</div>

					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('remarks')?></label>
						<div class="col-md-6 mb-md">
							<textarea class="form-control" rows="2" name="remarks"></textarea>
						</div>
					</div>
				</div>
				<div id="purchaseItems" class="mt-lg" style="<?php echo (empty($branch_id) ? 'display: none;' : ''); ?>">
					<?php if (!empty($branch_id)) { ?>
					<div class="table-responsive">
						<table class="table table-bordered table-hover mt-md" id="tableID">
							<thead>
								<th><?php echo translate('stoppage'); ?> <span class="required">*</span></th>
								<th><?php echo translate('stop_time'); ?> <span class="required">*</span></th>
								<th><?php echo translate('route_fare'); ?> <span class="required">*</span></th>
							</thead>
							<tbody>
								<tr id="row_0">
									<td class="min-w-lg">
										<div class="form-group">
											<?php
								            $this->db->where('branch_id', $branch_id);
								            $result = $this->db->get('transport_stoppage')->result();
								            $stoppagelist = array('' => translate('select'));
								            foreach ($result as $key => $value) {
								                $stoppagelist[$value->id] = $value->stop_position;
								            }
											echo form_dropdown("stoppage[0][stoppage_id]", $stoppagelist, "", "class='form-control' onchange='getStoppageDetails(this.value, 0)' data-width='100%' id='stoppage_id0'
											data-plugin-selectTwo");
											?>
											<span class="error"></span>
										</div>
									</td>
									<td class="min-w-lg">
										<div class="form-group">
											<input type="text" class="form-control timepicker" value="" name="stoppage[0][stop_time]" id="stop_time0" />
											<span class="error"></span>
										</div>
									</td>
									<td class="min-w-sm">
										<div class="form-group">
											<div class="input-group">
												<input type="text" class="form-control" name="stoppage[0][route_fare]" value="0.00" id="route_fare0" autocomplete="off" />
												<span class="input-group-addon"><?php echo $currency_symbol ?></span>
											</div>
											<span class="error"></span>
										</div>
									</td>
								</tr>
							</tbody>
							<tfoot>
								<tr>
									<td colspan="6">
										<button type="button" class="btn btn-default" onclick="addRows()"> <i class="fas fa-plus-circle"></i> <?php echo translate('add_more'); ?></button>
									</td>
								</tr>
							</tfoot>
						</table>
					</div>
				<?php } ?>
				</div>
				<footer class="panel-footer">
					<div class="row">
						<div class="col-md-offset-9 col-md-3">
							<button type="submit" name="purchase" id="savebtn" value="1" class="btn btn-default btn-block" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
								<i class="fas fa-plus-circle"></i> <?php echo translate('save'); ?>
							</button>
						</div>
					</div>
				</footer>
			
				<?php echo form_close();?>
			</div>
<?php endif; ?>
		</div>
	</div>
</section>

<?php if (!empty($branch_id)) { ?>
<script type="text/javascript">
	function getDynamicInput(value) {
		var html_row = "";
		html_row += '<tr id="row_' + value + '">';
		html_row += '<td><div class="form-group">';
		html_row += '<select id="stoppage_id' + value + '" name="stoppage[' + value + '][stoppage_id]" class="form-control select2_in"  onchange="getStoppageDetails(this.value, ' + value + ')" >';
		html_row += '<option value=""><?php echo translate('select'); ?></option>';
<?php
$stoppagelist = $this->db->where('branch_id', $branch_id)->get('transport_stoppage')->result();
foreach($stoppagelist as $val): ?>
		html_row += '<option value="<?php echo html_escape($val->id) ?>"><?php echo html_escape($val->stop_position); ?></option>';
<?php endforeach; ?>
		html_row += '</select>';
		html_row += '<span class="error"></span></div></td>';
		html_row += '<td><div class="form-group">';
		html_row += '<input id="stop_time' + value +'" name="stoppage[' + value +'][stop_time]" type="text" class="form-control timepicker" value=""   />';
		html_row += '<span class="error"></span></div></td>';
		html_row += '</div></td>';
		html_row += '<td class="min-w-md"><div class="form-group" style="float: left; width: 70% !important;">';
		html_row += '<div class="input-group">';
		html_row += '<input id="route_fare' + value + '" type="number" name="stoppage[' + value + '][route_fare]" class="form-control" autocomplete="off"  value="0.00" />';
		html_row += '<span class="input-group-addon"><?php echo html_escape($currency_symbol) ?></span></div>';
		html_row += '<span class="error"></span></div>';
		html_row += '<button type="button" class="btn btn-danger" onclick="deleteRow(' + value + ')" style="float: right; max-width: 30%"><i class="fas fa-times"></i> </button>';
		html_row += '</td>';
		html_row += '</tr>';
		return html_row;
	}
</script>
<?php } ?>

<script type="text/javascript">
	var count = 1;
	$(document).ready(function () {
		$(document).on('change', '#branchID', function() {
			var branchID = $(this).val();
			$.ajax({
				url: "<?=base_url('transport/getStoppageAjax')?>",
				type: 'POST',
				data: { branch_id: branchID },
				success: function (data) {
					$('#purchaseItems').html(data).slideDown();
					$(".selectTwo").each(function() {
						var $this = $(this);
						$this.themePluginSelect2({});
					});
				}
			});
		});

		$(document).on('focus', '.timepicker', function () {
			var $this = $(this);
			$this.themePluginTimePicker({});
		});
	});

	function getStoppageDetails(stoppage_id, rowid) {
	    $.ajax({
	        type: "POST",
	        url: "<?php echo base_url('transport/getStoppageDetails'); ?>",
	        data: {
	        	"stoppage_id": stoppage_id
	        },
	        dataType: "json",
	        success: function(data) {
	           $("#stop_time" + rowid).val(data.stop_time);
	           $("#route_fare" + rowid).val(data.route_fare);
	        }
	    });	
	}

	function addRows(){
		var tbody = $('#tableID').children('tbody');
		tbody.append(getDynamicInput(count));
		$(`#product${count}, .select2_in`).select2({
		    theme: "bootstrap",
		    width: "100%"
		});
		count++;
	}

    function deleteRow(id) {
        $("#row_" + id).remove();
    }
</script>
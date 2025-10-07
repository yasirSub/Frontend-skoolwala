<?php
$branch_id = $route['branch_id'];
$currency_symbol = $global_config['currency_symbol'];
 ?>
<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li>
				<a href="<?=base_url('transport/route')?>"><i class="fas fa-list-ul"></i> <?=translate('route_list')?></a>
			</li>
			<li class="active">
				<a href="#edit" data-toggle="tab" ><i class="far fa-edit"></i> <?=translate('edit_route')?></a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="tab-pane active" id="edit">
				<?php echo form_open($this->uri->uri_string(), array('class' => 'frm-submit')); ?>
					<div class="mt-lg form-horizontal form-bordered">
						<input type="hidden" name="branch_id" value="<?=$branch_id?>">
						<input type="hidden" name="route_id" value="<?=$route['id']?>">
						<div class="form-group">
							<label class="col-md-3 control-label"><?=translate('route_name')?> <span class="required">*</span></label>
							<div class="col-md-6">
								<input type="text" class="form-control" name="route_name" value="<?=$route['name']?>" />
								<span class="error"></span>
							</div>
						</div>
						<div class="form-group">
							<label class="col-md-3 control-label"><?=translate('start_place')?> <span class="required">*</span></label>
							<div class="col-md-6">
								<input type="text" class="form-control" name="start_place" value="<?=$route['start_place']?>" />
								<span class="error"></span>
							</div>
						</div>
						<div class="form-group">
							<label class="col-md-3 control-label"><?=translate('stop_place')?> <span class="required">*</span></label>
							<div class="col-md-6">
								<input type="text" class="form-control" name="stop_place" value="<?=$route['stop_place']?>" />
								<span class="error"></span>
							</div>
						</div>
						<div class="form-group">
							<label class="col-md-3 control-label"><?=translate('remarks')?></label>
							<div class="col-md-6 mb-md">
								<textarea class="form-control" rows="2" name="remarks"><?=$route['remarks']?></textarea>
							</div>
						</div>
					</div>
					<div id="routeStoppage" class="mt-lg">
						<div class="table-responsive">
							<table class="table table-bordered table-hover mt-md" id="tableID">
								<thead>
									<th><?php echo translate('stoppage'); ?> <span class="required">*</span></th>
									<th><?php echo translate('stop_time'); ?> <span class="required">*</span></th>
									<th><?php echo translate('route_fare'); ?> <span class="required">*</span></th>
								</thead>
								<tbody id="stoppage_entry_append">
<?php foreach ($stoppages as $r_key => $r_val) { ?>
									<?php echo form_hidden(array('i[]' => $r_val->id)); ?>
									<tr id="row_<?php echo $r_key ?>">
										<?php echo form_hidden(array("old_id[$r_key]" => $r_val->id)); ?>
										<td class="min-w-lg">
											<div class="form-group">
												<?php
									            $this->db->where('branch_id', $branch_id);
									            $result = $this->db->get('transport_stoppage')->result();
									            $stoppagelist = array('' => translate('select'));
									            foreach ($result as $key => $value) {
									                $stoppagelist[$value->id] = $value->stop_position;
									            }
												echo form_dropdown("stoppage[$r_key][stoppage_id]", $stoppagelist, $r_val->stoppage_id, "class='form-control' onchange='getStoppageDetails(this.value, $r_key)' data-width='100%' id='stoppage_id0'
												data-plugin-selectTwo");
												?>
												<span class="error"></span>
											</div>
										</td>
										<td class="min-w-lg">
											<div class="form-group">
												<input type="text" class="form-control timepicker" value="<?php echo date("g:i A", strtotime($r_val->stop_time)) ?>" name="stoppage[<?php echo $r_key ?>][stop_time]" id="stop_time<?php echo $r_key ?>" />
												<span class="error"></span>
											</div>
										</td>
										<td class="timet-td">
											<div class="form-group" <?php echo $r_key == 0 ? '' : 'style="float: left; width: 70% !important;"' ?>>
												<div class="input-group">
													<input type="text" class="form-control" name="stoppage[<?php echo $r_key ?>][route_fare]" value="<?php echo $r_val->route_fare ?>" id="route_fare<?php echo $r_key ?>" autocomplete="off" />
													<span class="input-group-addon"><?php echo $currency_symbol ?></span>
												</div>
												<span class="error"></span>
											</div>
<?php if ($r_key != 0) {  ?>
											<button type="button" class="btn btn-danger" onclick="deleteRow(this)" style="float: right; max-width: 30%"><i class="fas fa-times"></i> </button>
<?php } ?>
										</td>
									</tr>
<?php } ?>
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
					</div>
					<footer class="panel-footer">
						<div class="row">
							<div class="col-md-offset-9 col-md-3">
								<button type="submit" class="btn btn-default btn-block" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
									<i class="fas fa-plus-circle"></i> <?=translate('update')?>
								</button>
							</div>
						</div>
					</footer>
				<?php echo form_close();?>
			</div>
		</div>
	</div>
</section>

<script type="text/javascript">
	var count = <?php echo (empty($results)) ? 1 : count($results); ?>;
	function addRows(){
		var tbody = $('#tableID').children('tbody');
		tbody.append(getDynamicInput(count));
		$(`.select2_in`).themePluginSelect2({'width': "100%"});
		count++;
	}

    function deleteRow(elem) {
        $(elem).parent().parent().remove();
    }

	$(document).on('focus', '.timepicker', function () {
		var $this = $(this);
		$this.themePluginTimePicker({});
	});

	function getDynamicInput(value) {
		var html_row = "";
		html_row += '<tr id="row_' + value + '">';
		html_row += '<input type="hidden" name="old_id[' + value + ']" class="form-control" value="0" >';
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
		html_row += '<button type="button" class="btn btn-danger" onclick="deleteRow(this)" style="float: right; max-width: 30%"><i class="fas fa-times"></i> </button>';
		html_row += '</td>';
		html_row += '</tr>';
		return html_row;
	}

	function getStoppageDetails(stoppage_id, rowid) {
	    $.ajax({
	        type: "POST",
	        url: "<?php echo base_url('transport/getStoppageDetails'); ?>",
	        data: {
	        	"stoppage_id": stoppage_id
	        },
	        dataType: "json",
	        success: function(data) {
	        	console.log(data.stop_time);
	           $("#stop_time" + rowid).val(data.stop_time);
	           $("#route_fare" + rowid).val(data.route_fare);
	        }
	    });	
	}
</script>
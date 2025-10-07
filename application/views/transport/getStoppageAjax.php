<?php $currency_symbol = $global_config['currency_symbol']; ?>
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
						echo form_dropdown("stoppage[0][stoppage_id]", $stoppagelist, "", "class='form-control selectTwo' onchange='getStoppageDetails(this.value, 0)' data-width='100%' id='stoppage_id0'");
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
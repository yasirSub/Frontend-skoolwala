<section class="panel">
	<header class="panel-heading">
		<h4 class="panel-title"><i class="fas fa-list-ul"></i> <?=translate('event_list')?></h4>
	</header>
	<div class="panel-body">
		<div class="export_title"><?php echo translate('event_list');?></div>
		<table class="table table-bordered table-hover mb-none tbr-top" id="eventTable" width="100%">
			<thead>
				<tr>
					<th><?=translate('title')?></th>
					<th><?=translate('type')?></th>
					<th><?=translate('date_of_start')?></th>
					<th><?=translate('date_of_end')?></th>
					<th><?=translate('audience')?></th>
					<th><?=translate('created_by')?></th>
					<th><?=translate('action')?></th>
				</tr>
			</thead>
		</table>
	</div>
</section>

<div class="zoom-anim-dialog modal-block modal-block-primary mfp-hide" id="modal">
	<section class="panel">
		<header class="panel-heading">
			<div class="panel-btn">
				<button onclick="fn_printElem('printResult')" class="btn btn-default btn-circle icon" ><i class="fas fa-print"></i></button>
			</div>
			<h4 class="panel-title"><i class="fas fa-info-circle"></i> <?=translate('event_details')?></h4>
		</header>
		<div class="panel-body">
			<div id="printResult" class="pt-sm pb-sm">
				<div class="table-responsive">						
					<table class="table table-bordered table-condensed text-dark tbr-top" id="ev_table"></table>
				</div>
			</div>
		</div>
		<footer class="panel-footer">
			<div class="row">
				<div class="col-md-12 text-right">
					<button class="btn btn-default modal-dismiss">
						<?=translate('close')?>
					</button>
				</div>
			</div>
		</footer>
	</section>
</div>

<script type="text/javascript">
	$(document).ready(function () {
		var cusDataTable = initDatatable("#eventTable", "userrole/getEventListDT");
	});
</script>
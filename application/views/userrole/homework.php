<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li class="active">
				<a href="#list" data-type="live"  data-toggle="tab"><i class="fas fa-list-ul"></i> <?php echo translate('live') . " & " . translate('upcoming'); ?></a>
			</li>
			<li>
				<a href="#create" data-type="archive"  data-toggle="tab"><i class="fas fa-box-archive"></i> <?php echo translate('archive'); ?></a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="both-tab">
				<div class="export_title"><?php echo translate('homework_list');?></div>
				<table class="table table-bordered table-condensed table-hover mb-none" id="homeworkList" width="100%">
					<thead>
						<tr>
							<th><?=translate('class')?></th>
							<th><?=translate('subject')?></th>
							<th><?=translate('date_of_homework')?></th>
							<th><?=translate('date_of_submission')?></th>
							<th><?=translate('evaluation_date')?></th>
							<th><?=translate('rank_out_of_5'); ?></th>
							<th class="no-sort"><?=translate('status')?></th>
                            <th><?=translate('remarks')?></th>
							<th><?=translate('action')?></th>
						</tr>
					</thead>
				</table>
			</div>
		</div>
	</div>
</section>

<div class="zoom-anim-dialog modal-block modal-block-full mfp-hide" id="homeworkModal">
	<section class="panel">
		<header class="panel-heading">
			<h4 class="panel-title"><i class="fas fa-bars"></i> <?php echo translate('homework') . " " . translate('details') ?></h4>
		</header>
		<div class="panel-body mt-md mb-md" id="homewor_details">
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
	var cusDataTable = '';
	var tableType = 'live';
	$(document).ready(function () {
		let filter_report = function (d) {
			d.type = tableType;
		};
		cusDataTable = initDatatable("#homeworkList", "userrole/gethomeworkDT", filter_report);
	});

	$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
		tableType = $(e.target).attr('data-type');
		cusDataTable.ajax.reload();
	});

	function homeworkModal(id,dd, elm) {
		$("#homeworkModal #homewor_details").html("");
		var btn = $(elm);
		$.ajax({
			url: base_url + 'userrole/homeworkModal',
			type: 'POST',
			dataType: "html",
			data: { 'id': id },
	        beforeSend: function () {
	            btn.button('loading');

	        },
			success: function (data) {
				$("#homeworkModal #homewor_details").html(data);
			},
	        complete: function (data) {
	            mfp_modal('#homeworkModal');
	            btn.button('reset');
	        },
	        error: function () {
	            btn.button('reset');
	        }
		});
	}
</script>
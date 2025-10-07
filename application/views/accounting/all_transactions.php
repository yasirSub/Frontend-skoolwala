<?php $currency_symbol = $global_config['currency_symbol']; ?>
<div class="row">
	<div class="col-md-12">
		<section class="panel">
			<header class="panel-heading">
				<h4 class="panel-title"><i class="fas fa-list-ol"></i> <?php echo translate('transactions'); ?></h4>
			</header>
			<div class="panel-body">
				<div class="export_title">All Transactions</div>
				<table class="table table-bordered table-hover table-condensed" id="allTransactions" cellpadding="0" cellspacing="0" width="100%">
					<thead>
						<tr>
						<?php if (is_superadmin_loggedin()): ?>
							<th><?=translate('branch')?></th>
						<?php endif; ?>
							<th><?php echo translate('account') . " " . translate('name'); ?></th>
							<th><?php echo translate('type'); ?></th>
							<th><?php echo translate('voucher') . " " . translate('head'); ?></th>
							<th><?php echo translate('ref_no'); ?></th>
							<th><?php echo translate('description'); ?></th>
							<th><?php echo translate('pay_via'); ?></th>
							<th><?php echo translate('amount'); ?></th>
							<th><?php echo translate('dr'); ?></th>
							<th><?php echo translate('cr'); ?></th>
							<th><?php echo translate('balance'); ?></th>
							<th><?php echo translate('date'); ?></th>
						</tr>
					</thead>
				</table>


			</div>
		</section>
	</div>
</div>

<script type="text/javascript">
	var cusDataTable = '';
	$(document).ready(function () {
		cusDataTable = initDatatable('#allTransactions', 'accounting/getAlltransactionsListDT');
	});
</script>
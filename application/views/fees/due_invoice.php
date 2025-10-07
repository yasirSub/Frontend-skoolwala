<?php
$widget = (is_superadmin_loggedin() ? 3 : 4);
?>
<div class="row">
	<div class="col-md-12">
		<section class="panel">
			<header class="panel-heading">
				<h4 class="panel-title"><?=translate('select_ground')?></h4>
			</header>
			<?php echo form_open($this->uri->uri_string(), array('class' => 'search_form'));?>
			<div class="panel-body">
				<div class="row mb-sm">
				<?php if (is_superadmin_loggedin() ): ?>
					<div class="col-md-3">
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
								echo form_dropdown("class_id", $arrayClass, set_value('class_id'), "class='form-control' id='class_id' onchange='getSectionByClass(this.value,1)'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('section')?> <span class="required">*</span></label>
							<?php
								$arraySection = $this->app_lib->getSections(set_value('class_id'), true);
								echo form_dropdown("section_id", $arraySection, set_value('section_id'), "class='form-control' id='section_id'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('fees_type')?> <span class="required">*</span></label>
							<select data-plugin-selectTwo class="form-control" name="fees_type" id="feesType">
								
							</select>
							<span class="error"></span>
						</div>
					</div>
				</div>
			</div>
			<footer class="panel-footer">
				<div class="row">
					<div class="col-md-offset-10 col-md-2">
						<button type="submit" name="search" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing" value="1" class="btn btn-default btn-block"> <i class="fas fa-filter"></i> <?=translate('filter')?></button>
					</div>
				</div>
			</footer>
			<?php echo form_close();?>
		</section>

		<section class="panel appear-animation" data-appear-animation-type="<?php echo $global_config['animations'];?>" data-appear-animation-delay="100">
			<?php echo form_open('fees/invoicePrint', array('class' => 'printIn')); ?>
			<header class="panel-heading">
				<h4 class="panel-title"><i class="fas fa-list-ol"></i> <?=translate('due_invoice') . " " . translate('list');?>
					<div class="panel-btn">
						<button type="submit" class="btn btn-default btn-circle" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
							<i class="fas fa-print"></i> <?=translate('generate')?>
						</button>
					</div>
				</h4>
			</header>
			<div class="panel-body">
				<div class="mb-md mt-md">
					<div class="export_title"><?=translate('due_invoice') . " " . translate('list')?></div>
					<table class="table table-bordered table-condensed table-hover mb-none tbr-top" id="dueInvoiceTable" width="100%">
						<thead>
							<tr>
								<th width="5" class="no-sort no-export">
									<div class="checkbox-replace">
										<label class="i-checks" data-toggle="tooltip" data-original-title="Print Show / Hidden">
											<input type="checkbox" name="select-all" id="selectAllchkbox"> <i></i>
										</label>
									</div>
								</th>
								<th><?=translate('student')?></th>
								<th><?=translate('register_no')?></th>
								<th><?=translate('roll')?></th>
								<th><?=translate('mobile_no')?></th>
								<th><?=translate('fee_group')?></th>
								<th><?=translate('due_date')?></th>
								<th><?=translate('amount')?></th>
								<th><?=translate('paid')?></th>
								<th><?=translate('discount')?></th>
								<th><?=translate('balance')?></th>
								<th><?=translate('action')?></th>
							</tr>
						</thead>
					</table>
				</div>
			</div>
			<?php echo form_close(); ?>
		</section>

	</div>
</div>

<script type="text/javascript">
	var searchBtn = "";
	var cusDataTable = "";
	$(document).ready(function () {
		var filter = function (d) {
			d.branch_id = $('#branch_id').val();
			d.class_id = $('#class_id').val();
			d.section_id = $('#section_id').val();
			d.fees_type = $('#feesType').val();
			d.submit_btn = searchBtn;
		};
		cusDataTable = initDatatable("#dueInvoiceTable", "fees/getDueInvoiceListDT", filter);
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
						$(".export_title").html(data.export_title);
						searchBtn = 1;
						cusDataTable.draw();
						animation_panel_show();
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


		var branchID = "<?=$branch_id?>";
		var typeID = "<?=set_value('fees_type')?>";
		getTypeByBranch(branchID, typeID);

        $('form.printIn').on('submit', function(e) {
            e.preventDefault();
            var btn = $(this).find('[type="submit"]');
            $.ajax({
                url: $(this).attr('action'),
                type: "POST",
                data: $(this).serialize(),
                dataType: 'html',
                beforeSend: function () {
                    btn.button('loading');
                },
                success: function (data) {
                	fn_printElem(data, true);
                },
                error: function () {
	                btn.button('reset');
	                alert("An error occured, please try again");
                },
	            complete: function () {
	                btn.button('reset');
	            }
            });
        });

		$('#branch_id').on('change', function() {
			var branchID = $(this).val();
			getClassByBranch(branchID);
			getTypeByBranch(branchID);

		});

		function getTypeByBranch(branchID, typeID) {
		    $.ajax({
		        url: base_url + 'fees/getTypeByBranch',
		        type: 'POST',
		        data: {
		            'branch_id' : branchID,
		            'type_id' : typeID
		        },
		        success: function (data) {
		            $('#feesType').html(data);
		        }
		    });
		}
	});
</script>

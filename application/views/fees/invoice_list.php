<?php $widget = (is_superadmin_loggedin() ? 4 : 6); ?>
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
					<div class="col-md-4">
						<div class="form-group">
							<label class="control-label"><?=translate('branch')?> <span class="required">*</span></label>
							<?php
								$arrayBranch = $this->app_lib->getSelectList('branch');
								echo form_dropdown("branch_id", $arrayBranch, set_value('branch_id'), "class='form-control' id='branch_id' onchange='getClassByBranch(this.value)'
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
				<?php endif; ?>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('class')?></label>
							<?php
								$arrayClass = $this->app_lib->getClass($branch_id);
								echo form_dropdown("class_id", $arrayClass, set_value('class_id'), "class='form-control' id='class_id' onchange='getSectionByClass(this.value)'
								data-plugin-selectTwo data-width='100%' ");
							?>
							<span class="error"></span>
						</div>
					</div>
					<div class="col-md-<?php echo $widget; ?> mb-sm">
						<div class="form-group">
							<label class="control-label"><?=translate('section')?></label>
							<?php
								$arraySection = $this->app_lib->getSections(set_value('class_id'));
								echo form_dropdown("section_id", $arraySection, set_value('section_id'), "class='form-control' id='section_id'
								data-plugin-selectTwo data-width='100%'");
							?>
							<span class="error"></span>
						</div>
					</div>
				</div>
			</div>
			<footer class="panel-footer">
				<div class="row">
					<div class="col-md-offset-10 col-md-2">
						<button type="submit" name="search" id="searchBtn" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing" value="1" class="btn btn-default btn-block"> <i class="fas fa-filter"></i> <?=translate('filter')?></button>
					</div>
				</div>
			</footer>
			<?php echo form_close();?>
		</section>

		<section class="panel appear-animation" data-appear-animation-type="<?php echo $global_config['animations'];?>" data-appear-animation-delay="100">
			<?php echo form_open('fees/invoicePDFdownload', array('class' => 'printIn')); ?>
			<header class="panel-heading">
				<h4 class="panel-title"><i class="fas fa-list-ol"></i> <?=translate('invoice_list')?>
					<div class="panel-btn">
						<button type="submit" class="btn btn-default btn-circle" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing" >
							<i class="fa-solid fa-file-pdf"></i> <?=translate('download')?> PDF
						</button>
						<button type="button" class="btn btn-default btn-circle" id="printBtn" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
							<i class="fas fa-print"></i> <?=translate('print')?>
						</button>
					</div>
				</h4>
			</header>
			<div class="panel-body">
				<div class="mb-md mt-md">
					<div class="export_title"><?=translate('invoice') . " " . translate('list')?></div>
					<table class="table table-bordered table-condensed table-hover mb-none tbr-top" id="invoiceTable" width="100%">
						<thead>
							<tr>
								<th width="5" class="no-sort no-export">
									<div class="checkbox-replace">
										<label class="i-checks" data-toggle="tooltip" data-original-title="Select All">
											<input type="checkbox" name="select-all" id="selectAllchkbox"> <i></i>
										</label>
									</div>
								</th>
								<th><?=translate('student')?></th>
								<th><?=translate('class')?></th>
								<th><?=translate('section')?></th>
								<th><?=translate('register_no')?></th>
								<th><?=translate('roll')?></th>
								<th><?=translate('mobile_no')?></th>
								<th><?=translate('fee_group')?></th>
								<th class="no-sort"><?=translate('status')?></th>
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
	var branch_ID = "<?php echo set_value('branch_id'); ?>";
	$(document).ready(function () {
		let filter = function (d) {
			d.branch_id = $('#branch_id').val();
			d.class_id = $('#class_id').val();
			d.section_id = $('#section_id').val();
			d.submit_btn = searchBtn;
		};
		cusDataTable = initDatatable("#invoiceTable", "fees/getInvoiceListDT", filter);
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
						/*
						if (searchBtn == "") {
							cusDataTable.columns.adjust();
						}*/
						$(".export_title").html(data.export_title);
						searchBtn = 1;
						branch_ID = $('#branch_id').val();
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

		$('form.printIn').on('submit', function(e) {
		    e.preventDefault();
		    var btn = $(this).find('[type="submit"]');
		    var countRow = $(this).find('input[name="student_id[]"]:checked').length;
		    if (countRow > 0) {
		        var class_name = $('#class_id').find('option:selected').text();
		        var section_name = $('#section_id').find('option:selected').text();
		        section_name = (section_name == 'Select Class First' ? "<?php echo translate('all_section') ?>" : section_name);
		        class_name = (class_name == 'Select' ? "<?php echo translate('all_class') ?>" : class_name);
		        var fileName =  class_name + ' (' + section_name + ")-Invoice.pdf";
		        $.ajax({
		            url: $(this).attr('action'),
		            type: "POST",
		            data: $(this).serialize(),
		            cache: false,
					xhr: function () {
						var xhr = new XMLHttpRequest();
						xhr.responseType = 'blob'
						return xhr;
					},
		            beforeSend: function () {
		                btn.button('loading');
		            },
		            success: function (data, jqXHR, response) {
						const blob = new Blob([data], { type: 'application/pdf' });
						const url = window.URL.createObjectURL(blob);
						const a = document.createElement('a');
						a.href = url;
						a.download = fileName;
						document.body.appendChild(a);
						a.click();
						a.remove();
						window.URL.revokeObjectURL(url);
						btn.button('reset');
		            },
		            error: function () {
		                btn.button('reset');
		                alert("An error occured, please try again");
		            },
		            complete: function () {
		                btn.button('reset');
		            }
		        });
			} else {
				popupMsg("<?php echo translate('no_row_are_selected') ?>", "error");
			}
		});

	   $(document).on('click','#printBtn',function(){
			btn = $(this);
			var arrayData = [];
			$('form.printIn input[name="student_id[]"]').each(function() {
				if($(this).is(':checked')) {
					studentID = $(this).val();
		            arrayData.push(studentID);
	        	}
			});
	        if (arrayData.length === 0) {
	            popupMsg("<?php echo translate('no_row_are_selected') ?>", "error");
	            btn.button('reset');
	        } else {
	            $.ajax({
	                url: "<?php echo base_url('fees/invoicePrint') ?>",
	                type: "POST",
	                data: {
	                	'student_id[]' : arrayData,
	                },
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
	        }
	    });
	});

   function pdf_sendByemail(enrollID = '', ele) 
   {
   		var btn = $(ele);
		if (enrollID !== '') {
	        $.ajax({
	            url: "<?php echo base_url('fees/pdf_sendByemail') ?>",
	            type: "POST",
	            data: {
	            	'enrollID' : enrollID,
	            	'branch_id' : branch_ID,
	            },
	            dataType: 'JSON',
	            beforeSend: function () {
	                btn.button('loading');
	            },
	            success: function (data) {
	            	popupMsg(data.message, data.status);
	            },
	            error: function () {
	                btn.button('reset');
	                alert("An error occured, please try again");
	            },
	            complete: function () {
	                btn.button('reset');
	            }
	        });
		}
   }
</script>
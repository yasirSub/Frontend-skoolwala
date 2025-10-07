<section class="panel">
	<header class="panel-heading">
		<h4 class="panel-title"><i class="fas fa-user-clock"></i> <?=translate('schedule') . " " . translate('list')?></h4>
	</header>
	<div class="panel-body">
		<table class="table table-bordered table-hover table-condensed table-export mt-md">
			<thead>
				<tr>
					<th>#</th>
					<th><?=translate('exam_name')?></th>
					<th class="action"><?=translate('action')?></th>
				</tr>
			</thead>
			<tbody>
			<?php 
			$count = 1;
			foreach($exams as $row):
				?>
				<tr>
					<td><?php echo $count++ ?></td>
					<td><?php echo $this->application_model->exam_name_by_id($row['exam_id']);?></td>
					<td>
						<!-- view link -->
						<button class="btn btn-circle btn-default icon" data-toggle="tooltip" data-original-title="<?php echo translate('details') ?>" onclick="getExamTimetableM('<?=$row['exam_id']?>','<?=$row['class_id']?>','<?=$row['section_id']?>');"> 
							<i class="far fa-eye"></i> 
						</button>
					<?php if (!empty($templateID)) { ?>
						<button class="btn btn-circle btn-default" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing" onclick="admitCardPrint('<?=$row['exam_id']?>', this)"><i class="fa fa-download"></i> <?php echo translate('admit_card') ?></button>
					<?php } ?>
					</td>
				</tr>
			<?php endforeach;  ?>
			</tbody>
		</table>
	</div>
</section>
<div class="zoom-anim-dialog modal-block modal-block-lg mfp-hide" id="modal">
	<section class="panel" id='quick_view'></section>
</div>

<script type="text/javascript">
	function admitCardPrint(exam_id, elem) {
	    var btn = $(elem);
	    $.ajax({
	        url: base_url + "userrole/admitCardprintFn",
	        type: 'POST',
	        data: {'exam_id': exam_id},
	        dataType: "html",
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
</script>
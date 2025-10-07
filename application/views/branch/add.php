<section class="panel">
	<div class="tabs-custom">
		<ul class="nav nav-tabs">
			<li class="<?=(empty($validation_error) ? 'active' : '') ?>">
				<a href="#list" data-toggle="tab"><i class="fas fa-list-ul"></i> <?=translate('branch_list')?></a>
			</li>
			<li class="<?=(!empty($validation_error) ? 'active' : '') ?>">
				<a href="#create" data-toggle="tab"><i class="far fa-edit"></i> <?=translate('create_branch')?></a>
			</li>
		</ul>
		<div class="tab-content">
			<div id="list" class="tab-pane <?=(empty($validation_error) ? 'active' : '')?>">
				<div class="mb-md">
					<div class="row">
						<div class="col-md-6">
							<h4><?=translate('branch_list')?></h4>
						</div>
						<div class="col-md-6 text-right">
							<a href="<?=base_url('branch/map')?>" class="btn btn-default">
								<i class="fas fa-map-marked-alt"></i> <?=translate('view_map')?>
							</a>
						</div>
					</div>
					<table class="table table-bordered table-hover table-condensed mb-none table-export">
						<thead>
							<tr>
								<th width="50"><?=translate('sl')?></th>
								<th><?=translate('branch_name')?></th>
								<th><?=translate('school_name')?></th>
								<th><?=translate('email')?></th>
								<th><?=translate('mobile_no')?></th>
								<th><?=translate('currency')?></th>
								<th><?=translate('symbol')?></th>
								<th><?=translate('city')?></th>
								<th><?=translate('state')?></th>
								<th><?=translate('address')?></th>
								<th><?=translate('latitude')?></th>
								<th><?=translate('longitude')?></th>
								<th class="no-sort"><?=translate('action')?></th>
							</tr>
						</thead>
						<tbody>
							<?php 
								$count = 1;
								$branchs = $this->db->get('branch')->result();
								foreach($branchs as $row):
							?>
							<tr>
								<td><?php echo $count++; ?></td>
								<td><?php echo $row->name;?></td>
								<td><?php echo $row->school_name;?></td>
								<td><?php echo $row->email;?></td>
								<td><?php echo $row->mobileno;?></td>
								<td><?php echo $row->currency;?></td>
								<td><?php echo $row->symbol;?></td>
								<td><?php echo $row->city;?></td>
								<td><?php echo $row->state;?></td>
								<td><?php echo $row->address;?></td>
								<td><?php echo $row->latitude;?></td>
								<td><?php echo $row->longitude;?></td>
								<td class="min-w-c">
								<?php 
								if ($this->app_lib->isExistingAddon('saas')) {
								if (!isEnabledSubscription($row->id)) {
									?>
									<a href="<?=base_url('saas/enabled_school/'.$row->id)?>" class="btn btn-default btn-circle icon" data-toggle="tooltip" data-original-title="<?php echo translate('enable_subscription'); ?>"><i class="fas fa-sitemap"></i></a>
								<?php } } ?>
									<!--update link-->
									<a href="<?=base_url('branch/edit/'.$row->id)?>" class="btn btn-default btn-circle icon">
										<i class="fas fa-pen-nib"></i>
									</a>
									<!-- delete link -->
									<?php echo btn_delete('branch/delete_data/' . $row->id);?>
								</td>
							</tr>
							<?php endforeach; ?>
						</tbody>
					</table>
				</div>
			</div>
			<div class="tab-pane <?=(!empty($validation_error) ? 'active' : '')?>" id="create">
				<?php echo form_open_multipart($this->uri->uri_string(), array('class' => 'form-horizontal form-bordered validate', 'id' => 'branchForm')); ?>
					<div class="form-group mt-md">
						<label class="col-md-3 control-label"><?=translate('branch_name')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="branch_name" value="<?=set_value('branch_name')?>" />
							<span class="error"><?=form_error('branch_name') ?></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('school_name')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="school_name" value="<?=set_value('school_name')?>" />
							<span class="error"><?=form_error('school_name') ?></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('email')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="email" value="<?=set_value('email')?>" />
							<span class="error"><?=form_error('email') ?></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('mobile_no')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="mobileno" value="<?=set_value('mobileno')?>">
							<span class="error"><?=form_error('mobileno') ?></span>
						</div>
					</div>
					<div class="form-group">
						<label  class="col-md-3 control-label"><?=translate('currency')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="currency" value="<?=set_value('currency')?>" />
							<span class="error"><?=form_error('currency') ?></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('currency_symbol')?> <span class="required">*</span></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="currency_symbol" value="<?=set_value('currency_symbol')?>" />
							<span class="error"><?=form_error('currency_symbol'); ?></span>
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('city')?></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="city" id="city" value="<?=set_value('city')?>">
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('state')?></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="state" id="state" value="<?=set_value('state')?>">
						</div>
					</div>
					<div class="form-group">
						<label  class="col-md-3 control-label"><?=translate('address')?></label>
						<div class="col-md-6 mb-md">
							<textarea type="text" rows="3" class="form-control" name="address" id="address"><?=set_value('address')?></textarea>
						</div>
					</div>
					<!-- Map for address geocoding -->
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('location_on_map')?></label>
						<div class="col-md-6">
							<div id="map" style="height: 300px; width: 100%;"></div>
							<button type="button" class="btn btn-default mt-sm" id="geocodeAddress"><?=translate('get_coordinates_from_address')?></button>
						</div>
					</div>
					<!-- Latitude and Longitude fields -->
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('latitude')?></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="latitude" id="latitude" value="<?=set_value('latitude')?>">
						</div>
					</div>
					<div class="form-group">
						<label class="col-md-3 control-label"><?=translate('longitude')?></label>
						<div class="col-md-6">
							<input type="text" class="form-control" name="longitude" id="longitude" value="<?=set_value('longitude')?>">
						</div>
					</div>
					<div class="form-group">
						<div class="col-md-offset-3 col-md-3">
							<label class="control-label pt-none"><?=translate('system_logo');?></label>
							<input type="file" name="logo_file" class="dropify dre-render" data-allowed-file-extensions="png" data-default-file="<?=$this->application_model->getBranchImage('', 'logo')?>" />
						</div>
						<div class="col-md-3 mb-md">
							<label class="control-label pt-none"><?=translate('text_logo');?></label>
							<input type="file" name="text_logo" class="dropify dre-render" data-allowed-file-extensions="png" data-default-file="<?=$this->application_model->getBranchImage('', 'logo-small')?>" />
						</div>
					</div>
					<div class="form-group">
						<div class="col-md-offset-3 col-md-3">
							<label class="control-label pt-none"><?=translate('printing_logo');?></label>
							<input type="file" name="print_file" class="dropify dre-render" data-allowed-file-extensions="png" data-default-file="<?=$this->application_model->getBranchImage('', 'printing-logo')?>" />
						</div>
						<div class="col-md-3 mb-md">
							<label class="control-label pt-none"><?=translate('report_card');?></label>
							<input type="file" name="report_card" class="dropify dre-render" data-allowed-file-extensions="png" data-default-file="<?=$this->application_model->getBranchImage('', 'report-card-logo')?>" />
						</div>
					</div>
					<footer class="panel-footer mt-lg">
						<div class="row">
							<div class="col-md-2 col-md-offset-3">
								<button type="submit" class="btn btn-default btn-block" name="submit" value="save">
									<i class="fas fa-plus-circle"></i> <?=translate('save')?>
								</button>
							</div>
						</div>	
					</footer>
				<?php echo form_close();?>
			</div>
		</div>
	</div>
</section>

<script>
// Initialize map
var map;
var marker;

function initMap() {
    // Create map centered on India
    map = new google.maps.Map(document.getElementById('map'), {
        zoom: 5,
        center: {lat: 20.5937, lng: 78.9629}
    });

    // Create marker
    marker = new google.maps.Marker({
        map: map,
        draggable: true,
        position: {lat: 20.5937, lng: 78.9629}
    });

    // Update latitude and longitude when marker is dragged
    marker.addListener('dragend', function(event) {
        document.getElementById('latitude').value = event.latLng.lat();
        document.getElementById('longitude').value = event.latLng.lng();
    });

    // Add click event to map to place marker
    map.addListener('click', function(event) {
        marker.setPosition(event.latLng);
        document.getElementById('latitude').value = event.latLng.lat();
        document.getElementById('longitude').value = event.latLng.lng();
    });
}

// Geocode address to get coordinates
function geocodeAddress() {
    var address = document.getElementById('address').value;
    var city = document.getElementById('city').value;
    var state = document.getElementById('state').value;
    
    if (!address && !city && !state) {
        alert('Please enter an address, city, or state');
        return;
    }
    
    var fullAddress = [address, city, state].filter(Boolean).join(', ');
    
    var geocoder = new google.maps.Geocoder();
    geocoder.geocode({'address': fullAddress}, function(results, status) {
        if (status === 'OK') {
            // Center map on location
            map.setCenter(results[0].geometry.location);
            map.setZoom(15);
            
            // Move marker to location
            marker.setPosition(results[0].geometry.location);
            
            // Update latitude and longitude fields
            document.getElementById('latitude').value = results[0].geometry.location.lat();
            document.getElementById('longitude').value = results[0].geometry.location.lng();
        } else {
            alert('Geocode was not successful for the following reason: ' + status);
        }
    });
}

// Load Google Maps API
function loadGoogleMaps() {
    var script = document.createElement('script');
    script.src = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyCVcjJEjNRjT9WpgJHYLzHtUf8yCO6NYgk&callback=initMap';
    script.async = true;
    script.defer = true;
    document.head.appendChild(script);
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    loadGoogleMaps();
    
    // Add event listener to geocode button
    document.getElementById('geocodeAddress').addEventListener('click', geocodeAddress);
});
</script>
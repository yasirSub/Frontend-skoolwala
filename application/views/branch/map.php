<section class="panel">
	<header class="panel-heading">
		<h4 class="panel-title"><i class="fas fa-map-marked-alt"></i> <?=translate('school_map')?></h4>
	</header>
	<div class="panel-body">
		<div class="row mb-md">
			<div class="col-md-12">
				<div class="alert alert-info">
					<i class="fas fa-info-circle"></i> <?=translate('click_on_map_to_add_marker_or_drag_existing_markers')?>
				</div>
			</div>
		</div>
		<div id="school-map" style="height: 600px; width: 100%;"></div>
	</div>
</section>

<script>
// Initialize and display the map
function initMap() {
	// Create map centered on India (you can change this to your preferred default location)
	var map = new google.maps.Map(document.getElementById('school-map'), {
		zoom: 5,
		center: {lat: 20.5937, lng: 78.9629} // Center of India
	});

	// Keep track of markers
	var markers = [];
	var infoWindows = [];

	// Add markers for each school
	<?php foreach($schools as $school): ?>
		<?php if(!empty($school->latitude) && !empty($school->longitude)): ?>
			var marker = new google.maps.Marker({
				position: {lat: parseFloat(<?=$school->latitude?>), lng: parseFloat(<?=$school->longitude?>)},
				map: map,
				title: '<?=$school->school_name?>'
			});

			var infoWindow = new google.maps.InfoWindow({
				content: '<div><strong><?=$school->school_name?></strong><br/>' +
						'<?=$school->address?><br/>' +
						'<?=$school->city?>, <?=$school->state?><br/>' +
						'<?=$school->mobileno?></div>'
			});

			// Add click event to marker
			marker.addListener('click', function() {
				// Close all other info windows
				infoWindows.forEach(function(window) {
					window.close();
				});
				// Open this info window
				infoWindow.open(map, marker);
			});

			// Store references
			markers.push(marker);
			infoWindows.push(infoWindow);
		<?php endif; ?>
	<?php endforeach; ?>

	// Add click event to map to allow adding new markers
	map.addListener('click', function(event) {
		// Create new marker
		var newMarker = new google.maps.Marker({
			position: event.latLng,
			map: map,
			draggable: true
		});

		// Add info window with coordinates
		var newInfoWindow = new google.maps.InfoWindow({
			content: '<div><strong>New Location</strong><br/>' +
					'Lat: ' + event.latLng.lat().toFixed(6) + '<br/>' +
					'Lng: ' + event.latLng.lng().toFixed(6) + '<br/><br/>' +
					'<button onclick="copyCoordinates(' + event.latLng.lat() + ', ' + event.latLng.lng() + ')" class="btn btn-xs btn-default">Copy Coordinates</button></div>'
		});

		// Add click event to new marker
		newMarker.addListener('click', function() {
			// Close all other info windows
			infoWindows.forEach(function(window) {
				window.close();
			});
			// Open this info window
			newInfoWindow.open(map, newMarker);
		});

		// Add drag end event to update coordinates in info window
		newMarker.addListener('dragend', function(event) {
			newInfoWindow.setContent('<div><strong>New Location</strong><br/>' +
					'Lat: ' + event.latLng.lat().toFixed(6) + '<br/>' +
					'Lng: ' + event.latLng.lng().toFixed(6) + '<br/><br/>' +
					'<button onclick="copyCoordinates(' + event.latLng.lat() + ', ' + event.latLng.lng() + ')" class="btn btn-xs btn-default">Copy Coordinates</button></div>');
		});

		// Store references
		markers.push(newMarker);
		infoWindows.push(newInfoWindow);

		// Open info window for new marker
		newInfoWindow.open(map, newMarker);
	});
}

// Function to copy coordinates to clipboard
function copyCoordinates(lat, lng) {
	var coordinates = lat.toFixed(6) + ', ' + lng.toFixed(6);
	var tempInput = document.createElement('input');
	tempInput.style = 'position: absolute; left: -1000px; top: -1000px';
	tempInput.value = coordinates;
	document.body.appendChild(tempInput);
	tempInput.select();
	document.execCommand('copy');
	document.body.removeChild(tempInput);
	alert('Coordinates copied to clipboard: ' + coordinates);
}

// Load the Google Maps API
function loadGoogleMaps() {
	var script = document.createElement('script');
	script.src = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyB3y0GAbc3vZ7RzUQnVrBzY6Qf_PZ6b54U&callback=initMap';
	script.async = true;
	script.defer = true;
	document.head.appendChild(script);
}

// Call the function to load Google Maps
loadGoogleMaps();
</script>
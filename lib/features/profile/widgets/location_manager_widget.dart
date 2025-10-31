import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skoolwala/shared/services/location_service.dart';
import 'package:skoolwala/shared/services/api_service.dart';

class LocationManagerWidget extends StatefulWidget {
  final int? branchId;

  const LocationManagerWidget({super.key, this.branchId});

  @override
  State<LocationManagerWidget> createState() => _LocationManagerWidgetState();
}

class _LocationManagerWidgetState extends State<LocationManagerWidget> {
  List<LocationModel> _locations = [];
  bool _isLoading = false;
  String? _lastResult;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _getCurrentLocation();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await LocationService.getLocations(
        branchId: widget.branchId,
        isActive: true,
      );
      setState(() => _locations = locations);
    } catch (e) {
      _showError('Load Locations', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('❌ Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Manage locations for attendance tracking',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current Location Info
          if (_currentPosition != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addLocation,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Add Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkLocation,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Check Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadLocations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Locations List
          Text(
            'Registered Locations (${_locations.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_locations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No locations found')),
            )
          else
            ...(_locations.map((location) => _buildLocationCard(location))),

          // Result Display
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastResult!,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Radius: ${location.radius}m',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteLocation(location),
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            tooltip: 'Delete Location',
          ),
        ],
      ),
    );
  }

  Future<void> _addLocation() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final radiusController = TextEditingController(text: '100');
    final latController = TextEditingController();
    final lngController = TextEditingController();

    // Pre-fill coordinates if GPS is available
    if (_currentPosition != null) {
      latController.text = _currentPosition!.latitude.toStringAsFixed(6);
      lngController.text = _currentPosition!.longitude.toStringAsFixed(6);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Main Office, Branch A',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Full address of the location',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Location coordinates section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Location Coordinates',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_currentPosition != null)
                          TextButton.icon(
                            onPressed: () {
                              latController.text = _currentPosition!.latitude
                                  .toStringAsFixed(6);
                              lngController.text = _currentPosition!.longitude
                                  .toStringAsFixed(6);
                            },
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Use GPS'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              hintText: '23.810300',
                              prefixIcon: Icon(Icons.north, size: 16),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              hintText: '90.412500',
                              prefixIcon: Icon(Icons.east, size: 16),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentPosition != null
                          ? 'GPS Available: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                          : 'GPS Not Available - Enter coordinates manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sample coordinates for reference
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Coordinates (Dhaka):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Main Office: 23.810300, 90.412500',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      'North Office: 23.850000, 90.400000',
                      style: TextStyle(fontSize: 11),
                    ),
                    Text(
                      'South Office: 23.750000, 90.400000',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Location'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Validate input
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a location name'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lat = double.tryParse(latController.text.trim());
      final lng = double.tryParse(lngController.text.trim());

      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid latitude and longitude'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate coordinate ranges
      if (lat < -90 || lat > 90) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Latitude must be between -90 and 90'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (lng < -180 || lng > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Longitude must be between -180 and 180'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final result = await LocationService.addLocation(
          name: nameController.text.trim(),
          latitude: lat,
          longitude: lng,
          address: addressController.text.trim(),
          radius: int.tryParse(radiusController.text) ?? 100,
          branchId: widget.branchId,
        );

        if (result['status'] == 'success') {
          setState(() => _lastResult = result['message']);
          _loadLocations();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(result['message']);
        }
      } catch (e) {
        _showError('Add Location', e);
      }
    }
  }

  Future<void> _checkLocation() async {
    if (_currentPosition == null) {
      // Show dialog to enter coordinates manually
      final latController = TextEditingController();
      final lngController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GPS location not available. Please enter coordinates manually:',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '23.810300',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '90.412500',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Sample: Main Office Dhaka - 23.810300, 90.412500',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Check'),
            ),
          ],
        ),
      );

      if (result == true) {
        final lat = double.tryParse(latController.text.trim());
        final lng = double.tryParse(lngController.text.trim());

        if (lat == null || lng == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter valid coordinates'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _performLocationCheck(lat, lng);
      }
    } else {
      await _performLocationCheck(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  Future<void> _performLocationCheck(double latitude, double longitude) async {
    try {
      final result = await LocationService.checkLocation(
        latitude: latitude,
        longitude: longitude,
        branchId: widget.branchId,
      );

      _showLocationCheckResult(result);
    } catch (e) {
      _showError('Check Location', e);
    }
  }

  Future<void> _deleteLocation(LocationModel location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await LocationService.deleteLocation(location.id!);
        if (result['status'] == 'success') {
          setState(() => _lastResult = result['message']);
          _loadLocations();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(result['message']);
        }
      } catch (e) {
        _showError('Delete Location', e);
      }
    }
  }

  void _showLocationCheckResult(LocationCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.isWithinLocation ? '✅ Within Location' : '❌ Outside Location',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.isWithinLocation
                    ? 'You are within ${result.matchedLocations.length} location(s)'
                    : 'You are not within any registered location',
              ),
              if (result.matchedLocations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Matched Locations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.matchedLocations.map(
                  (location) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Address: ${location.address}'),
                        Text('Distance: ${location.distance}m'),
                        Text('Radius: ${location.radius}m'),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Current Position: ${result.currentPosition.latitude.toStringAsFixed(6)}, ${result.currentPosition.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String operation, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$operation - Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ ${error.toString()}'),
              const SizedBox(height: 12),
              const Text(
                '🔍 Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API URL: ${ApiService.currentApiUrl}'),
                    Text('Branch ID: ${widget.branchId ?? 'None'}'),
                    Text(
                      'Current Position: ${_currentPosition?.latitude.toStringAsFixed(6) ?? 'Not available'}, ${_currentPosition?.longitude.toStringAsFixed(6) ?? 'Not available'}',
                    ),
                    Text('Error Type: ${error.runtimeType}'),
                    Text('Timestamp: ${DateTime.now().toIso8601String()}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    setState(() => _lastResult = 'Error: $error');
  }
}

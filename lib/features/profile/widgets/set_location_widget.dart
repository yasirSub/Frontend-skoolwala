import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skoolwala/shared/services/school_location_service.dart';
import 'package:skoolwala/shared/services/api_service.dart';

class SetLocationWidget extends StatefulWidget {
  final int schoolId;

  const SetLocationWidget({super.key, this.schoolId = 1});

  @override
  State<SetLocationWidget> createState() => _SetLocationWidgetState();
}

class _SetLocationWidgetState extends State<SetLocationWidget> {
  List<SchoolLocationModel> _schoolLocations = [];
  bool _isLoading = false;
  String? _lastResult;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadSchoolLocations();
    _getCurrentLocation();
  }

  Future<void> _loadSchoolLocations() async {
    print('🔄 Loading school locations...');
    setState(() => _isLoading = true);
    try {
      final locations = await SchoolLocationService.getSchoolLocations(
        schoolId: widget.schoolId,
        isActive: true,
      );
      print('📥 Loaded ${locations.length} school locations');
      setState(() => _schoolLocations = locations);
      print('✅ School locations updated in UI');
    } catch (e) {
      print('❌ Error loading school locations: $e');
      _showError('Load School Locations', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
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
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set School Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Manage school locations for attendance',
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Current Position',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
                  onPressed: _isLoading ? null : _setLocation,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Set Location'),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkLocation,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Check Location'),
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
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadSchoolLocations,
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

          // School Locations List
          Text(
            'School Locations (${_schoolLocations.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_schoolLocations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('No school locations found')),
            )
          else
            ...(_schoolLocations.map(
              (location) => _buildLocationCard(location),
            )),

          // Result Display
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastResult!,
                      style: const TextStyle(
                        color: Colors.green,
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

  Widget _buildLocationCard(SchoolLocationModel location) {
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

  Future<void> _setLocation() async {
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
        title: const Text('Set School Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Main Campus, Branch Office',
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.green,
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
            child: const Text('Set Location'),
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

      try {
        print('🚀 Starting setLocation API call...');
        print(
          '📤 Sending data: name=${nameController.text.trim()}, lat=$lat, lng=$lng, schoolId=${widget.schoolId}',
        );

        final result = await SchoolLocationService.setLocation(
          name: nameController.text.trim(),
          latitude: lat,
          longitude: lng,
          address: addressController.text.trim(),
          radius: int.tryParse(radiusController.text) ?? 100,
          schoolId: widget.schoolId,
        );

        print('📥 Received response: $result');

        if (result['status'] == 'success') {
          print('✅ Save successful, updating UI...');
          setState(() => _lastResult = result['message']);
          await _loadSchoolLocations(); // Reload the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          print('✅ UI updated successfully');
        } else {
          print('❌ Save failed: ${result['message']}');
          throw Exception(result['message']);
        }
      } catch (e) {
        print('❌ Exception in setLocation: $e');
        _showError('Set Location', e);
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
      final result = await SchoolLocationService.checkLocation(
        latitude: latitude,
        longitude: longitude,
        schoolId: widget.schoolId,
      );

      _showLocationCheckResult(result);
    } catch (e) {
      _showError('Check Location', e);
    }
  }

  Future<void> _deleteLocation(SchoolLocationModel location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete School Location'),
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
        final result = await SchoolLocationService.deleteLocation(location.id!);
        if (result['status'] == 'success') {
          setState(() => _lastResult = result['message']);
          _loadSchoolLocations();
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

  void _showLocationCheckResult(SchoolLocationCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.isWithinLocation
              ? '✅ Within School Location'
              : '❌ Outside School Location',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.isWithinLocation
                    ? 'You are within ${result.matchedLocations.length} school location(s)'
                    : 'You are not within any school location',
              ),
              if (result.matchedLocations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Matched School Locations:',
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
                    Text('School ID: ${widget.schoolId}'),
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

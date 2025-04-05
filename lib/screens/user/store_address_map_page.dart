import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../components/app_bar/custom_app_bar.dart';

class StoreAddressMapPage extends StatefulWidget {
  const StoreAddressMapPage({super.key});

  @override
  State<StoreAddressMapPage> createState() => _StoreAddressMapPageState();
}

class _StoreAddressMapPageState extends State<StoreAddressMapPage> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.whileInUse && 
            requested != LocationPermission.always) {
          throw Exception('Location permission required');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = location;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );

      await _getAddressFromLatLng(location);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        
        _onLocationChanged(location);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: 15),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.street?.isNotEmpty ?? false) place.street,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.country?.isNotEmpty ?? false) place.country,
        ].where((e) => e != null).join(', ');

        setState(() => _searchController.text = address);
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onLocationChanged(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location);
  }

  void _onMapTapped() async {
    if (_mapController == null) return;

    setState(() => _isLoading = true);
    try {
      final bounds = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      
      setState(() => _selectedLocation = center);
      await _getAddressFromLatLng(center); // Only update address when tapped
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Select Store Location',
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedLocation != null && _searchController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'address': _searchController.text,
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a location')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_selectedLocation != null)
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onCameraMove: (position) => _selectedLocation = position.target,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: const {}, // No markers needed with center pin
            ),
          // Centered marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Icon(
                Icons.location_pin,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search location',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Confirm location button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _onMapTapped,
              icon: const Icon(Icons.push_pin),
              label: const Text('Confirm This Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../components/app_bar/custom_app_bar.dart';
import '../../components/buttons/custom_elevated_button.dart';
import '../../providers/auth_provider.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(10.8231, 106.6297); 
  LatLng? _currentMapPosition;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapPosition = position.target;
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        
        if (place.street?.isNotEmpty == true) {
          addressParts.add(place.street!);
        }
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add(place.subLocality!);
        }
        if (place.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          addressParts.add(place.administrativeArea!);
        }

        String address = addressParts.join(', ');
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng newPosition = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
      await _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchAddress(String address) async {
    try {
      if (address.isEmpty) return;
      
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng newPosition = LatLng(
          locations[0].latitude,
          locations[0].longitude,
        );
        _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy địa chỉ')),
      );
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = await AuthProvider.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('${Config.baseurl}/addresses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'address': _addressController.text,
          'latitude': _currentMapPosition?.latitude,
          'longitude': _currentMapPosition?.longitude,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        Navigator.pop(context, {
          'address': _addressController.text,
          'addressId': responseData['addressId'],
          'isUpdate': response.statusCode == 200,
        });
      } else {
        throw Exception('Failed to save address');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu địa chỉ: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title:'Thêm Địa Chỉ Mới',
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 15,
                    ),
                    onCameraMove: _onCameraMove,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 36,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ',
                            hintText: 'Tỉnh/Thành Phố, Quận/Huyện, Phường/Xã',
                          ),
                          onChanged: (value) => _searchAddress(value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập địa chỉ';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        tooltip: 'Lấy vị trí hiện tại',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomElevatedButton(
                    onPressed: _saveAddress,
                    text: 'Lưu Địa Chỉ',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
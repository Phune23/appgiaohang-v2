import 'package:appgiaohang/config/config.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logging/logging.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';

class UserDeliveryTrackingPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const UserDeliveryTrackingPage({super.key, required this.order});

  @override
  State<UserDeliveryTrackingPage> createState() =>
      _UserDeliveryTrackingPageState();
}

class _UserDeliveryTrackingPageState extends State<UserDeliveryTrackingPage> {
  final _logger = Logger('DeliveryTracking');
  late io.Socket socket;
  late MapOptions _navigationOption;
  MapNavigationViewController? _navigationController;
  LatLng? _shipperLocation;
  LatLng? _storeLatLng;
  LatLng? _customerLatLng;
  static const double _initialZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _initializeLocations();
    _initSocket();
  }

  void _initializeNavigation() {
    _navigationOption = MapOptions(
      apiKey: Config.mapapi,
      mapStyle:
          "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=${Config.mapapi}",
      simulateRoute: false,
      enableRefresh: true,
      isOptimized: true,
      voiceInstructionsEnabled: false,
      allowsUTurnAtWayPoints: true,
    );
  }

  void _initializeLocations() {
    _storeLatLng = LatLng(
        double.parse(widget.order['store_latitude'].toString()),
        double.parse(widget.order['store_longitude'].toString()));

    _customerLatLng = LatLng(double.parse(widget.order['latitude'].toString()),
        double.parse(widget.order['longitude'].toString()));
  }

  Future<void> _updateRoute() async {
    if (_navigationController != null && _shipperLocation != null) {
      final destination = widget.order['status'] == 'delivering'
          ? _customerLatLng
          : _storeLatLng;

      if (destination != null) {
        await _navigationController?.buildAndStartNavigation(
          waypoints: [
            _shipperLocation!,
            destination,
          ],
          profile: DrivingProfile.motorcycle,
        );
      }
    }
  }

  Future<void> _addMarkers() async {
    if (_navigationController == null) return;

    await _navigationController?.addImageMarkers([
      if (_storeLatLng != null)
        NavigationMarker(
          imagePath: 'assets/store_marker.png',
          latLng: _storeLatLng!,
          width: 48,
          height: 48,
        ),
      if (_customerLatLng != null)
        NavigationMarker(
          imagePath: 'assets/customer_marker.png',
          latLng: _customerLatLng!,
          width: 48,
          height: 48,
        ),
      if (_shipperLocation != null)
        NavigationMarker(
          imagePath: 'assets/shipper_marker.png',
          latLng: _shipperLocation!,
          width: 48,
          height: 48,
        ),
    ]);
  }

  void _initSocket() {
    socket = io.io(Config.baseurl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    String connectionString = _generateConnectionString();
    socket.emit('join-delivery-room', connectionString);

    socket.on('location-update', (data) {
      setState(() {
        _shipperLocation = LatLng(data['latitude'], data['longitude']);
        _updateRoute();
        _addMarkers();
      });
    });
  }

  String _generateConnectionString() {
    final orderId = widget.order['id']?.toString() ?? '0';
    final storeLat = widget.order['store_latitude']?.toString() ?? '0';
    final storeLng = widget.order['store_longitude']?.toString() ?? '0';
    final lat = widget.order['latitude']?.toString() ?? '0';
    final lng = widget.order['longitude']?.toString() ?? '0';

    final connectionString =
        'delivery_${orderId}_${storeLat}_${storeLng}_${lat}_${lng}';
    print('Connection string: $connectionString');
    return connectionString;
  }

  @override
  void dispose() {
    _navigationController?.onDispose();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order['status'] == 'delivering'
            ? 'Đang giao đến bạn'
            : 'Đang đến lấy hàng'),
      ),
      body: NavigationView(
        mapOptions: _navigationOption,
        onMapCreated: (controller) {
          _navigationController = controller;
          if (_shipperLocation != null) {
            _addMarkers();
            _updateRoute();
          }
        },
        onMapRendered: () {
          if (_shipperLocation != null) {
            _addMarkers();
            _updateRoute();
          }
        },
        onRouteProgressChange: (RouteProgressEvent event) {
          // Handle route progress if needed
        },
      ),
    );
  }
}

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  GoogleMapController _mapController;

  Set<Circle> _circles = HashSet<Circle>();
  static LatLng _initialPosition;
  static LatLng _lastPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _setCircles();
  }

  void _setCircles() {
    _circles.add(Circle(
      circleId: CircleId("Infected Area"),
      center: LatLng(39.890406, 32.847046),
      radius: 1000,
      fillColor: Color.fromRGBO(150, 50, 50, .3),
      strokeWidth: 1,
    ));
    _circles.add(Circle(
      circleId: CircleId("Infected Area 2"),
      center: LatLng(39.870406, 32.897046),
      radius: 2000,
      fillColor: Color.fromRGBO(150, 50, 50, .3),
      strokeWidth: 1,
    ));
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _lastPosition = _initialPosition;
    });
  }

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _initialPosition == null
        ? Container(
            alignment: Alignment.center,
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.black12,
              ),
            ),
          )
        : Scaffold(
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition:
                      CameraPosition(target: _initialPosition, zoom: 12.0),
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: false,
                  onCameraMove: _onCameraMove,
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
                  child: Text(
                    "Veriler gerçeği yansıtmayabilir.",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.0),
                  ),
                )
              ],
            ),
          );
  }
}
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nearX',
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
  Firestore firestore = Firestore.instance;

  Set<Circle> _circles = Set();

  static LatLng _initialPosition;
  static LatLng _lastPosition;

  @override
  void initState() {
    super.initState();
    setState(() {
      _getUserLocation();
      _getCircleLocation();
    });
  }

  void _getCircleLocation() async {
    await firestore
        .collection("locations")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      if (snapshot.documents.isNotEmpty)
        for (int i = 0; i < snapshot.documents.length; i++) {
          _setCircles(snapshot.documents.elementAt(i));
        }
    });
  }

  void _setCircles(DocumentSnapshot location) {
    setState(() {
      Circle resultCircle = Circle(
        circleId: CircleId(_circles.length.toString()),
        center: LatLng(location.data['latitude'], location.data['longitude']),
        radius: 500,
        fillColor: Color.fromRGBO(150, 50, 50, .3),
        strokeWidth: 1,
      );
      _circles.add(resultCircle);
    });
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
                      CameraPosition(target: _initialPosition, zoom: 11.0),
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
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 32),
                  child: FloatingActionButton(
                    onPressed: _addGeoPoint,
                    isExtended: true,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.add),
                  ),
                )
              ],
            ),
          );
  }

  Future<DocumentReference> _addGeoPoint() async {
//    TODO: Change data type to geopoint.
    return await firestore.collection('locations').add({
      'latitude': _initialPosition.latitude,
      'longitude': _initialPosition.longitude,
      'hashcode': _initialPosition.hashCode,
      'numbercases': 1
    });
  }
}

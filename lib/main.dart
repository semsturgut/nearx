import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

//TODO: Unique ID ile veri gonderimi yapilacak (firebase auth ile yapilacak) ?
//TODO: Mavi vaka gönderiminde uyarı penceresi eklenecek ?
//TODO: Mavi ve Kırmızı dairelerin uyarıları ekranda asılı olacak(harita üzerine kırmızı/mavi yazı) halkaların açıklaması ?

//TODO: general diye bir collection acilacak ve icinde maksimum kisi onay sayisi gibi gerekli veriler barindiracak -
//TODO: Olası vakalar Mavi Kesinleşmiş vakalar Kırmızı -
//TODO: Lokasyonlar 2 digit olarak gonderilecek. +
//TODO: Aynı lokasyondan gönderilen 5 adet bildirim Mavi Olası vaka olarak yayınlanacak +
//TODO: Mavi lokasyonlarda haberlerde kanıtlanmış vakalar Kırmızı olarak değiştirilecek ?
//TODO: Documents ismi firebase database de koordinat ile degistirilecek +

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
  List<DocumentSnapshot> circleLocations;

  Set<Circle> _circles = Set();

  static LatLng _initialPosition;
  static LatLng _lastPosition;

  int generalNumber = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _getUserLocation();
      _getCircleLocation();
    });
  }

//  Firebase'den halka loaksyonlarını topluyor
  void _getCircleLocation() async {
    await firestore
        .collection("general")
        .document("maximumDataToBlueCircle")
        .get()
        .then((generalData) {
      generalNumber = generalData.data["number"];
    });
    await firestore
        .collection("locations")
        .getDocuments()
        .then((QuerySnapshot locationsSnapshot) {
      if (locationsSnapshot.documents.isNotEmpty) {
        circleLocations = locationsSnapshot.documents;
        for (int i = 0; i < circleLocations.length; i++) {
          if (circleLocations.elementAt(i).data["numbercases"] >=
                  generalNumber &&
              generalNumber != 0) {
            _setCircles(circleLocations.elementAt(i));
          }
        }
      }
    });
  }

//  Halka lokasyonlarını alıp mapsde gosterme islemini yapiyor
  void _setCircles(DocumentSnapshot location) {
    setState(() {
      Circle resultCircle = Circle(
        circleId: CircleId(_circles.length.toString()),
        center: LatLng(location.data['latitude'], location.data['longitude']),
        radius: 500,
        fillColor: Color.fromRGBO(50, 50, 150, .3),
        strokeWidth: 1,
      );
      _circles.add(resultCircle);
    });
  }

//  Maps kamera hareketi kontrolu
  void _onCameraMove(CameraPosition position) {
    setState(() {
      _lastPosition = _initialPosition;
    });
  }

//  Kullanicinin anlik keskin lokasyon verisi
  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

//  Maps olusturulduktan sonra yapilacaklar bu fonksiyonda
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

//  Build ana tasarim elemanlari
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
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.add),
                  ),
                )
              ],
            ),
          );
  }

//  Kullanicinin bulundugu lokasyondaki vakayi firebase e ekleme
  void _addGeoPoint() async {
    // <--- ASYNC
//    TODO: Butun datalarla latlong karsilastirmasi yapilacak +
//    TODO: FIREBASE AUTH karsilastirmasi ile daha once ayni noktadan veri gondermemisse +1 artacak
//    TODO: Change data type to geopoint.
//    TODO: Neden iki tane async var <--????-->
    String queryName = _initialPosition.latitude.toStringAsFixed(2) +
        '-_-' +
        _initialPosition.longitude.toStringAsFixed(2);
    if (circleLocations.contains(queryName)) {
      for (int i = 0; i < circleLocations.length; i++) {
        if (circleLocations.elementAt(i).documentID == queryName) {
          await firestore.collection("locations").document(queryName).updateData({
            'latitude':
                double.parse(_initialPosition.latitude.toStringAsFixed(2)),
            'longitude':
                double.parse(_initialPosition.longitude.toStringAsFixed(2)),
            'numbercases': circleLocations.elementAt(i).data['numbercases'] + 1
          });
        }
      }
    } else {
      await firestore.collection("locations").document(queryName).setData({
        'latitude': double.parse(_initialPosition.latitude.toStringAsFixed(2)),
        'longitude':
            double.parse(_initialPosition.longitude.toStringAsFixed(2)),
        'numbercases': 1,
      });
    }
  }
}

//if (element.documentID == queryName) {
//await firestore.collection("locations").document(queryName).setData({
//'latitude':
//double.parse(_initialPosition.latitude.toStringAsFixed(2)),
//'longitude':
//double.parse(_initialPosition.longitude.toStringAsFixed(2)),
//'numbercases': element.data['numbercases'] + 1
//});
//} else {
//await firestore.collection("locations").document(queryName).setData({
//'latitude':
//double.parse(_initialPosition.latitude.toStringAsFixed(2)),
//'longitude':
//double.parse(_initialPosition.longitude.toStringAsFixed(2)),
//'numbercases': () {
//if (element.documentID == queryName)
//element.data['numbercases'] = element.data['numbercases'] + 1;
//return element.data['numbercases'];
//}
//});
//}

//await firestore.collection("locations").document(queryName).setData({
//'latitude': double.parse(_initialPosition.latitude.toStringAsFixed(2)),
//'longitude': double.parse(_initialPosition.longitude.toStringAsFixed(2)),
//'numbercases': () {
//if (circleLocations.elementAt(i).documentID == queryName)
//circleLocations.elementAt(i).data['numbercases'] = circleLocations.elementAt(i).data['numbercases'] + 1;
//return circleLocations.elementAt(i).data['numbercases'];
//}
//});

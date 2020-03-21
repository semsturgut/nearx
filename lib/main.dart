import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//TODO: Unique ID ile veri gonderimi yapilacak (firebase auth ile yapilacak) ?
//TODO: Mavi vaka gönderiminde uyarı penceresi eklenecek ?
//TODO: Olası vakalar Mavi Kesinleşmiş vakalar Kırmızı -

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
  int caseCounter = 0;

  int realCases = 0;
  int realFatal = 0;

  bool locationDataChecker = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _getUserLocation();
    });
  }

//  Firebase'den halka loaksyonlarını topluyor
  void _getCircleLocation() async {
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
        fillColor: Color.fromRGBO(0, 0, 255, .1),
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
    await firestore.collection("general").document("options").get().then((generalOptions) {
          setState(() {
            generalNumber = generalOptions.data["maxBlueCheck"];
            realCases = generalOptions.data["realCase"];
            realFatal = generalOptions.data["realFatal"];
            _initialPosition = LatLng(position.latitude, position.longitude);
            _getCircleLocation();
          });
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
    return (_initialPosition == null && generalNumber == 0)
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
                      CameraPosition(target: _initialPosition, zoom: 15.0),
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
                    "Veriler gerçeği yansıtmayabilir",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.fromLTRB(0, 60, 0, 0),
                  child: Text(
                    "Mavi vakalar kullanıcılar tarafından iletilmiştir",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
                  child: Text(
                    "Kırmızı vakalar resmi verilerdir",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 60),
                  child: Text(
                    "Vaka: " + realCases.toString(),
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 40),
                  child: Text(
                    "Ölüm: " + realFatal.toString(),
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.0),
                  ),
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 32),
                  child: FloatingActionButton.extended(
                    onPressed: _addGeoPoint,
                    isExtended: true,
                    backgroundColor: Colors.white,
                    label: Text(
                      "Vaka ekle",
                      style: TextStyle(color: Colors.black),
                    ),
                    icon: Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            ),
          );
  }

//  Kullanicinin bulundugu lokasyondaki vakayi firebase e ekleme
  void _addGeoPoint() async {
//    TODO: FIREBASE AUTH karsilastirmasi ile daha once ayni noktadan veri gondermemisse +1 artacak
//    TODO: Change data type to geopoint.
    String queryName = _initialPosition.latitude.toStringAsFixed(2) +
        '-_-' +
        _initialPosition.longitude.toStringAsFixed(2);

    await firestore.collection("locations").getDocuments().then((value) {
      for (int i = 0; i < value.documents.length; i++) {
        if (value.documents.elementAt(i).documentID == queryName) {
          locationDataChecker = true;
          caseCounter = value.documents.elementAt(i).data["numbercases"];
        }
      }
    });

    if (locationDataChecker) {
      locationDataChecker = false;
      for (int i = 0; i < circleLocations.length; i++) {
        if (circleLocations.elementAt(i).documentID == queryName) {
          await firestore
              .collection("locations")
              .document(queryName)
              .updateData({
            'latitude':
                double.parse(_initialPosition.latitude.toStringAsFixed(2)),
            'longitude':
                double.parse(_initialPosition.longitude.toStringAsFixed(2)),
            'numbercases': caseCounter + 1
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

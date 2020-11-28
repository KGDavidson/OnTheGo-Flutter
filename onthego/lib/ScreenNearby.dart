import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import 'package:geolocator/geolocator.dart';

final int animationDuration = 300;

final double toggleBarHeight = 0.06;
final double toggleHeight = toggleBarHeight * 0.8;
final double toggleWidth = 0.5;
final double pullTabHeight = 0.025;
final double listViewTitleBarHeight = 0.2;
final double listViewItemHeight = 0.13;

final double listViewTitleBarTextSize = 0.025;
final double listViewItemTextSize = 0.02;

final double initialMapHeight = 200;
final double endMapHeight = 500;

final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
final MapController mapController = MapController();

int selectedToggle = 0;
double lastPosition = 0;
double mapHeight = initialMapHeight;

String titleText = "XXXXX";
String subText = "ID XXXXXX | towards XXXXXX";

Position currentLocation;

StopBus currentStop;
List currentNearbyStops;
List currentArrivalTimes;

class StopBus {
  final String stopLetter;
  final String commonName;
  final String naptanId;
  final double distance;
  final double lat;
  final double lon;

  StopBus({this.stopLetter, this.commonName, this.naptanId, this.distance, this.lat, this.lon});

  factory StopBus.fromJson(Map<String, dynamic> json) {
    return StopBus(
      stopLetter: json['indicator'],
      commonName: json['commonName'],
      naptanId: json["naptanId"],
      distance: json['distance'],
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

class ArrivalTime {
  final String vehicleId;
  final String lineName;
  final String destinationName;
  final int timeToStation;

  ArrivalTime({this.vehicleId, this.lineName, this.timeToStation, this.destinationName});

  factory ArrivalTime.fromJson(Map<String, dynamic> json) {
    return ArrivalTime(
      vehicleId: json['vehicleId'],
      lineName: json['lineName'],
      destinationName: json["destinationName"],
      timeToStation: json['timeToStation'],
    );
  }
}

Future<List> fetchCurrentNearbyStops(Position currentLocation) async {
  String url = 'https://api.tfl.gov.uk/Stoppoint';
  url += "?lat=" + currentLocation.latitude.toString() + "&lon=" + currentLocation.longitude.toString();
  if (selectedToggle == 0) {
    url += "&stoptypes=NaptanPublicBusCoachTram";
  } else {
    url += "&stoptypes=NaptanMetroStation,NaptanRailStation";
  }
  url += "&radius=1000";
  print(url);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['stopPoints'].map((stop) => StopBus.fromJson(stop)).toList();
  } else {
    throw Exception('Failed to load');
  }
}

Future<List> fetchArrivalTimes() async {
  String url = 'https://api.tfl.gov.uk/Stoppoint/';
  url += currentStop.naptanId;
  url += "/arrivals";
  print(url);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body).map((arrivalTime) => ArrivalTime.fromJson(arrivalTime)).toList();
  } else {
    throw Exception('Failed to load');
  }
}

class ScreenNearby extends StatefulWidget {
  @override
  _ScreenNearby createState() => _ScreenNearby();
}


class _ScreenNearby extends State<ScreenNearby> {
  List futureAlbum;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  void reloadPage() {
    setState(() {});
  }

  void getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
          currentNearbyStops = await fetchCurrentNearbyStops(position);
          currentStop = currentNearbyStops[0];
          mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
          currentArrivalTimes = await fetchArrivalTimes();
          currentArrivalTimes.sort((a, b) {
            return a.timeToStation.compareTo(b.timeToStation);
          });
          setState(() {});
        }).catchError((e) {
          print(e);
        });
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: <Widget>[
        ListViewPage(getCurrentLocation, reloadPage),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        MapView(reloadPage),
        TopToggleBar(getCurrentLocation),
      ],
    );
  }
}

class TopToggleBar extends StatefulWidget {
  VoidCallback getCurrentLocation;
  TopToggleBar(this.getCurrentLocation);

  @override
  _TopToggleBarState createState() => _TopToggleBarState();
}

class _TopToggleBarState extends State<TopToggleBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: Color(0xff53354a),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            offset: Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      height: MediaQuery.of(context).size.height * toggleBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: (){
              setState(() {
                selectedToggle = 0;
                this.widget.getCurrentLocation();
              });
            },
            child: AnimatedContainer(
                height: MediaQuery.of(context).size.height * toggleHeight,
                width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (toggleBarHeight - toggleHeight) * 3 / 2)) * toggleWidth,
                decoration: BoxDecoration(
                  color: selectedToggle == 0 ? Color(0xffe84545) : null,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(MediaQuery.of(context).size.height * toggleHeight), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * toggleHeight)),
                  border: Border.all(color: Color(0xffe84545), width: 3),
                ),
                duration: Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: Center(
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                  ),
                )
            ),
          ),
          GestureDetector(
            onTap: (){
              setState(() {
                selectedToggle = 1;
                this.widget.getCurrentLocation();
              });
            },
            child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: MediaQuery.of(context).size.height * toggleHeight,
                width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (toggleBarHeight - toggleHeight) * 3 / 2)) * toggleWidth,
                decoration: BoxDecoration(
                  color: selectedToggle == 1 ? Color(0xffe84545) : null,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height * toggleHeight), bottomRight: Radius.circular(MediaQuery.of(context).size.height * toggleHeight)),
                  border: Border.all(color: Color(0xffe84545), width: 3),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_train,
                    color: Colors.white,
                  ),
                )
            ),
          ),
        ],
      ),
    );
  }
}

class MapView extends StatefulWidget {
  VoidCallback reloadPage;
  MapView(this.reloadPage);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedContainer(
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * toggleBarHeight),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: mapHeight,
          child: FlutterMap(
            mapController: mapController,
            options: new MapOptions(
              center: LatLng(51.507351, -0.127758),
              zoom: 13.0,
              maxZoom: 17.5,
            ),
            layers: [
              new TileLayerOptions(
                //https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png
                //https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              new MarkerLayerOptions(
                markers: currentNearbyStops != null ? currentNearbyStops.map((item) => Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(item.lat, item.lon),
                  builder: (ctx) =>
                      GestureDetector(
                          onTap: () async{
                            currentStop = item;
                            currentArrivalTimes = await fetchArrivalTimes();
                            currentArrivalTimes.sort((a, b) {
                              return a.timeToStation.compareTo(b.timeToStation);
                            });
                            mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
                            mapHeight = initialMapHeight;
                            this.widget.reloadPage();
                          },
                          child:  Stack(
                            children: <Widget>[
                              Icon(
                                Icons.location_pin,
                                color: Colors.black,
                                size: currentStop == item ? 40 : 32,
                              ),
                              Icon(
                                Icons.location_pin,
                                color: Color(currentStop == item ? 0xffe84545 : 0xffFFBFBF),
                                size: currentStop == item ? 38.5 : 30.5,
                              ),
                            ],
                          )
                      ),
                ),
                ).toList() : [],
              ),
            ],
          ),
        ),
        GestureDetector(
          onVerticalDragStart: (details) {
            lastPosition = details.globalPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              double change = details.globalPosition.dy - lastPosition;
              mapHeight += change;
              lastPosition = details.globalPosition.dy;
              if (mapHeight < initialMapHeight) {
                mapHeight = initialMapHeight;
              }
              if (mapHeight > endMapHeight) {
                mapHeight = endMapHeight;
              }
            });
          },
          onVerticalDragEnd: (details) {
            setState(() {
              if (details.primaryVelocity > 0) {
                mapHeight = endMapHeight;
              } else {
                mapHeight = initialMapHeight;
              }
            });
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * pullTabHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(MediaQuery.of(context).size.height * pullTabHeight), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * pullTabHeight)),
              color: Color(0xffe84545),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 0.1,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),

              ],
            ),
            child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.height * pullTabHeight * 0.07)),
                        color: Color(0xffFFBFBF),
                      ),
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * pullTabHeight * 0.4),
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height * pullTabHeight * 0.07,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.height * pullTabHeight * 0.07)),
                        color: Color(0xffFFBFBF),
                      ),
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * pullTabHeight * 0.2),
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height * pullTabHeight * 0.07,
                    ),
                  ],
                )
            ),
          ),
        ),
      ],
    );
  }
}

class ListViewPage extends StatefulWidget {
  VoidCallback getCurrentLocation;
  VoidCallback reloadPage;
  ListViewPage(this.getCurrentLocation, this.reloadPage);

  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  @override//(MediaQuery.of(context).size.height * (toggleBarHeight + pullTabHeight)) + mapHeight
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity > 0) {
          selectedToggle = 0;
        } else if(details.primaryVelocity < 0){
          selectedToggle = 1;
        }
        this.widget.getCurrentLocation();
        this.widget.reloadPage();
      },
      child: Column(
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: (MediaQuery.of(context).size.height * (toggleBarHeight)) + initialMapHeight),
              color: Color(0xffe8e8e8),
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * (pullTabHeight)),
                    color: Color(0xff903749),
                    height: MediaQuery.of(context).size.width * listViewTitleBarHeight,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                            icon: Icon(currentStop != null ? Icons.arrow_back : null, color: Colors.white,),
                            onPressed: () {
                              currentStop = null;
                              setState(() {});
                            }
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3),
                              child: Text(
                                currentStop != null ? currentStop.commonName.length > 20 ? currentStop.commonName.replaceRange(21, currentStop.commonName.length, "...") : currentStop.commonName : "Nearby Stops",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize,
                                ),
                              ),
                            ),
                            currentStop != null ? Container(
                              padding: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3,
                                  top: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 4
                              ),
                              child: Text(
                                subText,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 2,
                                ),
                              ),
                            ) : Container(),
                          ],
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                          ),
                        ),
                        currentStop != null ? Container(
                          height: MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.6,
                          width: MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.6,
                          margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.6)),
                            color: Color(0xffe84545),
                          ),
                          child: Center(
                              child: GestureDetector(
                                  onTap:() {
                                    mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
                                    setState(() {});
                                  },
                                  child: currentStop.stopLetter == null || currentStop.stopLetter.toString().contains("->") || currentStop.stopLetter == "Stop" ? Icon(Icons.directions_bus, color: Colors.white,) : Text(currentStop.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:  MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.6 * 0.4,),)
                              )
                          ),
                        ) : Container(),
                      ],
                    ),
                  ),

                  currentStop == null ? Container(
                    height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                    child: SingleChildScrollView(
                      child: Column(
                        children: currentNearbyStops != null ? currentNearbyStops.map((item) => Container(
                          height: MediaQuery.of(context).size.width * listViewItemHeight,
                          child: FlatButton(
                            onPressed: () async {
                              currentStop = item;
                              currentArrivalTimes = await fetchArrivalTimes();
                              currentArrivalTimes.sort((a, b) {
                                return a.timeToStation.compareTo(b.timeToStation);
                              });
                              mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
                              setState(() {});
                            },
                            color: Color(0xffe8e8e8),
                            child: Row(
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * listViewItemTextSize),
                                      child: Text(
                                        item.commonName,
                                        style: TextStyle(
                                          color: Color(0xff2b2e4a),
                                          fontSize: MediaQuery.of(context).size.height * listViewItemTextSize,
                                        ),
                                      ),
                                    ),
                                    item != null ? Container(
                                      padding: EdgeInsets.only(
                                          left: MediaQuery.of(context).size.height * listViewItemTextSize,
                                          top: MediaQuery.of(context).size.height * listViewItemTextSize / 4
                                      ),
                                      child: Text(
                                        subText,
                                        style: TextStyle(
                                          color: Color(0xff53354a),
                                          fontSize: MediaQuery.of(context).size.height * listViewItemTextSize / 2,
                                        ),
                                      ),
                                    ) : Container(),
                                  ],
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    width: 100.0,
                                    height: 100.0,
                                  ),
                                ),
                                item != null ? Container(
                                  height: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6,
                                  width: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6,
                                  margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6)),
                                    color: Color(0xffe84545),
                                  ),
                                  child: Center(
                                    child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop" ? Icon(Icons.directions_bus, color: Colors.white,) : Text(item.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                  ),
                                ) : Container(),
                              ],
                            ),
                          ),
                        )).toList() : [Container()],
                      ),
                    ),
                  ) : Container(
                    height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                    child: SingleChildScrollView(
                      child: Column(
                        children: currentArrivalTimes != null && currentArrivalTimes.isNotEmpty ? currentArrivalTimes.map((item) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          color: Color(0xffe8e8e8),
                          height: MediaQuery.of(context).size.width * listViewItemHeight,
                          child: Row(
                            children: <Widget>[
                              item.lineName != null ? Container(
                                height: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6,
                                width: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6 * 2,
                                margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.6)),
                                  color: Color(0xffe84545),
                                ),
                                child: Center(
                                  child: Text(
                                      item.lineName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      )
                                  ),
                                ),
                              ) : Container(),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * listViewItemTextSize),
                                    child: Text(
                                      item.destinationName != null ? item.destinationName.length > 20 ? item.destinationName.replaceRange(21, item.destinationName.length, "...") : item.destinationName : "",
                                      style: TextStyle(
                                        color: Color(0xff2b2e4a),
                                        fontSize: MediaQuery.of(context).size.height * listViewItemTextSize,
                                      ),
                                    ),
                                  ),
                                  item.vehicleId != null ? Container(
                                    padding: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.height * listViewItemTextSize,
                                        top: MediaQuery.of(context).size.height * listViewItemTextSize / 4
                                    ),
                                    child: Text(
                                      item.vehicleId,
                                      style: TextStyle(
                                        color: Color(0xff53354a),
                                        fontSize: MediaQuery.of(context).size.height * listViewItemTextSize / 2,
                                      ),
                                    ),
                                  ) : Container(),
                                ],
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  width: 100.0,
                                  height: 100.0,
                                ),
                              ),
                              item.timeToStation != null ? Container(
                                height: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight),
                                margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.2),
                                child: Center(
                                  child: Text(
                                      (item.timeToStation / 60).ceil().toString() + ((item.timeToStation / 60).ceil() > 0 ? " mins" : "min"),
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: MediaQuery.of(context).size.width * (listViewItemHeight - pullTabHeight) * 0.5,
                                        fontWeight: FontWeight.bold,
                                      )
                                  ),
                                ),
                              ) : Container(),
                            ],
                          ),
                        )).toList() : [Container()],
                      ),
                    ),
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }
}

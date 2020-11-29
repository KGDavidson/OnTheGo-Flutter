import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";
import 'package:http/http.dart' as http;

const FAVOURITES_ID_LIST_KEY = "57";

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
double currentBlurValue = 0;

bool loading = false;

Position currentLocation;

Stop currentStop;
List currentNearbyStops;
List currentArrivalTimes;
List currentFavorites = [];

readFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getStringList(FAVOURITES_ID_LIST_KEY) ?? [];
  currentFavorites = value;
  print('read: $currentFavorites');
}

writeFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList(FAVOURITES_ID_LIST_KEY, currentFavorites);
  print('saved $currentFavorites');
}

class Stop {
  final String stopLetter;
  final String commonName;
  final String naptanId;
  final double distance;
  final double lat;
  final double lon;
  final List lines;

  Stop({this.stopLetter, this.commonName, this.naptanId, this.distance, this.lat, this.lon, this.lines});

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopLetter: json['indicator'],
      commonName: json['commonName'],
      naptanId: json["naptanId"],
      distance: json['distance'],
      lat: json['lat'],
      lon: json['lon'],
      lines: json['lines'].map((item) => item["name"]).toList(),
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
    return jsonDecode(response.body)['stopPoints'].map((stop) => Stop.fromJson(stop)).toList();
  } else {
    throw Exception('Failed to load');
  }
}

Future<List> fetchArrivalTimes() async {
  String url = 'https://api.tfl.gov.uk/Stoppoint/';
  url += currentStop.naptanId;
  url += "/arrivals";
  print("////" + url);
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
    readFavourites().then(() {
      loading = true;
      setState(() {});
      getCurrentLocationAndFindClosest();
    }());
  }

  void reloadPage() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 400), () => {
      mapController.move(LatLng(mapController.center.latitude + 0.0000000001, mapController.center.longitude + 0.0000000001), mapController.zoom)
    });
  }

  void getCurrentLocationAndFindClosest() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
          currentLocation = position;
          currentNearbyStops = (await fetchCurrentNearbyStops(position)).where((item) => item.lines.isNotEmpty).toList();
          currentStop = currentNearbyStops[0];
          mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
          currentArrivalTimes = await fetchArrivalTimes();
          currentArrivalTimes.sort((a, b) {
            return a.timeToStation.compareTo(b.timeToStation);
          });
          loading = false;
          setState(() {});
        }).catchError((e) {
          print(e);
        });
  }

  void getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      currentLocation = position;
      currentNearbyStops = (await fetchCurrentNearbyStops(position)).where((item) => item.lines.isNotEmpty).toList();
      loading = false;
      setState(() {});
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop:() async {
        if (currentStop != null) {
          currentStop = null;
          setState(() {});
          return false;
        }
        return true;
      },
      child: Stack(
        children: <Widget>[
          ListViewPage(getCurrentLocationAndFindClosest, getCurrentLocation, reloadPage),
          IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: currentBlurValue, sigmaY: currentBlurValue),
              child: Container(
                color: Colors.black.withOpacity(currentBlurValue > 0 ? currentBlurValue / 4 : 0),
              ),
            ),
          ),
          MapView(reloadPage),
          TopToggleBar(getCurrentLocationAndFindClosest, reloadPage),
          loading ? LoadingOverlay() : Container(),
        ],
      ),
    );
  }
}

class TopToggleBar extends StatefulWidget {
  VoidCallback getCurrentLocationAndFindClosest;
  VoidCallback reloadPage;
  TopToggleBar(this.getCurrentLocationAndFindClosest, this.reloadPage);

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
                loading = true;
                this.widget.getCurrentLocationAndFindClosest();
                this.widget.reloadPage();
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
                duration: Duration(milliseconds: animationDuration),
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
                loading = true;
                this.widget.getCurrentLocationAndFindClosest();
                this.widget.reloadPage();
              });
            },
            child: AnimatedContainer(
                duration: Duration(milliseconds: animationDuration),
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
          duration: Duration(milliseconds: animationDuration),
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
                subdomains: ['a', 'b', 'c', 'd'],
              ),
              new MarkerLayerOptions(
                markers: currentNearbyStops != null ? () {
                  List<Marker> returnList = currentNearbyStops.map((item) => Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(item.lat, item.lon),
                    builder: (ctx) =>
                        GestureDetector(
                          child: Icon(
                              Icons.location_pin,
                              size: currentStop == item ? 38.5 : 30.5,
                              color: Color(currentStop == item ? 0xffe84545 : 0x802b2e4a),
                          ),
                          onTap: () async {
                            currentStop = item;
                            currentArrivalTimes = await fetchArrivalTimes();
                            currentArrivalTimes.sort((a, b) {
                              return a.timeToStation.compareTo(b.timeToStation);
                            });
                            mapController.move(LatLng(currentStop.lat, currentStop.lon), 15);
                            mapHeight = initialMapHeight;
                            currentBlurValue = 0;
                            this.widget.reloadPage();
                          },
                        ),
                  ),
                  ).toList();
                  if (currentLocation != null) {
                    returnList.add(Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(currentLocation.latitude,
                            currentLocation.longitude),
                        builder: (ctx) =>
                          Icon(
                            Icons.my_location,
                            color: Colors.black,
                            size: 30,
                          ),
                    ));
                  }
                  return returnList;
                }() : [],
              ),
            ],
          ),
        ),
        GestureDetector(
          onVerticalDragStart: (details) {
            lastPosition = details.globalPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            double change = details.globalPosition.dy - lastPosition;
            mapHeight += change;
            lastPosition = details.globalPosition.dy;
            if (mapHeight < initialMapHeight) {
              mapHeight = initialMapHeight;
            }
            if (mapHeight > endMapHeight) {
              mapHeight = endMapHeight;
            }
            currentBlurValue = 2 * ((mapHeight - initialMapHeight) / (endMapHeight - initialMapHeight));
            this.widget.reloadPage();
          },
          onVerticalDragEnd: (details) {
            if (endMapHeight - mapHeight < 10) {
              mapHeight = endMapHeight;
              currentBlurValue = 2;
            } else {
              if (details.primaryVelocity > 0) {
                mapHeight = endMapHeight;
                currentBlurValue = 2;
              } else {
                mapHeight = initialMapHeight;
                currentBlurValue = 0;
              }
            }
            this.widget.reloadPage();
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
                    Icon(Icons.arrow_drop_down, color: Colors.white,),
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
  VoidCallback getCurrentLocationAndFindClosest;
  VoidCallback getCurrentLocation;
  VoidCallback reloadPage;

  ListViewPage(this.getCurrentLocationAndFindClosest, this.getCurrentLocation, this.reloadPage);

  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        int currentSelectedToggle = selectedToggle;
        if (details.primaryVelocity > 0) {
          selectedToggle = 0;
        } else if(details.primaryVelocity < 0){
          selectedToggle = 1;
        }
        if (currentSelectedToggle != selectedToggle) {
          loading = true;
          this.widget.getCurrentLocationAndFindClosest();
          this.widget.reloadPage();
        }
      },
      child: Column(
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: (MediaQuery.of(context).size.height * (toggleBarHeight)) + initialMapHeight),
              color: Color(0xffe8e8e8),
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: Duration(milliseconds: animationDuration),
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
                              this.widget.reloadPage();
                            }
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3, right: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3),
                                  child: Text(
                                    currentStop != null ? currentStop.commonName.length > 17 ? currentStop.commonName.replaceRange(18, currentStop.commonName.length, "...") : currentStop.commonName : "Nearby Stops",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize,
                                    ),
                                  ),
                                ),
                                currentStop != null ? GestureDetector(
                                  onTap: () {
                                    if (currentFavorites.contains(currentStop.naptanId)) {
                                      currentFavorites.removeWhere((item) => item == currentStop.naptanId);
                                      writeFavourites();
                                      setState(() {});
                                    } else {
                                      currentFavorites.add(currentStop.naptanId);
                                      writeFavourites();
                                      setState(() {});
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 3, right: 3, bottom: 3, top: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color(0xff2b2e4a),
                                    ),
                                    child: Icon(currentFavorites.contains(currentStop.naptanId) ? Icons.favorite : Icons.favorite_border, color: Color(0xffe84545),),
                                  )
                                ) : Container(),
                              ],
                            ),
                            currentStop != null ? Container(
                              padding: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3,
                                  top: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 4
                              ),
                              child: Text(
                                "ID " + currentStop.naptanId + " | " + currentStop.lines.join(" • "),
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
                                  child: currentStop.stopLetter == null || currentStop.stopLetter.toString().contains("->") || currentStop.stopLetter == "Stop" ? selectedToggle == 0 ? Icon(Icons.directions_bus, color: Colors.white,) : Icon(Icons.directions_train, color: Colors.white,) : Text(currentStop.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:  MediaQuery.of(context).size.width * (listViewTitleBarHeight - pullTabHeight) * 0.6 * 0.4,),)
                              )
                          ),
                        ) : Container(),
                      ],
                    ),
                  ),

                  currentStop == null ? Container(
                    height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        loading = true;
                        this.widget.getCurrentLocation();
                        this.widget.reloadPage();
                      },
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: currentNearbyStops != null ? () {
                            List returnNearbyStops = currentNearbyStops.map((item) => Container(
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
                                            "ID " + item.naptanId + " | " + item.lines.join(" • "),
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
                                        child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop" ? selectedToggle == 0 ? Icon(Icons.directions_bus, color: Colors.white,) : Icon(Icons.directions_train, color: Colors.white,) : Text(item.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                      ),
                                    ) : Container(),
                                  ],
                                ),
                              ),
                            )).toList();
                            returnNearbyStops.add(Container(
                              height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                            ));
                            return returnNearbyStops;
                          }() : [Container()],
                        ),
                      ),
                    ),
                  ) : Container(
                    height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        currentArrivalTimes = await fetchArrivalTimes();
                        currentArrivalTimes.sort((a, b) {
                          return a.timeToStation.compareTo(b.timeToStation);
                        });
                        setState(() {});
                      },
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: currentArrivalTimes != null ? () {
                            List returnArrivalTimes = currentArrivalTimes.map((item) => AnimatedContainer(
                              duration: Duration(milliseconds: animationDuration),
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
                            )).toList();
                            returnArrivalTimes.add(AnimatedContainer(
                              duration: Duration(milliseconds: animationDuration),
                              curve: Curves.easeOut,
                              height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (toggleBarHeight + listViewTitleBarHeight) + initialMapHeight - 15),
                            ));
                            return returnArrivalTimes;
                          }() : [Container()],
                        ),
                      ),
                    )
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}


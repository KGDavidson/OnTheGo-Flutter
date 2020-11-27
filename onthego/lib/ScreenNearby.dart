import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart";

/*
class Test {
  final String id;
  final double distance;
  final int commonName;

  Test({this.id, this.distance, this.commonName});

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      distance: json['distance'],
      commonName: json['pageSize'],
    );
  }
}

Future<Test> fetchAlbum() async {
  final response = await http.get('https://api.tfl.gov.uk/Stoppoint?lat=51.605202&lon=-0.304100&stoptypes=NaptanMetroStation,NaptanRailStation,NaptanBusCoachStation,NaptanFerryPort,NaptanPublicBusCoachTram&radius=1000');

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.

    return Test.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load');
  }
}
 */

const double toggleBarHeight = 0.06;
const double toggleHeight = toggleBarHeight * 0.8;
const double toggleWidth = 0.5;
const double pullTabHeight = 0.025;
const double initialMapHeight = 200;
const double endMapHeight = 500;

const int animationDuration = 300;

int selectedToggle = 0;
double lastPosition = 0;
double mapHeight = initialMapHeight;

class ScreenNearby extends StatefulWidget {
  @override
  _ScreenNearby createState() => _ScreenNearby();
}


class _ScreenNearby extends State<ScreenNearby> {
  //Future<Test> futureAlbum;
  @override
  void initState() {
    super.initState();
    //futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        MapView(),
        TopToggleBar(),
      ],
    );
    /*FutureBuilder<Test>(
      future: futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data.commonName.toString());
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );*/
  }
}

class TopToggleBar extends StatefulWidget {
  @override
  _TopToggleBarState createState() => _TopToggleBarState();
}

class _TopToggleBarState extends State<TopToggleBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: Color(0xff3b6978),
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
              });
            },
            child: AnimatedContainer(
                height: MediaQuery.of(context).size.height * toggleHeight,
                width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (toggleBarHeight - toggleHeight) * 3 / 2)) * toggleWidth,
                decoration: BoxDecoration(
                  color: selectedToggle == 0 ? Color(0xfff05454) : null,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(MediaQuery.of(context).size.height * toggleHeight), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * toggleHeight)),
                  border: Border.all(color: Color(0xfff05454), width: 3),
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
              });
            },
            child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: MediaQuery.of(context).size.height * toggleHeight,
                width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (toggleBarHeight - toggleHeight) * 3 / 2)) * toggleWidth,
                decoration: BoxDecoration(
                  color: selectedToggle == 1 ? Color(0xfff05454) : null,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height * toggleHeight), bottomRight: Radius.circular(MediaQuery.of(context).size.height * toggleHeight)),
                  border: Border.all(color: Color(0xfff05454), width: 3),
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
            options: new MapOptions(
              center: LatLng(51.5, -0.09),
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
                markers: [
                  new Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(51.5, -0.09),
                    builder: (ctx) =>
                    new Container(
                      child: new FlutterLogo(),
                    ),
                  ),
                ],
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
              color: Color(0xfff05454),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  offset: Offset(0, -1),
                  blurRadius: 3,
                ),

              ],
            ),
            child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * pullTabHeight * 0.4),
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height * pullTabHeight * 0.07,
                      color: Colors.white,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * pullTabHeight * 0.2),
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.height * pullTabHeight * 0.07,
                      color: Colors.white,
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

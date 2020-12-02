import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const FAVOURITES_ID_LIST_KEY = "57";

final int animationDuration = 300;

final double listViewTitleBarHeight = 0.15;
final double listViewItemHeight = 0.13;

final double listViewTitleBarTextSize = 0.025;
final double listViewItemTextSize = 0.02;

bool loading = false;
bool favouritesChanged = false;

Position currentLocation;

Stop currentStop;
List currentFavouriteStops;
List currentArrivalTimes;
List currentFavourites = [];

readFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getStringList(FAVOURITES_ID_LIST_KEY) ?? [];
  currentFavourites = value;
}

writeFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList(FAVOURITES_ID_LIST_KEY, currentFavourites);
  print('saved $currentFavourites');
}

class Stop {
  final String stopLetter;
  final String commonName;
  final String naptanId;
  final double lat;
  final double lon;
  final List lines;

  Stop({this.stopLetter, this.commonName, this.naptanId, this.lat, this.lon, this.lines});

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopLetter: json['indicator'],
      commonName: json['commonName'],
      naptanId: json["naptanId"],
      lat: json["lat"],
      lon: json["lon"],
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

getCurrentLocation() async{
  await Geolocator
      .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
      .then((Position position) async {
    currentLocation = position;
  }).catchError((e) {
    print(e);
  });
}

double calculateDistance(lat1, lon1, lat2, lon2){
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 +
      c(lat1 * p) * c(lat2 * p) *
          (1 - c((lon2 - lon1) * p))/2;
  return 12742 * asin(sqrt(a));
}

Future<List> fetchFavouriteStops() async {
  List favouriteStops = [];
  for (String item in currentFavourites) {
    Stop favouriteStop = await fetchFavouriteStop(item);
    favouriteStops.add(favouriteStop);
  }
  await getCurrentLocation();
  favouriteStops.sort((a, b) {
    return calculateDistance(currentLocation.latitude, currentLocation.longitude, a.lat, a.lon).compareTo(calculateDistance(currentLocation.latitude, currentLocation.longitude, b.lat, b.lon));
  });
  return (favouriteStops);
}

Future<Stop> fetchFavouriteStop(String naptanId) async {
  String url = 'https://api.tfl.gov.uk/Stoppoint/' + naptanId;
  print("///" + url);
  final response = await http.get(url);

  if (response.statusCode == 200){
    if (jsonDecode(response.body)["naptanId"] == naptanId) {
      return (Stop.fromJson(jsonDecode(response.body)));
    }
    List children = jsonDecode(response.body)["children"].toList();
    if (children[0]["children"].toList() != null) {
      List firstCheck = children.where((item) => item["naptanId"] == naptanId)
          .toList().map((item) => Stop.fromJson(item))
          .toList();
      if (firstCheck.isNotEmpty) {
        return firstCheck[0];
      } else {
        return children.map((item) =>
            item["children"].toList().where((item) => item["naptanId"] ==
                naptanId).toList()
                .map((item) => Stop.fromJson(item))
                .toList()).toList().where((item) =>
        item.length > 0).toList()[0][0];
      }
    } else {
      return children.where((item) => item["naptanId"] == naptanId)
          .toList()
          .map((item) => Stop.fromJson(item))
          .toList()[0];
    }
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

class ScreenRoutePlanner extends StatefulWidget {
  @override
  _ScreenRoutePlanner createState() => _ScreenRoutePlanner();
}


class _ScreenRoutePlanner extends State<ScreenRoutePlanner> {
  List futureAlbum;

  @override
  void initState() {
    super.initState();
    /*loading = true;
    setState(() {});
    readFavourites().then((ret) async {
      currentFavouriteStops = await fetchFavouriteStops();
      loading = false;
      setState(() {});
    });*/
  }

  void reloadPage() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop:() async {
        if (currentStop != null) {
          currentStop = null;
          setState(() {});
          if (favouritesChanged) {
            favouritesChanged = false;
            loading = true;
            setState(() {});
            readFavourites().then((ret) async {
              currentFavouriteStops = await fetchFavouriteStops();
              loading = false;
              setState(() {});
            });
          }
          return false;
        }
        return true;
      },
      child: Stack(
        children: <Widget>[
          ListViewPage(reloadPage),
          loading ? LoadingOverlay() : Container(),
        ],
      ),
    );
  }
}

class ListViewPage extends StatefulWidget {
  VoidCallback reloadPage;

  ListViewPage(this.reloadPage);

  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            color: Color(0xffe8e8e8),
            child: Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: Duration(milliseconds: animationDuration),
                  curve: Curves.easeOut,
                  color: Color(0xff903749),
                  height: MediaQuery.of(context).size.width * listViewTitleBarHeight,
                  padding: EdgeInsets.only(top: 7),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(currentStop != null ? Icons.arrow_back : null, color: Colors.white,),
                          onPressed: () async {
                            currentStop = null;
                            this.widget.reloadPage();
                            if (favouritesChanged) {
                              favouritesChanged = false;
                              loading = true;
                              this.widget.reloadPage();
                              readFavourites().then((ret) async {
                                currentFavouriteStops = await fetchFavouriteStops();
                                loading = false;
                                this.widget.reloadPage();
                              });
                            }
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
                                  currentStop != null ? currentStop.commonName.length > 17 ? currentStop.commonName.replaceRange(18, currentStop.commonName.length, "...") : currentStop.commonName : "Route Planner",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize,
                                  ),
                                ),
                              ),
                              currentStop != null ? GestureDetector(
                                  onTap: () {
                                    if (currentFavourites.contains(currentStop.naptanId)) {
                                      currentFavourites.removeWhere((item) => item == currentStop.naptanId);
                                    } else {
                                      currentFavourites.add(currentStop.naptanId);
                                    }
                                    writeFavourites();
                                    favouritesChanged = true;
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 3, right: 3, bottom: 3, top: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color(0xff2b2e4a),
                                    ),
                                    child: Icon(currentFavourites.contains(currentStop.naptanId) ? Icons.favorite : Icons.favorite_border, color: Color(0xffe84545),),
                                  )
                              ) : Container(),
                            ],
                          ),
                          Container(
                            child: currentStop != null ? Container(
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
                            ) : Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3,
                                      bottom: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 10,
                                  ),
                                  child: Text(
                                    "FROM",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3,
                                      top: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 1.8,
                                  ),
                                  width: 100,
                                  height: 18,
                                  child: TextField(
                                    onChanged:(val) {
                                      print(val);
                                    },
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    decoration: InputDecoration(
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      hintText: 'Enter Station..'
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height * listViewTitleBarTextSize,
                                    bottom: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 10,
                                  ),
                                  child: Text(
                                    "TO",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 3,
                                    top: MediaQuery.of(context).size.height * listViewTitleBarTextSize / 1.8,
                                  ),
                                  width: 100,
                                  height: 18,
                                  child: TextField(
                                    onChanged:(val) {
                                      print(val);
                                    },
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    decoration: InputDecoration(
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                        hintText: 'Enter Station..'
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
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
                        height: MediaQuery.of(context).size.width * (listViewTitleBarHeight) * 0.6,
                        width: MediaQuery.of(context).size.width * (listViewTitleBarHeight) * 0.6,
                        margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewTitleBarHeight) * 0.2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewTitleBarHeight) * 0.6)),
                          color: Color(0xffe84545),
                        ),
                        child: Center(
                            child: currentStop.stopLetter == null || currentStop.stopLetter.toString().contains("->") || currentStop.stopLetter == "Stop" ? Icon(Icons.train, color: Colors.white,) : Text(currentStop.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:  MediaQuery.of(context).size.width * (listViewTitleBarHeight) * 0.6 * 0.4,),)
                        ),
                      ) : Container(),
                    ],
                  ),
                ),

                currentStop == null ? Container(
                  height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (listViewTitleBarHeight) + 15),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      loading = true;
                      this.widget.reloadPage();
                      readFavourites().then((ret) async {
                        currentFavouriteStops = await fetchFavouriteStops();
                        loading = false;
                        this.widget.reloadPage();
                      });
                    },
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: currentFavouriteStops != null ? () {
                          List returnNearbyStops = currentFavouriteStops.map((item) => Container(
                            height: MediaQuery.of(context).size.width * listViewItemHeight,
                            child: FlatButton(
                              onPressed: () async {
                                currentStop = item;
                                currentArrivalTimes = await fetchArrivalTimes();
                                currentArrivalTimes.sort((a, b) {
                                  return a.timeToStation.compareTo(b.timeToStation);
                                });
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
                                    height: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6,
                                    width: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6,
                                    margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6)),
                                      color: Color(0xffe84545),
                                    ),
                                    child: Center(
                                      child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop" ? Icon(Icons.train, color: Colors.white,) : Text(item.stopLetter.split("Stop ")[1], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                    ),
                                  ) : Container(),
                                ],
                              ),
                            ),
                          )).toList();
                          returnNearbyStops.add(Container(
                            height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (listViewTitleBarHeight) + 15),
                          ));
                          return returnNearbyStops;
                        }() : [Container()],
                      ),
                    ),
                  ),
                ) : Container(
                    height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (listViewTitleBarHeight) + 15),
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
                                    height: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6,
                                    width: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6 * 2,
                                    margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (listViewItemHeight) * 0.6)),
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
                                    height: MediaQuery.of(context).size.width * (listViewItemHeight),
                                    margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.2),
                                    child: Center(
                                      child: Text(
                                          (item.timeToStation / 60).ceil().toString() + ((item.timeToStation / 60).ceil() > 0 ? " mins" : "min"),
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: MediaQuery.of(context).size.width * (listViewItemHeight) * 0.5,
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
                              height: MediaQuery.of(context).size.height - (MediaQuery.of(context).size.height * (listViewTitleBarHeight) + 15),
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'globals.dart';
import 'global_class.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

bool loading = false;

bool back(setState) {
  if (currentStopFavourites != null) {
    currentStopFavourites = null;
    if (favouritesChanged) {
      favouritesChanged = false;
      readFavourites().then((ret) async {
        fetchFavouriteStops(setState);
      });
    }
    setState(() {});
  }

  if (currentStopFavourites != null) {
    currentStopFavourites = null;
    setState(() {});
  }
  return false;
}

List<Widget> buildFavourites(context, setState) {
  List returnNearbyStops = currentFavouriteStops
      .map((item) => Container(
            height: MediaQuery.of(context).size.width * LIST_VIEW_ITEM_HEIGHT,
            child: FlatButton(
              onPressed: () async {
                currentStopFavourites = item;
                loadArrivalTimes(setState);
              },
              color: Color(0xffe8e8e8),
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE),
                        child: Text(
                          item.commonName,
                          style: TextStyle(
                            color: Color(0xff2b2e4a),
                            fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE,
                          ),
                        ),
                      ),
                      item != null
                          ? Container(
                              padding: EdgeInsets.only(
                                  left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE,
                                  top: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE / 4),
                              child: Text(
                                "ID " + item.naptanId + " | " + item.lines.join(" • "),
                                style: TextStyle(
                                  color: Color(0xff53354a),
                                  fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE / 2,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                    ),
                  ),
                  item != null
                      ? Container(
                          height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6,
                          width: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6,
                          margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6)),
                            color: Color(0xffe84545),
                          ),
                          child: Center(
                            child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop"
                                ? Icon(
                                    Icons.train,
                                    color: Colors.white,
                                  )
                                : Text(
                                    item.stopLetter.split("Stop ")[1],
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ))
      .toList();
  returnNearbyStops.add(Container(
    height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) -
        ((MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) + 15),
  ));
  return returnNearbyStops;
}

Future<void> getCurrentLocation() async {
  currentLocation = await location.getLocation();
  return;
}

Future<void> loadArrivalTimes(setState) async {
  setState(() {
    loading = true;
  });
  String id = currentStopFavourites.naptanId;
  String urlString = "https://api.tfl.gov.uk/StopPoint/$id/Arrivals";

  var uri = Uri.parse(urlString);

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    List arrivalTimes = jsonDecode(response.body);
    currentArrivalTimesFavourites = arrivalTimes
        .map((json) => ArrivalTime(
              json['vehicleId'],
              json['lineName'],
              json["destinationName"],
              json['timeToStation'],
            ))
        .toList();
    currentArrivalTimesFavourites.sort((a, b) {
      return a.timeToStation.compareTo(b.timeToStation);
    });
  }
  setState(() {
    loading = false;
  });
  return;
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  print(lat1);
  print(lon1);
  print(lat2);
  print(lon2);
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Future<List> fetchFavouriteStops(setState) async {
  setState(() {
    loading = true;
  });
  List favouriteStops = [];
  for (MapEntry<String, dynamic> item in currentFavourites.entries) {
    Stop favouriteStop = await fetchFavouriteStop(item);
    favouriteStops.add(favouriteStop);
  }
  print(favouriteStops.length);
  //await getCurrentLocation();
  if (favouriteStops.length > 0) {
    favouriteStops.sort((a, b) {
      return calculateDistance(currentLocation.latitude, currentLocation.longitude, a.lat, a.lon).compareTo(calculateDistance(currentLocation.latitude, currentLocation.longitude, b.lat, b.lon));
    });
  }
  currentFavouriteStops = favouriteStops;
  setState(() {
    loading = false;
  });
}

Future<Stop> fetchFavouriteStop(MapEntry<String, dynamic> stop) async {
  String naptanId = stop.key;
  Map<String, dynamic> values = stop.value;
  String stopLetter = values["stopLetter"];
  String commonName = values["commonName"];
  double distance = values["distance"];
  double lat = values["lat"];
  double lon = values["lon"];
  List<dynamic> lines = values["lines"];

  return new Stop(stopLetter, commonName, naptanId, distance, lat, lon, lines);
}

class ScreenFavourites extends StatefulWidget {
  @override
  _ScreenFavourites createState() => _ScreenFavourites();
}

class _ScreenFavourites extends State<ScreenFavourites> {
  @override
  void initState() {
    super.initState();
    print("test");
    if (favouritesChanged) {
      readFavourites().then((ret) async {
        fetchFavouriteStops(setState);
      });
    }
  }

  void reloadPage() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListViewPage(reloadPage);
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
    return Container(
        color: Color(0xffe8e8e8),
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(milliseconds: ANIMATION_DURATION),
              curve: Curves.easeOut,
              color: Color(0xff903749),
              height: MediaQuery.of(context).size.width * LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES,
              child: Row(
                children: <Widget>[
                  IconButton(
                      icon: Icon(
                        currentStopFavourites != null ? Icons.arrow_back : null,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        back(setState);
                      }),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(
                                left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3,
                                right: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3),
                            child: Text(
                              currentStopFavourites != null
                                  ? currentStopFavourites.commonName.length > 17
                                      ? currentStopFavourites.commonName.replaceRange(18, currentStopFavourites.commonName.length, "...")
                                      : currentStopFavourites.commonName
                                  : "Favourites",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                              ),
                            ),
                          ),
                          currentStopFavourites != null
                              ? GestureDetector(
                                  onTap: () {
                                    if (currentFavourites.containsKey(currentStopFavourites.naptanId)) {
                                      currentFavourites.removeWhere((key, value) => key == currentStopFavourites.naptanId);
                                    } else {
                                      currentFavourites[currentStopFavourites.naptanId] = {
                                        "stopLetter": currentStopFavourites.stopLetter,
                                        "distance": currentStopFavourites.distance,
                                        "lat": currentStopFavourites.lat,
                                        "lon:": currentStopFavourites.lon,
                                        "lines": currentStopFavourites.lines,
                                      };
                                    }
                                    writeFavourites();
                                    favouritesChanged = true;
                                    back(setState);
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: 3, right: 3, bottom: 3, top: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color(0xff2b2e4a),
                                    ),
                                    child: Icon(
                                      currentFavourites.containsKey(currentStopFavourites.naptanId) ? Icons.favorite : Icons.favorite_border,
                                      color: Color(0xffe84545),
                                    ),
                                  ))
                              : Container(),
                        ],
                      ),
                      currentStopFavourites != null
                          ? Container(
                              padding: EdgeInsets.only(
                                  left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3,
                                  top: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 4),
                              child: Text(
                                "ID " + currentStopFavourites.naptanId + " | " + currentStopFavourites.lines.join(" • "),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 2,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                    ),
                  ),
                  currentStopFavourites != null
                      ? Container(
                          height: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) * 0.6,
                          width: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) * 0.6,
                          margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) * 0.2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) * 0.6)),
                            color: Color(0xffe84545),
                          ),
                          child: Center(
                              child: currentStopFavourites.stopLetter == null || currentStopFavourites.stopLetter.toString().contains("->") || currentStopFavourites.stopLetter == "Stop"
                                  ? Icon(
                                      Icons.train,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      currentStopFavourites.stopLetter.split("Stop ")[1],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) * 0.6 * 0.4,
                                      ),
                                    )),
                        )
                      : Container(),
                ],
              ),
            ),
            loading
                ? Expanded(
                    child: Center(
                    child: CircularProgressIndicator(),
                  ))
                : currentStopFavourites == null
                    ? Container(
                        height: MediaQuery.of(context).size.height - BOTTOM_NAVIGATION_BAR_HEIGHT - (MediaQuery.of(context).size.height * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES)),
                        child: RefreshIndicator(
                          onRefresh: () async {
                            this.widget.reloadPage();
                            readFavourites().then((ret) async {
                              fetchFavouriteStops(setState);
                            });
                          },
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: currentFavouriteStops != null ? buildFavourites(context, setState) : [Container()],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: MediaQuery.of(context).size.height - BOTTOM_NAVIGATION_BAR_HEIGHT - (MediaQuery.of(context).size.height * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES)),
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await loadArrivalTimes(setState);
                          },
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: currentArrivalTimesFavourites != null
                                  ? () {
                                      List returnArrivalTimes = currentArrivalTimesFavourites
                                          .map((item) => AnimatedContainer(
                                                duration: Duration(milliseconds: ANIMATION_DURATION),
                                                curve: Curves.easeOut,
                                                color: Color(0xffe8e8e8),
                                                height: MediaQuery.of(context).size.width * LIST_VIEW_ITEM_HEIGHT,
                                                child: Row(
                                                  children: <Widget>[
                                                    item.lineName != null
                                                        ? Container(
                                                            height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6,
                                                            width: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6 * 2,
                                                            margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.2),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.6)),
                                                              color: Color(0xffe84545),
                                                            ),
                                                            child: Center(
                                                              child: Text(item.lineName,
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                  )),
                                                            ),
                                                          )
                                                        : Container(),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.only(left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE),
                                                          child: Text(
                                                            item.destinationName != null
                                                                ? item.destinationName.length > 20
                                                                    ? item.destinationName.replaceRange(21, item.destinationName.length, "...")
                                                                    : item.destinationName
                                                                : "",
                                                            style: TextStyle(
                                                              color: Color(0xff2b2e4a),
                                                              fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE,
                                                            ),
                                                          ),
                                                        ),
                                                        item.vehicleId != null
                                                            ? Container(
                                                                padding: EdgeInsets.only(
                                                                    left: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE,
                                                                    top: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE / 4),
                                                                child: Text(
                                                                  item.vehicleId,
                                                                  style: TextStyle(
                                                                    color: Color(0xff53354a),
                                                                    fontSize: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * LIST_VIEW_ITEM_TEXT_SIZE / 2,
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        width: 100.0,
                                                        height: 100.0,
                                                      ),
                                                    ),
                                                    item.timeToStation != null
                                                        ? Container(
                                                            height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT),
                                                            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.2),
                                                            child: Center(
                                                              child: Text((item.timeToStation / 60).ceil().toString() + ((item.timeToStation / 60).ceil() > 0 ? " mins" : "min"),
                                                                  style: TextStyle(
                                                                    color: Colors.red,
                                                                    fontSize: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT) * 0.5,
                                                                    fontWeight: FontWeight.bold,
                                                                  )),
                                                            ),
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                              ))
                                          .toList();
                                      returnArrivalTimes.add(AnimatedContainer(
                                        duration: Duration(milliseconds: ANIMATION_DURATION),
                                        curve: Curves.easeOut,
                                        height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) -
                                            ((MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * (LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES) + 15),
                                      ));
                                      return returnArrivalTimes;
                                    }()
                                  : [Container()],
                            ),
                          ),
                        )),
          ],
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:onthego/ScreenNearby.dart';

import 'globals.dart';
import 'global_class.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

readFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  String favouriteStops = prefs.getString(FAVOURITES_ID_LIST_KEY) ?? "{}";
  currentFavourites = json.decode(favouriteStops);
  //final value = prefs.getStringList(FAVOURITES_ID_LIST_KEY) ?? [];
  //currentFavourites = value;
}

writeFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(FAVOURITES_ID_LIST_KEY, json.encode(currentFavourites));
  favouritesChanged = true;
}

List<Widget> buildArrivalTimes(context, idx) {
  List currentArrivalTimes = [currentArrivalTimesNearby, currentArrivalTimesFavourites][idx];
  if (currentArrivalTimes == null) {
    return [Container()];
  }
  List<Widget> arrivalTimes = currentArrivalTimes
      .map((item) => AnimatedContainer(
            duration: Duration(milliseconds: ANIMATION_DURATION),
            curve: Curves.easeOut,
            color: Color(0xffe8e8e8),
            height: MediaQuery.of(context).size.width * LIST_VIEW_ITEM_HEIGHT,
            child: Row(
              children: <Widget>[
                item.lineName != null
                    ? Container(
                        height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.6,
                        padding: EdgeInsets.all(4),
                        margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.6)),
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
                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE),
                      child: Text(
                        item.destinationName != null
                            ? item.destinationName.length > 20
                                ? item.destinationName.replaceRange(21, item.destinationName.length, "...")
                                : item.destinationName
                            : "",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE,
                        ),
                      ),
                    ),
                    item.vehicleId != null
                        ? Container(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE, top: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 4),
                            child: Text(
                              item.vehicleId,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 2,
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
                        height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT),
                        margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.2),
                        child: Center(
                          child: Text((item.timeToStation / 60).ceil().toString() + ((item.timeToStation / 60).ceil() > 0 ? " mins" : "min"),
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.5,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      )
                    : Container(),
              ],
            ),
          ))
      .toList();
  return arrivalTimes;
}

Future<void> getCurrentLocation() async {
  currentLocation = await location.getLocation();
  return;
}

Future<void> loadNearbyStops(setState) async {
  mapHeight = INITIAL_MAP_HEIGHT;
  setState(() {
    loadingNearby = true;
  });
  await getCurrentLocation();
  List<String> busTrain = ["NaptanBusCoachStation,NaptanPrivateBusCoachTram,NaptanPublicBusCoachTram", "NaptanRailStation,NaptanMetroStation"];
  String stopTypes = busTrain[selectedToggle];
  String latitude = currentLocation.latitude.toString();
  String longitude = currentLocation.longitude.toString();
  mapController.onReady.then((value) {
    mapController.move(LatLng(currentLocation.latitude, currentLocation.longitude), mapController.zoom);
  });
  String urlString = "https://api.tfl.gov.uk/StopPoint?stoptypes=$stopTypes&radius=$SEARCH_RADIUS&lat=$latitude&lon=$longitude";

  var uri = Uri.parse(urlString);

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    List stopPoints = jsonDecode(response.body)["stopPoints"];
    currentNearbyStops = [];
    for (Map stopPoint in stopPoints) {
      List linesFiltered = stopPoint['lines'].map((item) => item["name"]).toList();
      if (linesFiltered.length > 0) {
        currentNearbyStops.add(Stop(stopPoint['indicator'], stopPoint['commonName'], stopPoint["naptanId"], stopPoint['distance'], stopPoint['lat'], stopPoint['lon'], linesFiltered));
      }
    }
  }
  setState(() {
    loadingNearby = false;
  });
  return;
}

Future<void> loadArrivalTimesNearby(setState) async {
  mapHeight = INITIAL_MAP_HEIGHT;
  setState(() {
    loadingNearby = true;
  });
  mapController.onReady.then((value) {
    mapController.move(LatLng(currentStopNearby.lat, currentStopNearby.lon), mapController.zoom);
  });
  String id = currentStopNearby.naptanId;
  List<String> busTrain = ["bus,replacement-bus,coach", "tube,dlr,national-rail,overground,tflrail,"];
  String modes = busTrain[selectedToggle];

  String urlString = "https://api.tfl.gov.uk/StopPoint/$id/Arrivals?mode=$modes";

  var uri = Uri.parse(urlString);

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    List arrivalTimes = jsonDecode(response.body);
    currentArrivalTimesNearby = arrivalTimes
        .map((json) => ArrivalTime(
              json['vehicleId'],
              json['lineName'],
              json["destinationName"],
              json['timeToStation'],
            ))
        .toList();
  }
  setState(() {
    loadingNearby = false;
  });
  return;
}

Future<void> loadArrivalTimesFavourites(setState) async {
  mapHeight = INITIAL_MAP_HEIGHT;
  setState(() {
    loadingFavourites = true;
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
    loadingFavourites = false;
  });
  return;
}

Future<void> loadClosestStopArrivalTimes(setState) async {
  setState(() {
    loadingFavourites = true;
    loadingNearby = true;
  });
  await loadNearbyStops(setState);
  currentStopNearby = currentNearbyStops[0];
  await loadArrivalTimesNearby(setState);
  setState(() {
    loadingFavourites = false;
    loadingNearby = false;
  });
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Future<void> fetchFavouriteStops(setState) async {
  mapHeight = INITIAL_MAP_HEIGHT;
  setState(() {
    loadingFavourites = true;
  });
  List favouriteStops = [];
  for (MapEntry<String, dynamic> item in currentFavourites.entries) {
    Stop favouriteStop = await fetchFavouriteStop(item);
    favouriteStops.add(favouriteStop);
  }
  if (currentLocation == null) {
    await getCurrentLocation();
  }
  if (favouriteStops.length > 1) {
    favouriteStops.sort((a, b) {
      return calculateDistance(currentLocation.latitude, currentLocation.longitude, a.lat, a.lon).compareTo(calculateDistance(currentLocation.latitude, currentLocation.longitude, b.lat, b.lon));
    });
  }
  currentFavouriteStops = favouriteStops;
  setState(() {
    loadingFavourites = false;
  });
  return;
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

void searchForStops(setState, text) async {
  setState(() {
    loadingNearby = true;
  });
  mapHeight = INITIAL_MAP_HEIGHT;
  currentSearchString = text;
  currentStopNearby = null;
  await getCurrentLocation();
  List<String> busTrain = ["coach,bus", "dlr,national-rail,overground,tflrail,tube"];
  String modes = busTrain[selectedToggle];
  String urlString = "https://api.tfl.gov.uk/StopPoint/Search/?query=$text&modes=$modes";
  final response = await http.get(Uri.parse(urlString));
  currentNearbyStops = [];
  if (response.statusCode == 200) {
    List matches = jsonDecode(response.body)["matches"];
    for (Map match in matches) {
      String naptanId = match['id'];
      String stopUrlString = "https://api.tfl.gov.uk/StopPoint/$naptanId";
      final response = await http.get(Uri.parse(stopUrlString));
      if (response.statusCode == 200) {
        Map stopPoint = Map.from(jsonDecode(response.body));
        List linesFiltered = stopPoint['lines'].map((item) => item["name"]).toList();
        if (linesFiltered.length > 0) {
          currentNearbyStops.add(Stop(stopPoint['indicator'], stopPoint['commonName'], stopPoint["naptanId"], stopPoint['distance'], stopPoint['lat'], stopPoint['lon'], linesFiltered));
        }
      }
    }
  }

  setState(() {
    loadingNearby = false;
  });
  return;
}

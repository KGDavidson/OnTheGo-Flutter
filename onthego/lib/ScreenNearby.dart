import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';

import 'globals.dart';
import 'global_class.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

MapController mapController = MapController();

int selectedToggle = 0;
double lastPosition = 0;
double mapHeight = INITIAL_MAP_HEIGHT;

bool pullTabIcon = true;
bool loading = false;

bool back(setState) {
  if (currentStopNearby != null) {
    currentStopNearby = null;
    setState(() {});
  }
  return false;
}

List<Widget> buildArrivalTimes(context) {
    if (currentArrivalTimesNearby == null) {
      return [Container()];
    }
    List<Widget> arrivalTimes = currentArrivalTimesNearby.map((item) => AnimatedContainer(
          duration: Duration(
              milliseconds:
              ANIMATION_DURATION),
          curve: Curves.easeOut,
          color:
          Color(0xffe8e8e8),
          height: MediaQuery.of(
              context)
              .size
              .width *
              LIST_VIEW_ITEM_HEIGHT,
          child: Row(
            children: <Widget>[
              item.lineName !=
                  null
                  ? Container(
                height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.6,
                width: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.6 * 2,
                margin: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width *
                        (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) *
                        0.2),
                decoration:
                BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width *
                      (LIST_VIEW_ITEM_HEIGHT -
                          PULL_TAB_HEIGHT) *
                      0.6)),
                  color: Color(
                      0xffe84545),
                ),
                child:
                Center(
                  child: Text(
                      item
                          .lineName,
                      style:
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              )
                  : Container(),
              Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height *
                            LIST_VIEW_ITEM_TEXT_SIZE),
                    child: Text(
                      item.destinationName !=
                          null
                          ? item.destinationName.length > 20
                          ? item.destinationName.replaceRange(21, item.destinationName.length, "...")
                          : item.destinationName
                          : "",
                      style:
                      TextStyle(
                        color: Color(
                            0xff2b2e4a),
                        fontSize:
                        MediaQuery.of(context).size.height *
                            LIST_VIEW_ITEM_TEXT_SIZE,
                      ),
                    ),
                  ),
                  item.vehicleId !=
                      null
                      ? Container(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE,
                        top: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 4),
                    child:
                    Text(
                      item.vehicleId,
                      style:
                      TextStyle(
                        color: Color(0xff53354a),
                        fontSize: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 2,
                      ),
                    ),
                  )
                      : Container(),
                ],
              ),
              Expanded(
                flex: 1,
                child:
                Container(
                  width: 100.0,
                  height: 100.0,
                ),
              ),
              item.timeToStation !=
                  null
                  ? Container(
                height: MediaQuery.of(context)
                    .size
                    .width *
                    (LIST_VIEW_ITEM_HEIGHT -
                        PULL_TAB_HEIGHT),
                margin: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width *
                        (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) *
                        0.2),
                child:
                Center(
                  child: Text(
                      (item.timeToStation / 60).ceil().toString() +
                          ((item.timeToStation / 60).ceil() > 0 ? " mins" : "min"),
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
        )).toList();
    return arrivalTimes;
}

List<Widget> buildNearbyStops(context, setState) {
  if (currentNearbyStops == null){
    return [Container()];
  }
  List nearbyStops = currentNearbyStops.map((item) => Container(
    height: MediaQuery.of(
        context)
        .size
        .width *
        LIST_VIEW_ITEM_HEIGHT,
    child: TextButton(
      onPressed: () async {
        currentStopNearby = item;
        await loadArrivalTimes(setState);
      },
      style: TextButton.styleFrom(
        backgroundColor: Color(0xffe8e8e8),
        padding: EdgeInsets.all(5)
      ),
      child: Row(
        children: <Widget>[
          Column(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Container(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context)
                        .size
                        .height *
                        LIST_VIEW_ITEM_TEXT_SIZE),
                child: Text(
                  item.commonName,
                  style:
                  TextStyle(
                    color: Color(
                        0xff2b2e4a),
                    fontSize: MediaQuery.of(context)
                        .size
                        .height *
                        LIST_VIEW_ITEM_TEXT_SIZE,
                  ),
                ),
              ),
              item != null
                  ? Container(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.height *
                        LIST_VIEW_ITEM_TEXT_SIZE,
                    top: MediaQuery.of(context).size.height *
                        LIST_VIEW_ITEM_TEXT_SIZE /
                        4),
                child:
                Text(
                  "ID " +
                      item.naptanId +
                      " | " +
                      item.lines.join(" • "),
                  style:
                  TextStyle(
                    color:
                    Color(0xff53354a),
                    fontSize: MediaQuery.of(context).size.height *
                        LIST_VIEW_ITEM_TEXT_SIZE /
                        1.7,
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
            height: MediaQuery.of(context)
                .size
                .width *
                (LIST_VIEW_ITEM_HEIGHT -
                    PULL_TAB_HEIGHT) *
                0.8,
            width: MediaQuery.of(context)
                .size
                .width *
                (LIST_VIEW_ITEM_HEIGHT -
                    PULL_TAB_HEIGHT) *
                0.8,
            margin: EdgeInsets.only(
                right: MediaQuery.of(context).size.width *
                    (LIST_VIEW_ITEM_HEIGHT -
                        PULL_TAB_HEIGHT) *
                    0.2),
            decoration:
            BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context)
                  .size
                  .width *
                  (LIST_VIEW_ITEM_HEIGHT -
                      PULL_TAB_HEIGHT) *
                  0.6)),
              color: Color(
                  0xffe84545),
            ),
            child:
            Center(
              child: item.stopLetter == null ||
                  item.stopLetter.toString().contains("->") ||
                  item.stopLetter == "Stop"
                  ? selectedToggle == 0
                  ? Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              )
                  : Icon(
                Icons.directions_train,
                color: Colors.white,
                size: 20,
              )
                  : Text(
                item.stopLetter.split("Stop ")[1],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          )
              : Container(),
        ],
      ),
    ),
  ))
      .toList();
  return nearbyStops;
}

Future<void> getCurrentLocation() async {
  currentLocation = await location.getLocation();
  return;
}

Future<void> loadNearbyStops(setState) async {
  setState(() {
    loading = true;
  });
  await getCurrentLocation();
  List<String> busTrain = ["NaptanBusCoachStation,NaptanPrivateBusCoachTram,NaptanPublicBusCoachTram", "NaptanRailStation,NaptanMetroStation"];
  String stopTypes = busTrain[selectedToggle];
  String latitude = currentLocation.latitude.toString();
  String longitude = currentLocation.longitude.toString();
  mapController.move(LatLng(currentLocation.latitude, currentLocation.longitude), mapController.zoom);
  String urlString = "https://api.tfl.gov.uk/StopPoint?stoptypes=$stopTypes&radius=1000&lat=$latitude&lon=$longitude";

  var uri = Uri.parse(urlString);

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    List stopPoints = jsonDecode(response.body)["stopPoints"];
    currentNearbyStops = stopPoints.map((stop) => Stop.fromJson(stop)).toList();
  }
  setState(() {
    loading = false;
  });
  return;
}

Future<void> loadArrivalTimes(setState) async {
  setState(() {
    loading = true;
  });
  mapController.move(LatLng(currentStopNearby.lat, currentStopNearby.lon), mapController.zoom);
  String id = currentStopNearby.naptanId;
  String urlString = "https://api.tfl.gov.uk/StopPoint/$id/Arrivals";

  var uri = Uri.parse(urlString);

  final response = await http.get(uri);
  if (response.statusCode == 200) {
    List arrivalTimes = jsonDecode(response.body);
    currentArrivalTimesNearby = arrivalTimes.map((arrivalTime) => ArrivalTime.fromJson(arrivalTime)).toList();
  }
  setState(() {
    loading = false;
  });
  return;
}

Future<void> loadClosestStopArrivalTimes(setState) async {
  setState(() {
    loading = true;
  });
  await loadNearbyStops(setState);
  currentStopNearby = currentNearbyStops[0];
  await loadArrivalTimes(setState);
  setState(() {
    loading = false;
  });
}

class ScreenNearby extends StatefulWidget {
  @override
  _ScreenNearby createState() => _ScreenNearby();
}

class _ScreenNearby extends State<ScreenNearby>{

  @override
  void initState() {
    super.initState();
    if (firstOpen) {
      firstOpen = false;
      loadClosestStopArrivalTimes(setState);
    } else {
      if (favouritesChanged) {
        favouritesChanged = false;
        if (currentStopNearby == null) {
          loadNearbyStops(setState);
        } else {
          loadArrivalTimes(setState);
        }
      }
    }
    if (currentLocation != null) {
      mapController = MapController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return back(setState);
      },
      child: Stack(
        children: <Widget>[
          ListViewPage(),
          MapView(setState),
          TopToggleBar(setState),
        ],
      ),
    );
  }
}

class TopToggleBar extends StatefulWidget {
  Function setStateParent;

  TopToggleBar(this.setStateParent);

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
      height: MediaQuery.of(context).size.height * TOGGLE_BAR_HEIGHT,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Material(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                    MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
                bottomLeft: Radius.circular(
                    MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
            color: selectedToggle == 0 ? Color(0xffe84545) : Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                      MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
                  bottomLeft: Radius.circular(
                      MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
              onTap: () async {
                selectedToggle = 0;
                await loadClosestStopArrivalTimes(this.widget.setStateParent);
              },
              child: AnimatedContainer(
                  height: MediaQuery.of(context).size.height * TOGGLE_HEIGHT,
                  width: (MediaQuery.of(context).size.width -
                      (MediaQuery.of(context).size.height *
                          (TOGGLE_BAR_HEIGHT - TOGGLE_HEIGHT) *
                          3 /
                          2)) *
                      TOGGLE_WIDTH,
                  decoration: BoxDecoration(
                    color: selectedToggle == 0 ? Color(0xffe84545) : null,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
                        bottomLeft: Radius.circular(
                            MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                    border: Border.all(color: Color(0xffe84545), width: 3),
                  ),
                  duration: Duration(milliseconds: ANIMATION_DURATION),
                  curve: Curves.fastOutSlowIn,
                  child: Center(
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                    ),
                  )),
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(
              MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
              bottomRight: Radius.circular(
              MediaQuery.of(context).size.height * TOGGLE_HEIGHT)
            ),
            color: selectedToggle == 1 ? Color(0xffe84545) : Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                      MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
                  bottomRight: Radius.circular(
                      MediaQuery.of(context).size.height * TOGGLE_HEIGHT)
              ),
              onTap: () async {
                selectedToggle = 1;
                await loadClosestStopArrivalTimes(this.widget.setStateParent);
              },
              child: AnimatedContainer(
                  duration: Duration(milliseconds: ANIMATION_DURATION),
                  curve: Curves.easeInOut,
                  height: MediaQuery.of(context).size.height * TOGGLE_HEIGHT,
                  width: (MediaQuery.of(context).size.width -
                      (MediaQuery.of(context).size.height *
                          (TOGGLE_BAR_HEIGHT - TOGGLE_HEIGHT) *
                          3 /
                          2)) *
                      TOGGLE_WIDTH,
                  decoration: BoxDecoration(
                    color: selectedToggle == 1 ? Color(0xffe84545) : null,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                            MediaQuery.of(context).size.height * TOGGLE_HEIGHT),
                        bottomRight: Radius.circular(
                            MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
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
          )
        ],
      ),
    );
  }
}

class MapView extends StatefulWidget {
  Function setStateParent;

  MapView(this.setStateParent);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedContainer(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * TOGGLE_BAR_HEIGHT),
          duration: Duration(milliseconds: ANIMATION_DURATION),
          curve: Curves.easeOut,
          height: mapHeight,
          child: FlutterMap(
            mapController: mapController,
            options: new MapOptions(
              center: currentLocation == null ? LatLng(51.507351, -0.127758) : LatLng(currentLocation.latitude, currentLocation.longitude),
              zoom: 13.0,
              maxZoom: 17.5,
            ),
            layers: [
              new TileLayerOptions(
                //https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png
                //https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png
                urlTemplate:
                "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c', 'd'],
              ),
              new MarkerLayerOptions(
                markers: currentNearbyStops != null
                    ? () {
                  List<Marker> returnList = currentNearbyStops
                      .map(
                        (item) => Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(item.lat, item.lon),
                      builder: (ctx) => GestureDetector(
                        child: Icon(
                          Icons.location_pin,
                          size: currentStopNearby == item ? 38.5 : 30.5,
                          color: Color(currentStopNearby == item
                              ? 0xffe84545
                              : 0x802b2e4a),
                        ),
                        onTap: () async {
                          currentStopNearby = item;
                          loadArrivalTimes(this.widget.setStateParent);
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
                      builder: (ctx) => Icon(
                        Icons.my_location,
                        color: Colors.black,
                        size: 30,
                      ),
                    ));
                  }
                  return returnList;
                }()
                    : [],
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
            if (mapHeight < INITIAL_MAP_HEIGHT) {
              mapHeight = INITIAL_MAP_HEIGHT;
            }
            if (mapHeight > MAX_MAP_HEIGHT) {
              mapHeight = MAX_MAP_HEIGHT;
            }
            if ((mapHeight - INITIAL_MAP_HEIGHT) / (MAX_MAP_HEIGHT - INITIAL_MAP_HEIGHT) > 0.5){
              pullTabIcon = false;
            } else {
              pullTabIcon = true;
            }
            setState(() {});
          },
          onVerticalDragEnd: (details) {
            if (MAX_MAP_HEIGHT - mapHeight < 10) {
              mapHeight = MAX_MAP_HEIGHT;
              pullTabIcon = false;
            } else {
              if (details.primaryVelocity > 0) {
                mapHeight = MAX_MAP_HEIGHT;
                pullTabIcon = false;
              } else {
                mapHeight = INITIAL_MAP_HEIGHT;
                pullTabIcon = true;
              }
            }
            setState(() {});
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * PULL_TAB_HEIGHT,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(
                      MediaQuery.of(context).size.height * PULL_TAB_HEIGHT),
                  bottomLeft: Radius.circular(
                      MediaQuery.of(context).size.height * PULL_TAB_HEIGHT)),
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
              child: Icon(
                pullTabIcon ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ListViewPage extends StatefulWidget {
  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(
          top: (MediaQuery.of(context).size.height * (TOGGLE_BAR_HEIGHT)) + INITIAL_MAP_HEIGHT,
        ),
        color: Color(0xffe8e8e8),
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(milliseconds: ANIMATION_DURATION),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height *
                      (PULL_TAB_HEIGHT)),
              color: Color(0xff903749),
              height: MediaQuery.of(context).size.width *
                  LIST_VIEW_TITLE_BAR_HEIGHT,
              child: Row(
                children: <Widget>[
                  IconButton(
                      icon: Icon(
                        currentStopNearby != null ? Icons.arrow_back : null,
                        color: Colors.white,
                      ),
                      onPressed: () {
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
                                left: MediaQuery.of(context).size.height *
                                    LIST_VIEW_TITLE_BAR_TEXT_SIZE /
                                    3,
                                right:
                                MediaQuery.of(context).size.height *
                                    LIST_VIEW_TITLE_BAR_TEXT_SIZE /
                                    3),
                            child: loading ? Text(
                              "Nearby Stops",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                MediaQuery.of(context).size.height *
                                    LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                              ),
                            ) : Text(
                              currentStopNearby != null
                                  ? currentStopNearby.commonName.length > 17
                                  ? currentStopNearby.commonName
                                  .replaceRange(
                                  18,
                                  currentStopNearby
                                      .commonName.length,
                                  "...")
                                  : currentStopNearby.commonName
                                  : "Nearby Stops",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                MediaQuery.of(context).size.height *
                                    LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                              ),
                            ),
                          ),
                          currentStopNearby != null
                              ? GestureDetector(
                              onTap: () {
                                if (currentFavourites.contains(currentStopNearby.naptanId)) {
                                  currentFavourites.removeWhere(
                                          (item) =>
                                      item ==
                                          currentStopNearby.naptanId);
                                  writeFavourites();
                                  setState(() {});
                                } else {
                                  currentFavourites
                                      .add(currentStopNearby.naptanId);
                                  writeFavourites();
                                  setState(() {});
                                }
                                favouritesChanged = true;
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 3,
                                    right: 3,
                                    bottom: 3,
                                    top: 5),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(100),
                                  color: Color(0xff2b2e4a),
                                ),
                                child: Icon(
                                  currentFavourites.contains(currentStopNearby.naptanId.toString()) ? Icons.favorite : Icons.favorite_border,
                                  color: Color(0xffe84545),
                                ),
                              ))
                              : Container(),
                        ],
                      ),
                      currentStopNearby != null
                          ? Container(
                        padding: EdgeInsets.only(
                            left:
                            MediaQuery.of(context).size.height *
                                LIST_VIEW_TITLE_BAR_TEXT_SIZE /
                                3,
                            top:
                            MediaQuery.of(context).size.height *
                                LIST_VIEW_TITLE_BAR_TEXT_SIZE /
                                4),
                        child: Text(
                          "ID " +
                              currentStopNearby.naptanId +
                              " | " +
                              currentStopNearby.lines.join(" • "),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize:
                            MediaQuery.of(context).size.height *
                                LIST_VIEW_TITLE_BAR_TEXT_SIZE /
                                2,
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
                  currentStopNearby != null
                      ? Container(
                    height: MediaQuery.of(context).size.width *
                        (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) *
                        0.6,
                    width: MediaQuery.of(context).size.width *
                        (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) *
                        0.6,
                    margin: EdgeInsets.only(
                        right: MediaQuery.of(context).size.width *
                            (LIST_VIEW_TITLE_BAR_HEIGHT -
                                PULL_TAB_HEIGHT) *
                            0.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                          Radius.circular(
                              MediaQuery.of(context).size.width *
                                  (LIST_VIEW_TITLE_BAR_HEIGHT -
                                      PULL_TAB_HEIGHT) *
                                  0.6)),
                      color: Color(0xffe84545),
                    ),
                    child: Center(
                        child: GestureDetector(
                            onTap: () {
                              /*mapController.move(
                                  LatLng(currentStop.lat,
                                      currentStop.lon),
                                  15);
                              setState(() {});*/
                            },
                            child: currentStopNearby.stopLetter == null ||
                                currentStopNearby.stopLetter
                                    .toString()
                                    .contains("->") ||
                                currentStopNearby.stopLetter == "Stop"
                                ? selectedToggle == 0
                                ? Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                            )
                                : Icon(
                              Icons.directions_train,
                              color: Colors.white,
                            )
                                : Text(
                              currentStopNearby.stopLetter
                                  .split("Stop ")[1],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: MediaQuery.of(
                                    context)
                                    .size
                                    .width *
                                    (LIST_VIEW_TITLE_BAR_HEIGHT -
                                        PULL_TAB_HEIGHT) *
                                    0.6 *
                                    0.4,
                              ),
                            ))),
                  )
                      : Container(),
                ],
              ),
            ),
            loading ? Expanded(
                child: Center(
                child: CircularProgressIndicator()
            )
            ) : Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (currentStopNearby == null) {
                    loadNearbyStops(setState);
                  } else {
                    loadArrivalTimes(setState);
                  }
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: currentStopNearby == null ? buildNearbyStops(context, setState) : buildArrivalTimes(context)
                  ),
                ),
              ),
            )
          ],
        ));
  }
}

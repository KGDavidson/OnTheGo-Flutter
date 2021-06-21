import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'globals.dart';
import 'global_class.dart';
import 'global_functions.dart';

bool back(setState) {
  loadingFavourites = false;
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
  return false;
}

List<Widget> buildFavourites(context, setState) {
  List returnFavouritesStops = currentFavouriteStops
      .map((item) => Container(
            height: MediaQuery.of(context).size.width * LIST_VIEW_ITEM_HEIGHT,
            child: FlatButton(
              onPressed: () async {
                currentStopFavourites = item;
                loadArrivalTimesFavourites(setState);
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
                            color: Colors.black87,
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
                                  color: Colors.black54,
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
  return returnFavouritesStops;
}

class ScreenFavourites extends StatefulWidget {
  @override
  _ScreenFavourites createState() => _ScreenFavourites();
}

class _ScreenFavourites extends State<ScreenFavourites> {
  @override
  void initState() {
    super.initState();
    showSearchInput = false;
    if (favouritesChanged) {
      readFavourites().then((ret) async {
        fetchFavouriteStops(setState);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FocusScope.of(context).unfocus();
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
    return WillPopScope(
      onWillPop: () async {
        return back(setState);
      },
      child: Container(
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
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3),
                            child: loadingFavourites
                                ? Text(
                                    "Favourites",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                                    ),
                                  )
                                : Text(
                                    currentStopFavourites != null
                                        ? currentStopFavourites.commonName.length > LIST_VIEW_TITLE_MAX_LENGTH
                                            ? currentStopFavourites.commonName.replaceRange(LIST_VIEW_TITLE_MAX_LENGTH + 1, currentStopFavourites.commonName.length, "...")
                                            : currentStopFavourites.commonName
                                        : "Favourites",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                                    ),
                                  ),
                          ),
                          currentStopFavourites != null ? Container() : Container(),
                        ],
                      ),
                      currentStopFavourites != null
                          ? Container(
                              padding: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3, top: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.only(
                                      right: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3,
                                    ),
                                    child: Text(
                                      () {
                                        String text = "ID " + currentStopFavourites.naptanId + " | " + currentStopFavourites.lines.join(" • ");
                                        try {
                                          text = text.replaceRange(45, text.length, '...');
                                        } catch (e) {}
                                        return text;
                                      }(),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 1.7,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {});
                                      if (currentFavourites.containsKey(currentStopFavourites.naptanId)) {
                                        currentFavourites.removeWhere((key, value) => key == currentStopFavourites.naptanId);
                                        writeFavourites();
                                      } else {
                                        currentFavourites[currentStopFavourites.naptanId] = {
                                          "stopLetter": currentStopFavourites.stopLetter,
                                          "commonName": currentStopFavourites.commonName,
                                          "distance": currentStopFavourites.distance,
                                          "lat": currentStopFavourites.lat,
                                          "lon": currentStopFavourites.lon,
                                          "lines": currentStopFavourites.lines,
                                        };
                                        writeFavourites();
                                      }
                                      favouritesChanged = true;
                                    },
                                    child: Icon(
                                      currentFavourites.containsKey(currentStopFavourites.naptanId) ? Icons.favorite : Icons.favorite_border,
                                      color: Color(0xffe84545),
                                      size: 17,
                                    ),
                                  )
                                ],
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
            Expanded(
              child: loadingFavourites
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        this.widget.reloadPage();
                        if (currentFavouriteStops != null) {
                          readFavourites().then((ret) async {
                            fetchFavouriteStops(setState);
                          });
                        } else {
                          await loadArrivalTimesFavourites(setState);
                        }
                      },
                      child: ListView(
                        children: currentStopFavourites != null
                            ? buildArrivalTimes(context, 1)
                            : currentFavouriteStops != null
                                ? buildFavourites(context, setState)
                                : [Container()],
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
